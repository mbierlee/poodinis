/**
 * This module contains instance factory facilities
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2021 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.factory;

import poodinis.container;
import poodinis.imports;

import std.typecons;
import std.exception;
import std.traits;
import std.string;
import std.stdio;

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

    public @property void factoryParameters(InstanceFactoryParameters factoryParameters) {
        if (factoryParameters.factoryMethod is null) {
            factoryParameters.factoryMethod = &this.createInstance;
        }

        if (factoryParameters.existingInstance !is null) {
            factoryParameters.createsSingleton = CreatesSingleton.yes;
            this.instance = factoryParameters.existingInstance;
        }

        _factoryParameters = factoryParameters;
    }

    public @property InstanceFactoryParameters factoryParameters() {
        return _factoryParameters;
    }

    public Object getInstance() {
        if (_factoryParameters.createsSingleton && instance !is null) {
            debug(poodinisVerbose) {
                printDebugUseExistingInstance();
            }

            return instance;
        }

        debug(poodinisVerbose) {
            printDebugCreateNewInstance();
        }

        instance = _factoryParameters.factoryMethod();
        if(_constructionHandler !is null) {
            _constructionHandler(instance);
        }

        return instance;
    }

    void onConstructed(InstanceEventHandler handler) {
        _constructionHandler = handler;
    }

    private void printDebugUseExistingInstance() {
        if (_factoryParameters.instanceType !is null) {
            writeln(format("DEBUG: Existing instance returned of type %s", _factoryParameters.instanceType.toString()));
        } else {
            writeln("DEBUG: Existing instance returned from custom factory method");
        }
    }

    private void printDebugCreateNewInstance() {
        if (_factoryParameters.instanceType !is null) {
            writeln(format("DEBUG: Creating new instance of type %s", _factoryParameters.instanceType.toString()));
        } else {
            writeln("DEBUG: Creating new instance from custom factory method");
        }
    }

    protected Object createInstance() {
        enforce!InstanceCreationException(_factoryParameters.instanceType, "Instance type is not defined, cannot create instance without knowing its type.");
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
        foreach(param; Params) {
            if (argumentList.length > 0) {
                argumentList ~= ",";
            }

            argumentList ~= "container.resolve!" ~ param.stringof;
        }
        return argumentList;
    }

    private static string createImportList(Params...)() {
        string importList = "";
        foreach(param; Params) {
            importList ~= createImportsString!param;
        }
        return importList;
    }

    private static bool parametersAreValid(Params...)() {
        bool isValid = true;
        foreach(param; Params) {
            if (isBuiltinType!param || is(param == struct)) {
                isValid = false;
                break;
            }
        }

        return isValid;
    }

    protected override Object createInstance() {
        enforce!InstanceCreationException(container, "A dependency container is not defined. Cannot perform constructor injection without one.");
        enforce!InstanceCreationException(!isBeingInjected, format("%s is already being created and injected; possible circular dependencies in constructors?", InstanceType.stringof));

        Object instance = null;
        static if (__traits(compiles, __traits(getOverloads, InstanceType, `__ctor`))) {
            foreach(ctor ; __traits(getOverloads, InstanceType, `__ctor`)) {
                static if (parametersAreValid!(Parameters!ctor)) {
                    isBeingInjected = true;
                    mixin(createImportsString!InstanceType
                        ~ createImportList!(Parameters!ctor) ~ `
                        instance = new ` ~ fullyQualifiedName!InstanceType ~ `(` ~ createArgumentList!(Parameters!ctor) ~ `);
                    `);
                    isBeingInjected = false;
                    break;
                }
            }
        }

        if (instance is null) {
            instance = typeid(InstanceType).create();
        }

        enforce!InstanceCreationException(instance !is null, "Unable to create instance of type" ~ InstanceType.stringof ~ ", does it have injectable constructors?");

        return instance;
    }
}
