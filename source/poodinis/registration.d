/**
 * This module contains objects for defining and scoping dependency registrations.
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

module poodinis.registration;

import poodinis.container : DependencyContainer;
import poodinis.factory : InstanceFactory, InstanceEventHandler,
    InstanceCreationException, InstanceFactoryParameters, CreatesSingleton;

class Registration {
    private TypeInfo _registeredType = null;
    private TypeInfo_Class _instanceType = null;
    private Registration linkedRegistration;
    private shared(DependencyContainer) _originatingContainer;
    private InstanceFactory _instanceFactory;
    private void delegate() _preDestructor;

    TypeInfo registeredType() {
        return _registeredType;
    }

    TypeInfo_Class instanceType() {
        return _instanceType;
    }

    shared(DependencyContainer) originatingContainer() {
        return _originatingContainer;
    }

    InstanceFactory instanceFactory() {
        return _instanceFactory;
    }

    void delegate() preDestructor() {
        return _preDestructor;
    }

    protected void preDestructor(void delegate() preDestructor) {
        _preDestructor = preDestructor;
    }

    this(TypeInfo registeredType, TypeInfo_Class instanceType,
        InstanceFactory instanceFactory, shared(DependencyContainer) originatingContainer) {
        this._registeredType = registeredType;
        this._instanceType = instanceType;
        this._originatingContainer = originatingContainer;
        this._instanceFactory = instanceFactory;
    }

    Object getInstance(InstantiationContext context = new InstantiationContext()) {
        if (linkedRegistration !is null) {
            return linkedRegistration.getInstance(context);
        }

        if (instanceFactory is null) {
            throw new InstanceCreationException(
                "No instance factory defined for registration of type " ~ registeredType.toString());
        }

        return instanceFactory.getInstance();
    }

    Registration linkTo(Registration registration) {
        this.linkedRegistration = registration;
        return this;
    }

    Registration onConstructed(InstanceEventHandler handler) {
        if (instanceFactory !is null)
            instanceFactory.onConstructed(handler);
        return this;
    }
}

private InstanceFactoryParameters copyFactoryParameters(Registration registration) {
    return registration.instanceFactory.factoryParameters;
}

private void setFactoryParameters(Registration registration, InstanceFactoryParameters newParameters) {
    registration.instanceFactory.factoryParameters = newParameters;
}

/**
 * Sets the registration's instance factory type the same as the registration's.
 *
 * This is not a registration scope. Typically used by Poodinis internally only.
 */
Registration initializeFactoryType(Registration registration) {
    auto params = registration.copyFactoryParameters();
    params.instanceType = registration.instanceType;
    registration.setFactoryParameters(params);
    return registration;
}

/**
 * Scopes registrations to return the same instance every time a given registration is resolved.
 *
 * Effectively makes the given registration a singleton.
 */
Registration singleInstance(Registration registration) {
    auto params = registration.copyFactoryParameters();
    params.createsSingleton = CreatesSingleton.yes;
    registration.setFactoryParameters(params);
    return registration;
}

/**
 * Scopes registrations to return a new instance every time the given registration is resolved.
 */
Registration newInstance(Registration registration) {
    auto params = registration.copyFactoryParameters();
    params.createsSingleton = CreatesSingleton.no;
    params.existingInstance = null;
    registration.setFactoryParameters(params);
    return registration;
}

/**
 * Scopes registrations to return the given instance every time the given registration is resolved.
 */
Registration existingInstance(Registration registration, Object instance) {
    auto params = registration.copyFactoryParameters();
    params.createsSingleton = CreatesSingleton.yes;
    params.existingInstance = instance;
    registration.setFactoryParameters(params);
    return registration;
}

/**
 * Scopes registrations to create new instances using the given initializer delegate.
 */
Registration initializedBy(T)(Registration registration, T delegate() initializer)
        if (is(T == class) || is(T == interface)) {
    auto params = registration.copyFactoryParameters();
    params.createsSingleton = CreatesSingleton.no;
    params.factoryMethod = () => cast(Object) initializer();
    registration.setFactoryParameters(params);
    return registration;
}

/**
 * Scopes registrations to create a new instance using the given initializer delegate. On subsequent resolves the same instance is returned.
 */
Registration initializedOnceBy(T : Object)(Registration registration, T delegate() initializer) {
    auto params = registration.copyFactoryParameters();
    params.createsSingleton = CreatesSingleton.yes;
    params.factoryMethod = () => cast(Object) initializer();
    registration.setFactoryParameters(params);
    return registration;
}

string toConcreteTypeListString(Registration[] registrations) {
    auto concreteTypeListString = "";
    foreach (registration; registrations) {
        if (concreteTypeListString.length > 0) {
            concreteTypeListString ~= ", ";
        }
        concreteTypeListString ~= registration.instanceType.toString();
    }
    return concreteTypeListString;
}

class InstantiationContext {
}

version (unittest)  :  //

import poodinis;
import poodinis.testclasses;
import std.exception;

// Test getting instance without scope defined throws exception
unittest {
    Registration registration = new Registration(typeid(TestType), null, null, null);
    assertThrown!(InstanceCreationException)(registration.getInstance(), null);
}

// Test set single instance scope using scope setter
unittest {
    Registration registration = new Registration(null, typeid(TestType),
        new InstanceFactory(), null).initializeFactoryType();
    auto chainedRegistration = registration.singleInstance();
    auto instance1 = registration.getInstance();
    auto instance2 = registration.getInstance();
    assert(instance1 is instance2,
        "Registration with single instance scope did not return the same instance");
    assert(registration is chainedRegistration,
        "Registration returned by scope setting is not the same as the registration being set");
}

// Test set new instance scope using scope setter
unittest {
    Registration registration = new Registration(null, typeid(TestType),
        new InstanceFactory(), null).initializeFactoryType();
    auto chainedRegistration = registration.newInstance();
    auto instance1 = registration.getInstance();
    auto instance2 = registration.getInstance();
    assert(instance1 !is instance2,
        "Registration with new instance scope did not return a different instance");
    assert(registration is chainedRegistration,
        "Registration returned by scope setting is not the same as the registration being set");
}

// Test set existing instance scope using scope setter
unittest {
    Registration registration = new Registration(null, null, new InstanceFactory(), null);
    auto expectedInstance = new TestType();
    auto chainedRegistration = registration.existingInstance(expectedInstance);
    auto actualInstance = registration.getInstance();
    assert(expectedInstance is actualInstance,
        "Registration with existing instance scope did not return the same instance");
    assert(registration is chainedRegistration,
        "Registration returned by scope setting is not the same as the registration being set");
}

// Test linking registrations
unittest {
    Registration firstRegistration = new Registration(typeid(TestInterface),
        typeid(TestImplementation), new InstanceFactory(), null).initializeFactoryType()
        .singleInstance();
    Registration secondRegistration = new Registration(typeid(TestImplementation),
        typeid(TestImplementation), new InstanceFactory(), null).initializeFactoryType()
        .singleInstance().linkTo(firstRegistration);

    auto firstInstance = firstRegistration.getInstance();
    auto secondInstance = secondRegistration.getInstance();

    assert(firstInstance is secondInstance);
}

// Test custom factory method via initializedBy
unittest {
    Registration registration = new Registration(typeid(TestInterface),
        typeid(TestImplementation), new InstanceFactory(), null);

    registration.initializedBy({
        auto instance = new TestImplementation();
        instance.someContent = "createdbyinitializer";
        return instance;
    });

    TestImplementation instanceOne = cast(TestImplementation) registration.getInstance();
    TestImplementation instanceTwo = cast(TestImplementation) registration.getInstance();
    assert(instanceOne.someContent == "createdbyinitializer");
    assert(instanceTwo.someContent == "createdbyinitializer");
    assert(instanceOne !is instanceTwo);
}

// Test custom factory method via initializedOnceBy
unittest {
    Registration registration = new Registration(typeid(TestInterface),
        typeid(TestImplementation), new InstanceFactory(), null);

    registration.initializedOnceBy({
        auto instance = new TestImplementation();
        instance.someContent = "createdbyinitializer";
        return instance;
    });

    TestImplementation instanceOne = cast(TestImplementation) registration.getInstance();
    TestImplementation instanceTwo = cast(TestImplementation) registration.getInstance();
    assert(instanceOne.someContent == "createdbyinitializer");
    assert(instanceTwo.someContent == "createdbyinitializer");
    assert(instanceOne is instanceTwo);
}

// Test chaining single/new instance scope to initializedBy will not overwrite the factory method.
unittest {
    Registration registration = new Registration(typeid(TestInterface),
        typeid(TestImplementation), new InstanceFactory(), null);

    registration.initializedBy({
        auto instance = new TestImplementation();
        instance.someContent = "createdbyinitializer";
        return instance;
    });

    registration.singleInstance();

    TestImplementation instanceOne = cast(TestImplementation) registration.getInstance();
    TestImplementation instanceTwo = cast(TestImplementation) registration.getInstance();
    assert(instanceOne.someContent == "createdbyinitializer");
    assert(instanceTwo.someContent == "createdbyinitializer");
    assert(instanceOne is instanceTwo);
}
