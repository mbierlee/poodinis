/**
 * This module contains instance factory facilities
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2026 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.factory;

import poodinis.container : DependencyContainer;
import poodinis.imports : createImportsString;

import std.typecons : Flag;
import std.exception : enforce;
import std.traits : Parameters, isBuiltinType, fullyQualifiedName;
import std.string : format;

debug {
    import std.stdio : writeln;
}

alias CreatesSingleton = Flag!"CreatesSingleton";
alias InstanceFactoryMethod = Object delegate();
alias InstanceEventHandler = void delegate(Object instance);

class InstanceCreationException : Exception {
    this(string message, string file = __FILE__, size_t line = __LINE__) {
        super(message, file, line);
    }
}

struct InstanceFactoryParameters {
    TypeInfo_Class instanceType;
    CreatesSingleton createsSingleton = CreatesSingleton.yes;
    Object existingInstance;
    InstanceFactoryMethod factoryMethod;
}

class InstanceFactory {
    private Object instance = null;
    private InstanceFactoryParameters _factoryParameters;
    private InstanceEventHandler _constructionHandler;

    this() {
        factoryParameters = InstanceFactoryParameters();
    }

    void factoryParameters(InstanceFactoryParameters factoryParameters) {
        if (factoryParameters.factoryMethod is null) {
            factoryParameters.factoryMethod = &this.createInstance;
        }

        if (factoryParameters.existingInstance !is null) {
            factoryParameters.createsSingleton = CreatesSingleton.yes;
            this.instance = factoryParameters.existingInstance;
        }

        _factoryParameters = factoryParameters;
    }

    InstanceFactoryParameters factoryParameters() {
        return _factoryParameters;
    }

    Object getInstance() {
        if (_factoryParameters.createsSingleton && instance !is null) {
            debug (poodinisVerbose) {
                printDebugUseExistingInstance();
            }

            return instance;
        }

        debug (poodinisVerbose) {
            printDebugCreateNewInstance();
        }

        instance = _factoryParameters.factoryMethod();
        if (_constructionHandler !is null) {
            _constructionHandler(instance);
        }

        return instance;
    }

    void onConstructed(InstanceEventHandler handler) {
        _constructionHandler = handler;
    }

    private void printDebugUseExistingInstance() {
        debug {
            if (_factoryParameters.instanceType !is null) {
                writeln(format("DEBUG: Existing instance returned of type %s",
                        _factoryParameters.instanceType.toString()));
            } else {
                writeln("DEBUG: Existing instance returned from custom factory method");
            }
        }
    }

    private void printDebugCreateNewInstance() {
        debug {
            if (_factoryParameters.instanceType !is null) {
                writeln(format("DEBUG: Creating new instance of type %s",
                        _factoryParameters.instanceType.toString()));
            } else {
                writeln("DEBUG: Creating new instance from custom factory method");
            }
        }
    }

    protected Object createInstance() {
        enforce!InstanceCreationException(_factoryParameters.instanceType,
            "Instance type is not defined, cannot create instance without knowing its type.");
        return _factoryParameters.instanceType.create();
    }
}

class ConstructorInjectingInstanceFactory(InstanceType) : InstanceFactory {
    private shared DependencyContainer container;
    private bool isBeingInjected = false;

    this(shared DependencyContainer container) {
        this.container = container;
    }

    private static string createArgumentList(Params...)() {
        string argumentList = "";
        foreach (param; Params) {
            if (argumentList.length > 0) {
                argumentList ~= ",";
            }

            argumentList ~= "container.resolve!(" ~ param.stringof ~ ")";
        }
        return argumentList;
    }

    private static string createImportList(Params...)() {
        string importList = "";
        foreach (param; Params) {
            importList ~= createImportsString!param;
        }
        return importList;
    }

    private static bool parametersAreValid(Params...)() {
        bool isValid = true;
        foreach (param; Params) {
            if (isBuiltinType!param || is(param == struct)) {
                isValid = false;
                break;
            }
        }

        return isValid;
    }

    protected override Object createInstance() {
        enforce!InstanceCreationException(container,
            "A dependency container is not defined. Cannot perform constructor injection without one.");
        enforce!InstanceCreationException(!isBeingInjected,
            format("%s is already being created and injected; possible circular dependencies in constructors?",
                InstanceType.stringof));

        Object instance = null;
        static if (__traits(compiles, __traits(getOverloads, InstanceType, `__ctor`))) {
            foreach (ctor; __traits(getOverloads, InstanceType, `__ctor`)) {
                static if (parametersAreValid!(Parameters!ctor)) {
                    isBeingInjected = true;
                    mixin(createImportsString!InstanceType ~ createImportList!(
                            Parameters!ctor) ~ `
                        instance = new `
                            ~ fullyQualifiedName!InstanceType ~ `(` ~ createArgumentList!(
                                Parameters!ctor) ~ `);
                    `);
                    isBeingInjected = false;
                    break;
                }
            }
        }

        if (instance is null) {
            instance = typeid(InstanceType).create();
        }

        enforce!InstanceCreationException(instance !is null,
            "Unable to create instance of type" ~ InstanceType.stringof
                ~ ", does it have injectable constructors?");

        return instance;
    }
}

version (unittest)  :  //

import poodinis;
import poodinis.testclasses;
import std.exception;

// Test instance factory with singletons
unittest {
    auto factory = new InstanceFactory();
    factory.factoryParameters = InstanceFactoryParameters(typeid(TestImplementation),
        CreatesSingleton.yes);
    auto instanceOne = factory.getInstance();
    auto instanceTwo = factory.getInstance();

    assert(instanceOne !is null, "Created factory instance is null");
    assert(instanceOne is instanceTwo, "Created factory instance is not the same");
}

// Test instance factory with new instances
unittest {
    auto factory = new InstanceFactory();
    factory.factoryParameters = InstanceFactoryParameters(typeid(TestImplementation),
        CreatesSingleton.no);
    auto instanceOne = factory.getInstance();
    auto instanceTwo = factory.getInstance();

    assert(instanceOne !is null, "Created factory instance is null");
    assert(instanceOne !is instanceTwo, "Created factory instance is the same");
}

// Test instance factory with existing instances
unittest {
    auto existingInstance = new TestImplementation();
    auto factory = new InstanceFactory();
    factory.factoryParameters = InstanceFactoryParameters(typeid(TestImplementation),
        CreatesSingleton.yes, existingInstance);
    auto instanceOne = factory.getInstance();
    auto instanceTwo = factory.getInstance();

    assert(instanceOne is existingInstance,
        "Created factory instance is not the existing instance");
    assert(instanceTwo is existingInstance,
        "Created factory instance is not the existing instance when called again");
}

// Test instance factory with existing instances when setting singleton flag to "no"
unittest {
    auto existingInstance = new TestImplementation();
    auto factory = new InstanceFactory();
    factory.factoryParameters = InstanceFactoryParameters(typeid(TestImplementation),
        CreatesSingleton.no, existingInstance);
    auto instance = factory.getInstance();

    assert(instance is existingInstance,
        "Created factory instance is not the existing instance");
}

// Test creating instance using custom factory method
unittest {
    Object factoryMethod() {
        auto instance = new TestImplementation();
        instance.someContent = "Ducks!";
        return instance;
    }

    auto factory = new InstanceFactory();
    factory.factoryParameters = InstanceFactoryParameters(null,
        CreatesSingleton.yes, null, &factoryMethod);
    auto instance = cast(TestImplementation) factory.getInstance();

    assert(instance !is null,
        "No instance was created by factory or could not be cast to expected type");
    assert(instance.someContent == "Ducks!");
}

// Test injecting constructor of class
unittest {
    auto container = new shared DependencyContainer();
    container.register!TestImplementation;

    auto factory = new ConstructorInjectingInstanceFactory!ClassWithConstructor(container);
    auto instance = cast(ClassWithConstructor) factory.getInstance();

    assert(instance !is null);
    assert(instance.testImplementation is container.resolve!TestImplementation);
}

// Test injecting constructor of class with multiple constructors injects the first candidate
unittest {
    auto container = new shared DependencyContainer();
    container.register!SomeOtherClassThen;
    container.register!TestImplementation;

    auto factory = new ConstructorInjectingInstanceFactory!ClassWithMultipleConstructors(
        container);
    auto instance = cast(ClassWithMultipleConstructors) factory.getInstance();

    assert(instance !is null);
    assert(instance.someOtherClassThen is container.resolve!SomeOtherClassThen);
    assert(instance.testImplementation is null);
}

// Test injecting constructor of class with multiple constructor parameters
unittest {
    auto container = new shared DependencyContainer();
    container.register!SomeOtherClassThen;
    container.register!TestImplementation;

    auto factory = new ConstructorInjectingInstanceFactory!ClassWithConstructorWithMultipleParameters(
        container);
    auto instance = cast(ClassWithConstructorWithMultipleParameters) factory.getInstance();

    assert(instance !is null);
    assert(instance.someOtherClassThen is container.resolve!SomeOtherClassThen);
    assert(instance.testImplementation is container.resolve!TestImplementation);
}

// Test injecting constructor of class with primitive constructor parameters
unittest {
    auto container = new shared DependencyContainer();
    container.register!SomeOtherClassThen;

    auto factory = new ConstructorInjectingInstanceFactory!ClassWithPrimitiveConstructor(
        container);
    auto instance = cast(ClassWithPrimitiveConstructor) factory.getInstance();

    assert(instance !is null);
    assert(instance.someOtherClassThen is container.resolve!SomeOtherClassThen);
}

// Test injecting constructor of class with struct constructor parameters
unittest {
    auto container = new shared DependencyContainer();
    container.register!SomeOtherClassThen;

    auto factory = new ConstructorInjectingInstanceFactory!ClassWithStructConstructor(container);
    auto instance = cast(ClassWithStructConstructor) factory.getInstance();

    assert(instance !is null);
    assert(instance.someOtherClassThen is container.resolve!SomeOtherClassThen);
}

// Test injecting constructor of class with empty constructor will skip injection
unittest {
    auto container = new shared DependencyContainer();

    auto factory = new ConstructorInjectingInstanceFactory!ClassWithEmptyConstructor(container);
    auto instance = cast(ClassWithEmptyConstructor) factory.getInstance();

    assert(instance !is null);
    assert(instance.someOtherClassThen is null);
}

// Test injecting constructor of class with no candidates fails
unittest {
    auto container = new shared DependencyContainer();

    auto factory = new ConstructorInjectingInstanceFactory!ClassWithNonInjectableConstructor(
        container);

    assertThrown!InstanceCreationException(factory.getInstance());
}
