/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2024 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;
import poodinis.test.testclasses;

import std.exception;

version (unittest) {

    // Test autowiring concrete type to existing instance
    unittest {
        auto container = new shared DependencyContainer();
        container.register!ComponentA;
        auto componentB = new ComponentB();
        container.autowire(componentB);
        assert(componentB !is null, "Autowirable dependency failed to autowire");
    }

    // Test autowiring interface type to existing instance
    unittest {
        auto container = new shared DependencyContainer();
        container.register!(InterfaceA, ComponentC);
        auto componentD = new ComponentD();
        container.autowire(componentD);
        assert(componentD.componentC !is null, "Autowirable dependency failed to autowire");
    }

    // Test autowiring private members
    unittest {
        auto container = new shared DependencyContainer();
        container.register!(InterfaceA, ComponentC);
        auto componentD = new ComponentD();
        container.autowire(componentD);
        assert(componentD.privateComponentC is componentD.componentC,
            "Autowire private dependency failed");
    }

    // Test autowiring will only happen once
    unittest {
        auto container = new shared DependencyContainer();
        container.register!(InterfaceA, ComponentC).newInstance();
        auto componentD = new ComponentD();
        container.autowire(componentD);
        auto expectedComponent = componentD.componentC;
        container.autowire(componentD);
        auto actualComponent = componentD.componentC;
        assert(expectedComponent is actualComponent,
            "Autowiring the second time wired a different instance");
    }

    // Test autowiring unregistered type
    unittest {
        auto container = new shared DependencyContainer();
        auto componentD = new ComponentD();
        assertThrown!(ResolveException)(container.autowire(componentD),
            "Autowiring unregistered type should throw ResolveException");
    }

    // Test autowiring member with non-autowire attribute does not autowire
    unittest {
        auto container = new shared DependencyContainer();
        auto componentE = new ComponentE();
        container.autowire(componentE);
        assert(componentE.componentC is null,
            "Autowiring should not occur for members with attributes other than @Autowire");
    }

    // Test autowire class with alias declaration
    unittest {
        auto container = new shared DependencyContainer();
        container.register!ComponentA;
        auto componentDeclarationCocktail = new ComponentDeclarationCocktail();

        container.autowire(componentDeclarationCocktail);

        assert(componentDeclarationCocktail.componentA !is null,
            "Autowiring class with non-assignable declarations failed");
    }

    // Test autowire class with qualifier
    unittest {
        auto container = new shared DependencyContainer();
        container.register!(InterfaceA, ComponentC);
        container.register!(InterfaceA, ComponentX);
        auto componentX = container.resolve!(InterfaceA, ComponentX);

        auto monkeyShine = new MonkeyShine();
        container.autowire(monkeyShine);

        assert(monkeyShine.component is componentX, "Autowiring class with qualifier failed");
    }

    // Test autowire class with multiple qualifiers
    unittest {
        auto container = new shared DependencyContainer();
        container.register!(InterfaceA, ComponentC);
        container.register!(InterfaceA, ComponentX);
        auto componentC = container.resolve!(InterfaceA, ComponentC);
        auto componentX = container.resolve!(InterfaceA, ComponentX);

        auto bootstrapBootstrap = new BootstrapBootstrap();
        container.autowire(bootstrapBootstrap);

        assert(bootstrapBootstrap.componentX is componentX,
            "Autowiring class with multiple qualifiers failed");
        assert(bootstrapBootstrap.componentC is componentC,
            "Autowiring class with multiple qualifiers failed");
    }

    // Test getting instance from autowired registration will autowire instance
    unittest {
        auto container = new shared DependencyContainer();
        container.register!ComponentA;

        auto registration = new AutowiredRegistration!ComponentB(typeid(ComponentB),
            new InstanceFactory(), container).initializeFactoryType().singleInstance();
        auto instance = cast(ComponentB) registration.getInstance(
            new AutowireInstantiationContext());

        assert(instance.componentA !is null);
    }

    // Test autowiring a dynamic array with all qualified types
    unittest {
        auto container = new shared DependencyContainer();
        container.register!(InterfaceA, ComponentC);
        container.register!(InterfaceA, ComponentX);

        auto lord = new LordOfTheComponents();
        container.autowire(lord);

        assert(lord.components.length == 2, "Dynamic array was not autowired");
    }

    // Test autowiring new instance of singleinstance registration with newInstance UDA
    unittest {
        auto container = new shared DependencyContainer();
        container.register!ComponentA;

        auto regularComponentA = container.resolve!ComponentA;
        auto charlie = new ComponentCharlie();

        container.autowire(charlie);

        assert(charlie.componentA !is regularComponentA,
            "Autowiring class with AssignNewInstance did not yield a different instance");
    }

    // Test autowiring members from base class
    unittest {
        auto container = new shared DependencyContainer();
        container.register!ComponentA;
        container.register!ComponentB;
        container.register!ComponentZ;

        auto instance = new ComponentZ();
        container.autowire(instance);

        assert(instance.componentA !is null);
    }

    // Test autowiring optional dependencies
    unittest {
        auto container = new shared DependencyContainer();
        auto instance = new OuttaTime();

        container.autowire(instance);

        assert(instance.interfaceA is null);
        assert(instance.componentA is null);
        assert(instance.componentCs is null);
    }

    // Test autowiring class using value injection
    unittest {
        auto container = new shared DependencyContainer();

        container.register!(ValueInjector!int, TestInjector);
        container.register!ComponentA;
        auto instance = new ValuedClass();

        container.autowire(instance);

        assert(instance.intValue == 8);
        assert(instance.unrelated !is null);
    }
}
