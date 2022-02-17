/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2022 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;
import poodinis.test.testClasses;

import std.exception;

version (unittest)
{

    //Test register component registrations from context
    unittest
    {
        auto container = new shared DependencyContainer();
        auto context = new TestContext();
        context.registerContextComponents(container);
        auto bananaInstance = container.resolve!Banana;

        assert(bananaInstance.color == "Yellow");
    }

    //Test non-annotated methods are not registered
    unittest
    {
        auto container = new shared DependencyContainer();
        auto context = new TestContext();
        context.registerContextComponents(container);
        assertThrown!ResolveException(container.resolve!Apple);
    }

    //Test register component by base type
    unittest
    {
        auto container = new shared DependencyContainer();
        auto context = new TestContext();
        context.registerContextComponents(container);
        auto instance = container.resolve!Fruit;
        assert(instance.getShape() == "Pear shaped");
    }

    //Test register components with multiple candidates
    unittest
    {
        auto container = new shared DependencyContainer();
        auto context = new TestContext();
        context.registerContextComponents(container);

        auto rabbit = container.resolve!(Animal, Rabbit);
        assert(rabbit.getYell() == "Squeeeeeel");

        auto wolf = container.resolve!(Animal, Wolf);
        assert(wolf.getYell() == "Wooooooooooo");
    }

    //Test register component as prototype
    unittest
    {
        auto container = new shared DependencyContainer();
        auto context = new TestContext();
        context.registerContextComponents(container);

        auto firstInstance = container.resolve!PieChart;
        auto secondInstance = container.resolve!PieChart;

        assert(firstInstance !is null && secondInstance !is null);
        assert(firstInstance !is secondInstance);
    }

    // Test setting up simple dependencies through application context
    unittest
    {
        auto container = new shared DependencyContainer();
        container.registerContext!SimpleContext;
        auto instance = container.resolve!CakeChart;

        assert(instance !is null);
    }

    // Test resolving dependency from registered application context
    unittest
    {
        auto container = new shared DependencyContainer();
        container.registerContext!SimpleContext;
        auto instance = container.resolve!Apple;

        assert(instance !is null);
    }

    // Test autowiring application context
    unittest
    {
        auto container = new shared DependencyContainer();
        container.register!Apple;
        container.registerContext!AutowiredTestContext;
        auto instance = container.resolve!ClassWrapper;

        assert(instance !is null);
        assert(instance.someClass !is null);
    }

    // Test autowiring application context with dependencies registered in same context
    unittest
    {
        auto container = new shared DependencyContainer();
        container.registerContext!ComplexAutowiredTestContext;
        auto instance = container.resolve!ClassWrapperWrapper;
        auto wrapper = container.resolve!ClassWrapper;
        auto someClass = container.resolve!Apple;

        assert(instance !is null);
        assert(instance.wrapper is wrapper);
        assert(instance.wrapper.someClass is someClass);
    }

    // Test resolving registered context
    unittest
    {
        auto container = new shared DependencyContainer();
        container.registerContext!TestContext;
        container.resolve!ApplicationContext;
    }
}
