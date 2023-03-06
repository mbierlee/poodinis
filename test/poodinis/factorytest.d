/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2023 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;
import poodinis.test.testclasses;

import std.exception;

version (unittest) {

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

}
