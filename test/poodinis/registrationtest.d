/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2023 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;
import poodinis.test.testclasses;

import std.exception;

version (unittest)
{

    // Test getting instance without scope defined throws exception
    unittest
    {
        Registration registration = new Registration(typeid(TestType), null, null, null);
        assertThrown!(InstanceCreationException)(registration.getInstance(), null);
    }

    // Test set single instance scope using scope setter
    unittest
    {
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
    unittest
    {
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
    unittest
    {
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
    unittest
    {
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
    unittest
    {
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
    unittest
    {
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
    unittest
    {
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

}
