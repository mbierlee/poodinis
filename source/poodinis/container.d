/**
 * Contains the implementation of the dependency container.
 *
 * Part of the Poodinis Dependency Injection framework.
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2025 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.container;

import poodinis.registration : Registration, singleInstance,
    toConcreteTypeListString, initializeFactoryType;
import poodinis.autowire : AutowiredRegistration, AutowireInstantiationContext;
import poodinis.factory : ConstructorInjectingInstanceFactory;
import poodinis.valueinjection : ValueInjectionException;
import poodinis.altphobos : isFunction;
import poodinis.imports : createImportsString;

import std.string : format;
import std.algorithm : canFind;
import std.traits : fullyQualifiedName, hasUDA, BaseTypeTuple;
import std.meta : AliasSeq;

debug (poodinisVerbose) {
    import std.stdio : writeln;
}

/**
 * Exception thrown when errors occur while resolving a type in a dependency container.
 */
class ResolveException : Exception {
    this(string message, TypeInfo resolveType) {
        super(format("Exception while resolving type %s: %s", resolveType.toString(), message));
    }

    this(Throwable cause, TypeInfo resolveType) {
        super(format("Exception while resolving type %s", resolveType.toString()), cause);
    }
}

/**
 * Exception thrown when errors occur while registering a type in a dependency container.
 */
class RegistrationException : Exception {
    this(string message, TypeInfo registrationType) {
        super(format("Exception while registering type %s: %s",
                registrationType.toString(), message));
    }
}

/**
 * Options which influence the process of registering dependencies
 */
enum RegistrationOption {
    none = 0,
    /**
     * Prevent a concrete type being registered on itself. With this option you will always need
     * to use the supertype as the type of the dependency.
     */
    doNotAddConcreteTypeRegistration = 1 << 0,
}

/**
 * Options which influence the process of resolving dependencies
 */
enum ResolveOption {
    none = 0,
    /**
     * Registers the type you're trying to resolve before returning it.
     * This essentially makes registration optional for resolving by concerete types.
     * Resolinvg will still fail when trying to resolve a dependency by supertype.
     */
    registerBeforeResolving = 1 << 0,

    /**
     * Does not throw a resolve exception when a type is not registered but will
     * return null instead. If the type is an array, an empty array is returned instead.
     */
    noResolveException = 1 << 1
}

/**
 * Methods marked with this UDA within dependencies are called after that dependency
 * is constructed by the dependency container.
 *
 * Multiple methods can be marked and will all be called after construction. The order in which
 * methods are called is undetermined. Methods should have the signature void(void).
 */
struct PostConstruct {
}

/**
 * Methods marked with this UDA within dependencies are called before the container
 * loses the dependency's registration.
 *
 * This method is called when removeRegistration or clearAllRegistrations is called.
 * It will also be called when the container's destructor is called.
 */
struct PreDestroy {
}

/**
 * The dependency container maintains all dependencies registered with it.
 *
 * Dependencies registered by a container can be resolved as long as they are still registered with the container.
 * Upon resolving a dependency, an instance is fetched according to a specific scope which dictates how instances of
 * dependencies are created. Resolved dependencies will be autowired before being returned.
 *
 * In most cases you want to use a global singleton dependency container provided by getInstance() to manage all dependencies.
 * You can still create new instances of this class for exceptional situations.
 */
synchronized class DependencyContainer {
    private Registration[][TypeInfo] registrations;

    private Registration[] autowireStack;

    private RegistrationOption persistentRegistrationOptions;
    private ResolveOption persistentResolveOptions;

    ~this() {
        clearAllRegistrations();
    }

    /**
     * Register a dependency by concrete class type.
     *
     * A dependency registered by concrete class type can only be resolved by concrete class type.
     * No qualifiers can be used when resolving dependencies which are registered by concrete type.
     *
     * The default registration scope is "single instance" scope.
     *
     * Returns:
     * A registration is returned which can be used to change the registration scope.
     *
     * Examples:
     * Register and resolve a class by concrete type:
     * ---
     * class Cat : Animal { ... }
     * container.register!Cat;
     * ---
     *
     * See_Also: singleInstance, newInstance, existingInstance
     */
    Registration register(ConcreteType)(RegistrationOption options = RegistrationOption.none) {
        return register!(ConcreteType, ConcreteType)(options);
    }

    /**
     * Register a dependency by super type.
     *
     * A dependency registered by super type can only be resolved by super type. A qualifier is typically
     * used to resolve dependencies registered by super type.
     *
     * The default registration scope is "single instance" scope.
     *
     * Examples:
     * Register and resolve by super type
     * ---
     * class Cat : Animal { ... }
     * container.register!(Animal, Cat);
     * ---
     *
     * See_Also: singleInstance, newInstance, existingInstance, RegistrationOption
     */
    Registration register(SuperType, ConcreteType:
        SuperType)(RegistrationOption options = RegistrationOption.none)
            if (!is(ConcreteType == struct)) {
        TypeInfo registeredType = typeid(SuperType);
        TypeInfo_Class concreteType = typeid(ConcreteType);

        debug (poodinisVerbose) {
            writeln(format("DEBUG: Register type %s (as %s)",
                    concreteType.toString(), registeredType.toString()));
        }

        auto existingRegistration = getExistingRegistration(registeredType, concreteType);
        if (existingRegistration) {
            return existingRegistration;
        }

        auto instanceFactory = new ConstructorInjectingInstanceFactory!ConcreteType(this);
        auto newRegistration = new AutowiredRegistration!ConcreteType(registeredType,
            instanceFactory, this);
        newRegistration.initializeFactoryType().singleInstance();

        static if (!is(SuperType == ConcreteType)) {
            if (!hasOption(options, persistentRegistrationOptions,
                    RegistrationOption.doNotAddConcreteTypeRegistration)) {
                auto concreteTypeRegistration = register!ConcreteType;
                concreteTypeRegistration.linkTo(newRegistration);
            }
        }

        registrations[registeredType] ~= cast(shared(Registration)) newRegistration;
        return newRegistration;
    }

    private bool hasOption(OptionType)(OptionType options,
        OptionType persistentOptions, OptionType option) {
        return ((options | persistentOptions) & option) != 0;
    }

    private OptionType buildFlags(OptionType)(OptionType[] options) {
        OptionType flags;
        foreach (option; options) {
            flags |= option;
        }
        return flags;
    }

    private Registration getExistingRegistration(TypeInfo registrationType, TypeInfo qualifierType) {
        auto existingCandidates = registrationType in registrations;
        if (existingCandidates) {
            return getRegistration(cast(Registration[])*existingCandidates, qualifierType);
        }

        return null;
    }

    private Registration getRegistration(Registration[] candidates, TypeInfo concreteType) {
        foreach (existingRegistration; candidates) {
            if (existingRegistration.instanceType == concreteType) {
                return existingRegistration;
            }
        }

        return null;
    }

    /**
     * Resolve dependencies.
     *
     * Dependencies can only resolved using this method if they are registered by concrete type or the only
     * concrete type registered by super type.
     *
     * Resolved dependencies are automatically autowired before being returned.
     *
     * Returns:
     * An instance is returned which is created according to the registration scope with which they are registered.
     *
     * Throws:
     * ResolveException when type is not registered.
     *
     * Examples:
     * Resolve dependencies registered by super type and concrete type:
     * ---
     * class Cat : Animal { ... }
     * class Dog : Animal { ... }
     *
     * container.register!(Animal, Cat);
     * container.register!Dog;
     *
     * container.resolve!Animal;
     * container.resolve!Dog;
     * ---
     * You cannot resolve a dependency when it is registered by multiple super types:
     * ---
     * class Cat : Animal { ... }
     * class Dog : Animal { ... }
     *
     * container.register!(Animal, Cat);
     * container.register!(Animal, Dog);
     *
     * container.resolve!Animal; // Error: multiple candidates for type "Animal"
     * container.resolve!Dog; // Error: No type is registered by concrete type "Dog", only by super type "Animal"
     * ---
     * You need to use the resolve method which allows you to specify a qualifier.
     */
    RegistrationType resolve(RegistrationType)(
        ResolveOption resolveOptions = ResolveOption.none)
            if (!is(RegistrationType == struct)) {
        return resolve!(RegistrationType, RegistrationType)(resolveOptions);
    }

    /**
     * Resolve dependencies using a qualifier.
     *
     * Dependencies can only resolved using this method if they are registered by super type.
     *
     * Resolved dependencies are automatically autowired before being returned.
     *
     * Returns:
     * An instance is returned which is created according to the registration scope with which they are registered.
     *
     * Throws:
     * ResolveException when type is not registered or there are multiple candidates available for type.
     *
     * Examples:
     * Resolve dependencies registered by super type:
     * ---
     * class Cat : Animal { ... }
     * class Dog : Animal { ... }
     *
     * container.register!(Animal, Cat);
     * container.register!(Animal, Dog);
     *
     * container.resolve!(Animal, Cat);
     * container.resolve!(Animal, Dog);
     * ---
     */
    QualifierType resolve(RegistrationType, QualifierType:
        RegistrationType)(ResolveOption resolveOptions = ResolveOption.none)
            if (!is(QualifierType == struct)) {
        TypeInfo resolveType = typeid(RegistrationType);
        TypeInfo qualifierType = typeid(QualifierType);

        debug (poodinisVerbose) {
            writeln("DEBUG: Resolving type " ~ resolveType.toString() ~ " with qualifier " ~ qualifierType.toString());
        }

        auto candidates = resolveType in registrations;
        if (!candidates) {
            static if (is(typeof(typeid(QualifierType)) == TypeInfo_Class) && !__traits(isAbstractClass, QualifierType)) {
                if (hasOption(resolveOptions, persistentResolveOptions, ResolveOption
                        .registerBeforeResolving)) {
                    register!(RegistrationType, QualifierType)();
                    return resolve!(RegistrationType, QualifierType)(resolveOptions);
                }
            }

            if (hasOption(resolveOptions, persistentResolveOptions,
                    ResolveOption.noResolveException)) {
                return null;
            }

            throw new ResolveException("Type not registered.", resolveType);
        }

        Registration registration = getQualifiedRegistration(resolveType,
            qualifierType, cast(Registration[])*candidates);

        try {
            QualifierType newInstance = resolveAutowiredInstance!QualifierType(registration);
            callPostConstructors(newInstance);
            return newInstance;
        } catch (ValueInjectionException e) {
            throw new ResolveException(e, resolveType);
        }
    }

    bool isRegistered(RegistrationType)() {
        TypeInfo typeInfo = typeid(RegistrationType);
        auto candidates = typeInfo in registrations;
        return candidates !is null;
    }

    private QualifierType resolveAutowiredInstance(QualifierType)(Registration registration) {
        QualifierType instance;
        if (!(cast(Registration[]) autowireStack).canFind(registration)) {
            autowireStack ~= cast(shared(Registration)) registration;
            instance = cast(QualifierType) registration.getInstance(
                new AutowireInstantiationContext());
            autowireStack = autowireStack[0 .. $ - 1];
        } else {
            auto autowireContext = new AutowireInstantiationContext();
            autowireContext.autowireInstance = false;
            instance = cast(QualifierType) registration.getInstance(autowireContext);
        }
        return instance;
    }

    /**
     * Resolve all dependencies registered to a super type.
     *
     * Returns:
     * An array of autowired instances is returned. The order is undetermined.
     *
     * Examples:
     * ---
     * class Cat : Animal { ... }
     * class Dog : Animal { ... }
     *
     * container.register!(Animal, Cat);
     * container.register!(Animal, Dog);
     *
     * Animal[] animals = container.resolveAll!Animal;
     * ---
     */
    RegistrationType[] resolveAll(RegistrationType)(
        ResolveOption resolveOptions = ResolveOption.none) {
        RegistrationType[] instances;
        TypeInfo resolveType = typeid(RegistrationType);

        auto qualifiedRegistrations = resolveType in registrations;
        if (!qualifiedRegistrations) {
            if (hasOption(resolveOptions, persistentResolveOptions,
                    ResolveOption.noResolveException)) {
                return [];
            }

            throw new ResolveException("Type not registered.", resolveType);
        }

        foreach (registration; cast(Registration[])*qualifiedRegistrations) {
            instances ~= resolveAutowiredInstance!RegistrationType(registration);
        }

        return instances;
    }

    private Registration getQualifiedRegistration(TypeInfo resolveType,
        TypeInfo qualifierType, Registration[] candidates) {
        if (resolveType == qualifierType) {
            if (candidates.length > 1) {
                string candidateList = candidates.toConcreteTypeListString();
                throw new ResolveException(
                    "Multiple qualified candidates available: " ~ candidateList ~ ". Please use a qualifier.",
                    resolveType);
            }

            return candidates[0];
        }

        return getRegistration(candidates, qualifierType);
    }

    private void callPostConstructors(Type)(Type instance) {
        static foreach (memberName; __traits(allMembers, Type)) {
            static foreach (overload; __traits(getOverloads, Type, memberName)) {
                static if (__traits(compiles, __traits(getProtection, overload))
                    && __traits(getProtection, overload) == "public"
                    && isFunction!overload
                    && hasUDA!(overload, PostConstruct)) {
                    __traits(getMember, instance, memberName)();
                }
            }
        }
    }

    /**
     * Clears all dependency registrations managed by this container.
     */
    void clearAllRegistrations() {
        foreach (registrationsOfType; registrations) {
            callPreDestructorsOfRegistrations(registrationsOfType);
        }
        registrations.destroy();
    }

    /**
     * Removes a registered dependency by type.
     *
     * A dependency can be removed either by super type or concrete type, depending on how they are registered.
     *
     * Examples:
     * ---
     * container.removeRegistration!Animal;
     * ---
     */
    void removeRegistration(RegistrationType)() {
        auto registrationsOfType = *(typeid(RegistrationType) in registrations);
        callPreDestructorsOfRegistrations(registrationsOfType);
        registrations.remove(typeid(RegistrationType));
    }

    private void callPreDestructorsOfRegistrations(shared(Registration[]) registrations) {
        foreach (registration; registrations) {
            Registration unsharedRegistration = cast(Registration) registration;
            if (unsharedRegistration.preDestructor !is null) {
                unsharedRegistration.preDestructor()();
            }
        }
    }

    /**
     * Apply persistent registration options which will be used everytime register() is called.
     */
    void setPersistentRegistrationOptions(RegistrationOption options) {
        persistentRegistrationOptions = options;
    }

    /**
     * Unsets all applied persistent registration options
     */
    void unsetPersistentRegistrationOptions() {
        persistentRegistrationOptions = RegistrationOption.none;
    }

    /**
     * Apply persistent resolve options which will be used everytime resolve() is called.
     */
    void setPersistentResolveOptions(ResolveOption options) {
        persistentResolveOptions = options;
    }

    /**
     * Unsets all applied persistent resolve options
     */
    void unsetPersistentResolveOptions() {
        persistentResolveOptions = ResolveOption.none;
    }

}

version (unittest)  :  //

import poodinis;
import poodinis.testclasses;
import poodinis.foreigndependencies;

import std.exception;
import core.thread;

// Test register concrete type
unittest {
    auto container = new shared DependencyContainer();
    auto registration = container.register!TestClass;
    assert(registration.registeredType == typeid(TestClass),
        "Type of registered type not the same");
}

// Test resolve registered type
unittest {
    auto container = new shared DependencyContainer();
    container.register!TestClass;
    TestClass actualInstance = container.resolve!TestClass;
    assert(actualInstance !is null, "Resolved type is null");
    assert(cast(TestClass) actualInstance, "Resolved class is not the same type as expected");
}

// Test register interface
unittest {
    auto container = new shared DependencyContainer();
    container.register!(TestInterface, TestClass);
    TestInterface actualInstance = container.resolve!TestInterface;
    assert(actualInstance !is null, "Resolved type is null");
    assert(cast(TestInterface) actualInstance,
        "Resolved class is not the same type as expected");
}

// Test resolve non-registered type
unittest {
    auto container = new shared DependencyContainer();
    assertThrown!ResolveException(container.resolve!TestClass,
        "Resolving non-registered type does not fail");
}

// Test clear registrations
unittest {
    auto container = new shared DependencyContainer();
    container.register!TestClass;
    container.clearAllRegistrations();
    assertThrown!ResolveException(container.resolve!TestClass,
        "Resolving cleared type does not fail");
}

// Test resolve single instance for type
unittest {
    auto container = new shared DependencyContainer();
    container.register!TestClass.singleInstance();
    auto instance1 = container.resolve!TestClass;
    auto instance2 = container.resolve!TestClass;
    assert(instance1 is instance2,
        "Resolved instance from single instance scope is not the each time it is resolved");
}

// Test resolve new instance for type
unittest {
    auto container = new shared DependencyContainer();
    container.register!TestClass.newInstance();
    auto instance1 = container.resolve!TestClass;
    auto instance2 = container.resolve!TestClass;
    assert(instance1 !is instance2,
        "Resolved instance from new instance scope is the same each time it is resolved");
}

// Test resolve existing instance for type
unittest {
    auto container = new shared DependencyContainer();
    auto expectedInstance = new TestClass();
    container.register!TestClass.existingInstance(expectedInstance);
    auto actualInstance = container.resolve!TestClass;
    assert(expectedInstance is actualInstance,
        "Resolved instance from existing instance scope is not the same as the registered instance");
}

// Test creating instance via custom initializer on resolve
unittest {
    auto container = new shared DependencyContainer();
    auto expectedInstance = new TestClass();
    container.register!TestClass.initializedBy({ return expectedInstance; });
    auto actualInstance = container.resolve!TestClass;
    assert(expectedInstance is actualInstance,
        "Resolved instance does not come from the custom initializer");
}

// Test creating instance via initializedBy creates new instance every time
unittest {
    auto container = new shared DependencyContainer();
    container.register!TestClass.initializedBy({ return new TestClass(); });
    auto firstInstance = container.resolve!TestClass;
    auto secondInstance = container.resolve!TestClass;
    assert(firstInstance !is secondInstance, "Resolved instance are not different instances");
}

// Test creating instance via initializedOnceBy creates a singleton instance
unittest {
    auto container = new shared DependencyContainer();
    container.register!TestClass.initializedOnceBy({ return new TestClass(); });
    auto firstInstance = container.resolve!TestClass;
    auto secondInstance = container.resolve!TestClass;
    assert(firstInstance is secondInstance, "Resolved instance are different instances");
}

// Test autowire resolved instances
unittest {
    auto container = new shared DependencyContainer();
    container.register!AutowiredClass;
    container.register!ComponentClass;
    auto componentInstance = container.resolve!ComponentClass;
    auto autowiredInstance = container.resolve!AutowiredClass;
    assert(componentInstance.autowiredClass is autowiredInstance,
        "Member is not autwired upon resolving");
}

// Test circular autowiring
unittest {
    auto container = new shared DependencyContainer();
    container.register!ComponentMouse;
    container.register!ComponentCat;
    auto mouse = container.resolve!ComponentMouse;
    auto cat = container.resolve!ComponentCat;
    assert(mouse.cat is cat && cat.mouse is mouse && mouse !is cat,
        "Circular dependencies should be autowirable");
}

// Test remove registration
unittest {
    auto container = new shared DependencyContainer();
    container.register!TestClass;
    container.removeRegistration!TestClass;
    assertThrown!ResolveException(container.resolve!TestClass);
}

// Test autowiring does not autowire member where instance is non-null
unittest {
    auto container = new shared DependencyContainer();
    auto existingA = new AutowiredClass();
    auto existingB = new ComponentClass();
    existingB.autowiredClass = existingA;

    container.register!AutowiredClass;
    container.register!ComponentClass.existingInstance(existingB);
    auto resolvedA = container.resolve!AutowiredClass;
    auto resolvedB = container.resolve!ComponentClass;

    assert(resolvedB.autowiredClass is existingA && resolvedA !is existingA,
        "Autowiring shouldn't rewire member when it is already wired to an instance");
}

// Test autowiring circular dependency by third-degree
unittest {
    auto container = new shared DependencyContainer();
    container.register!Eenie;
    container.register!Meenie;
    container.register!Moe;

    auto eenie = container.resolve!Eenie;

    assert(eenie.meenie.moe.eenie is eenie,
        "Autowiring third-degree circular dependency failed");
}

// Test autowiring deep circular dependencies
unittest {
    auto container = new shared DependencyContainer();
    container.register!Ittie;
    container.register!Bittie;
    container.register!Bunena;

    auto ittie = container.resolve!Ittie;

    assert(ittie.bittie is ittie.bittie.banana.bittie, "Autowiring deep dependencies failed.");
}

// Test autowiring deep circular dependencies with newInstance scope does not autowire new instance second time
unittest {
    auto container = new shared DependencyContainer();
    container.register!Ittie.newInstance();
    container.register!Bittie.newInstance();
    container.register!Bunena.newInstance();

    auto ittie = container.resolve!Ittie;

    assert(ittie.bittie.banana.bittie.banana is null,
        "Autowiring deep dependencies with newInstance scope autowired a reoccuring type.");
}

// Test autowiring type registered by interface
unittest {
    auto container = new shared DependencyContainer();
    container.register!Bunena;
    container.register!Bittie;
    container.register!(SuperInterface, SuperImplementation);

    SuperImplementation superInstance = cast(SuperImplementation) container
        .resolve!SuperInterface;

    assert(!(superInstance.banana is null),
        "Instance which was resolved by interface type was not autowired.");
}

// Test reusing a container after clearing all registrations
unittest {
    auto container = new shared DependencyContainer();
    container.register!Banana;
    container.clearAllRegistrations();
    try {
        container.resolve!Banana;
    } catch (ResolveException e) {
        container.register!Banana;
        return;
    }
    assert(false);
}

// Test register multiple concrete classess to same interface type
unittest {
    auto container = new shared DependencyContainer();
    container.register!(Color, Blue);
    container.register!(Color, Red);
}

// Test removing all registrations for type with multiple registrations.
unittest {
    auto container = new shared DependencyContainer();
    container.register!(Color, Blue);
    container.register!(Color, Red);
    container.removeRegistration!Color;
}

// Test registering same registration again
unittest {
    auto container = new shared DependencyContainer();
    auto firstRegistration = container.register!(Color, Blue);
    auto secondRegistration = container.register!(Color, Blue);

    assert(firstRegistration is secondRegistration,
        "First registration is not the same as the second of equal types");
}

// Test resolve registration with multiple qualifiers
unittest {
    auto container = new shared DependencyContainer();
    container.register!(Color, Blue);
    container.register!(Color, Red);
    try {
        container.resolve!Color;
    } catch (ResolveException e) {
        return;
    }
    assert(false);
}

// Test resolve registration with multiple qualifiers using a qualifier
unittest {
    auto container = new shared DependencyContainer();
    container.register!(Color, Blue);
    container.register!(Color, Red);
    auto blueInstance = container.resolve!(Color, Blue);
    auto redInstance = container.resolve!(Color, Red);

    assert(blueInstance !is redInstance,
        "Resolving type with multiple, different registrations yielded the same instance");
    assert(blueInstance !is null, "Resolved blue instance to null");
    assert(redInstance !is null, "Resolved red instance to null");
}

// Test autowire of unqualified member typed by interface.
unittest {
    auto container = new shared DependencyContainer();
    container.register!Spiders;
    container.register!(TestInterface, TestClass);

    auto instance = container.resolve!Spiders;

    assert(!(instance is null), "Container failed to autowire member by interface");
}

// Register existing registration
unittest {
    auto container = new shared DependencyContainer();

    auto firstRegistration = container.register!TestClass;
    auto secondRegistration = container.register!TestClass;

    assert(firstRegistration is secondRegistration,
        "Registering the same registration twice registers the dependencies twice.");
}

// Register existing registration by supertype
unittest {
    auto container = new shared DependencyContainer();

    auto firstRegistration = container.register!(TestInterface, TestClass);
    auto secondRegistration = container.register!(TestInterface, TestClass);

    assert(firstRegistration is secondRegistration,
        "Registering the same registration by super type twice registers the dependencies twice.");
}

// Resolve dependency depending on itself
unittest {
    auto container = new shared DependencyContainer();
    container.register!Recursive;

    auto instance = container.resolve!Recursive;

    assert(instance.recursive is instance, "Resolving dependency that depends on itself fails.");
    assert(instance.recursive.recursive is instance,
        "Resolving dependency that depends on itself fails.");
}

// Test autowire stack pop-back
unittest {
    auto container = new shared DependencyContainer();
    container.register!Moolah;
    container.register!Wants.newInstance();
    container.register!John;

    container.resolve!Wants;
    auto john = container.resolve!John;

    assert(john.wants.moolah !is null, "Autowire stack did not clear entries properly");
}

// Test resolving registration registered in different thread
unittest {
    auto container = new shared DependencyContainer();

    auto thread = new Thread(delegate() { container.register!TestClass; });
    thread.start();
    thread.join();

    container.resolve!TestClass;
}

// Test resolving instance previously resolved in different thread
unittest {
    auto container = new shared DependencyContainer();
    shared(TestClass) actualTestClass;

    container.register!TestClass;

    auto thread = new Thread(delegate() {
        actualTestClass = cast(shared(TestClass)) container.resolve!TestClass;
    });
    thread.start();
    thread.join();

    shared(TestClass) expectedTestClass = cast(shared(TestClass)) container.resolve!TestClass;

    assert(expectedTestClass is actualTestClass,
        "Instance resolved in main thread is not the one resolved in thread");
}

// Test registering type with option doNotAddConcreteTypeRegistration
unittest {
    auto container = new shared DependencyContainer();
    container.register!(TestInterface,
        TestClass)(RegistrationOption.doNotAddConcreteTypeRegistration);

    auto firstInstance = container.resolve!TestInterface;
    assertThrown!ResolveException(container.resolve!TestClass);
}

// Test registering conrete type with registration option doNotAddConcreteTypeRegistration does nothing
unittest {
    auto container = new shared DependencyContainer();
    container.register!TestClass(RegistrationOption.doNotAddConcreteTypeRegistration);
    container.resolve!TestClass;
}

// Test registering type will register by contrete type by default
unittest {
    auto container = new shared DependencyContainer();
    container.register!(TestInterface, TestClass);

    auto firstInstance = container.resolve!TestInterface;
    auto secondInstance = container.resolve!TestClass;

    assert(firstInstance is secondInstance);
}

// Test resolving all registrations to an interface
unittest {
    auto container = new shared DependencyContainer();
    container.register!(Color, Blue);
    container.register!(Color, Red);

    auto colors = container.resolveAll!Color;

    assert(colors.length == 2, "resolveAll did not yield all instances of interface type");
}

// Test autowiring instances resolved in array
unittest {
    auto container = new shared DependencyContainer();
    container.register!UnrelatedClass;
    container.register!(TestInterface, TestClassDeux);

    auto instances = container.resolveAll!TestInterface;
    auto instance = cast(TestClassDeux) instances[0];

    assert(instance.unrelated !is null);
}

// Test set persistent registration options
unittest {
    auto container = new shared DependencyContainer();
    container.setPersistentRegistrationOptions(
        RegistrationOption.doNotAddConcreteTypeRegistration);
    container.register!(TestInterface, TestClass);
    assertThrown!ResolveException(container.resolve!TestClass);
}

// Test unset persistent registration options
unittest {
    auto container = new shared DependencyContainer();
    container.setPersistentRegistrationOptions(
        RegistrationOption.doNotAddConcreteTypeRegistration);
    container.unsetPersistentRegistrationOptions();
    container.register!(TestInterface, TestClass);
    container.resolve!TestClass;
}

// Test registration when resolving
unittest {
    auto container = new shared DependencyContainer();
    container.resolve!(TestInterface, TestClass)(ResolveOption.registerBeforeResolving);
    container.resolve!TestClass;
}

// Test set persistent resolve options
unittest {
    auto container = new shared DependencyContainer();
    container.setPersistentResolveOptions(ResolveOption.registerBeforeResolving);
    container.resolve!TestClass;
}

// Test unset persistent resolve options
unittest {
    auto container = new shared DependencyContainer();
    container.setPersistentResolveOptions(ResolveOption.registerBeforeResolving);
    container.unsetPersistentResolveOptions();
    assertThrown!ResolveException(container.resolve!TestClass);
}

// Test ResolveOption registerBeforeResolving fails for interfaces
unittest {
    auto container = new shared DependencyContainer();
    assertThrown!ResolveException(
        container.resolve!TestInterface(ResolveOption.registerBeforeResolving));
}

// Test ResolveOption noResolveException does not throw
unittest {
    auto container = new shared DependencyContainer();
    auto instance = container.resolve!TestInterface(ResolveOption.noResolveException);
    assert(instance is null);
}

// ResolveOption noResolveException does not throw for resolveAll
unittest {
    auto container = new shared DependencyContainer();
    auto instances = container.resolveAll!TestInterface(ResolveOption.noResolveException);
    assert(instances.length == 0);
}

// Test autowired, constructor injected class
unittest {
    auto container = new shared DependencyContainer();
    container.register!Red;
    container.register!Moolah;
    container.register!Cocktail;

    auto instance = container.resolve!Cocktail;

    assert(instance !is null);
    assert(instance.moolah is container.resolve!Moolah);
    assert(instance.red is container.resolve!Red);
}

// Test autowired, constructor injected class where constructor argument is templated
unittest {
    auto container = new shared DependencyContainer();
    container.register!PieChart;
    container.register!(TemplatedComponent!PieChart);
    container.register!(ClassWithTemplatedConstructorArg!PieChart);
    auto instance = container.resolve!(ClassWithTemplatedConstructorArg!PieChart);

    assert(instance !is null);
    assert(instance.dependency !is null);
    assert(instance.dependency.instance !is null);
}

// Test injecting constructor with super-type parameter
unittest {
    auto container = new shared DependencyContainer();
    container.register!Wallpaper;
    container.register!(Color, Blue);

    auto instance = container.resolve!Wallpaper;
    assert(instance !is null);
    assert(instance.color is container.resolve!Blue);
}

// Test prevention of circular dependencies during constructor injection
unittest {
    auto container = new shared DependencyContainer();
    container.register!Pot;
    container.register!Kettle;

    assertThrown!InstanceCreationException(container.resolve!Pot);
}

// Test prevention of transitive circular dependencies during constructor injection
unittest {
    auto container = new shared DependencyContainer();
    container.register!Rock;
    container.register!Paper;
    container.register!Scissors;

    assertThrown!InstanceCreationException(container.resolve!Rock);
}

// Test injection of foreign dependency in constructor
unittest {
    auto container = new shared DependencyContainer();
    container.register!Ola;
    container.register!Hello;
    container.resolve!Hello;
}

// Test PostConstruct method is called after resolving a dependency
unittest {
    auto container = new shared DependencyContainer();
    container.register!PostConstructionDependency;

    auto instance = container.resolve!PostConstructionDependency;
    assert(instance.postConstructWasCalled == true);
}

// Test PostConstruct of base type is called
unittest {
    auto container = new shared DependencyContainer();
    container.register!ChildOfPostConstruction;

    auto instance = container.resolve!ChildOfPostConstruction;
    assert(instance.postConstructWasCalled == true);
}

// Test PostConstruct of class implementing interface is not called
unittest {
    auto container = new shared DependencyContainer();
    container.register!ButThereWontBe;

    auto instance = container.resolve!ButThereWontBe;
    assert(instance.postConstructWasCalled == false);
}

// Test postconstruction happens after autowiring and value injection
unittest {
    auto container = new shared DependencyContainer();
    container.register!(ValueInjector!int, PostConstructingIntInjector);
    container.register!PostConstructionDependency;
    container.register!PostConstructWithAutowiring;
    auto instance = container.resolve!PostConstructWithAutowiring;
}

// Test PreDestroy is called when removing a registration
unittest {
    auto container = new shared DependencyContainer();
    container.register!PreDestroyerOfFates;
    auto instance = container.resolve!PreDestroyerOfFates;
    container.removeRegistration!PreDestroyerOfFates;
    assert(instance.preDestroyWasCalled == true);
}

// Test PreDestroy is called when removing all registrations
unittest {
    auto container = new shared DependencyContainer();
    container.register!PreDestroyerOfFates;
    auto instance = container.resolve!PreDestroyerOfFates;
    container.clearAllRegistrations();
    assert(instance.preDestroyWasCalled == true);
}

// Test PreDestroy is called when the container is destroyed
unittest {
    auto container = new shared DependencyContainer();
    container.register!PreDestroyerOfFates;
    auto instance = container.resolve!PreDestroyerOfFates;
    container.destroy();

    assert(instance.preDestroyWasCalled == true);
}

// Test register class by ancestor type
unittest {
    auto container = new shared DependencyContainer();
    container.register!(Grandma, Kid);
    auto instance = container.resolve!Grandma;

    assert(instance !is null);
}

// Test autowiring classes with recursive template parameters
unittest {
    auto container = new shared DependencyContainer();
    container.register!CircularTemplateComponentA;
    container.register!CircularTemplateComponentB;

    auto componentA = container.resolve!CircularTemplateComponentA;
    auto componentB = container.resolve!CircularTemplateComponentB;

    assert(componentA !is null);
    assert(componentB !is null);

    assert(componentA.instance is componentB);
    assert(componentB.instance is componentA);
}

// Test autowiring class where a method is marked with @Autowire does nothing
unittest {
    // It should also not show deprecation warning:
    // Deprecation: `__traits(getAttributes)` may only be used for individual functions, not overload sets such as: `lala`
    //      the result of `__traits(getOverloads)` may be used to select the desired function to extract attributes from

    auto container = new shared DependencyContainer();
    container.register!AutowiredMethod;
    auto instance = container.resolve!AutowiredMethod;

    assert(instance !is null);
    assert(instance.lala == 42);
    assert(instance.lala(77) == 77);
}

// Test autowiring using @Autowire attribute
unittest {
    auto container = new shared DependencyContainer();
    container.register!ComponentA;
    container.register!WithAutowireAttribute;

    auto instance = container.resolve!WithAutowireAttribute;
    assert(instance.componentA is container.resolve!ComponentA);
}
