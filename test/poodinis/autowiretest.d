/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2015 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.exception;

version(unittest) {
	class ComponentA {}

	class ComponentB {
		public @Autowire ComponentA componentA;
	}

	interface InterfaceA {}

	class ComponentC : InterfaceA {}

	class ComponentD {
		public @Autowire InterfaceA componentC = null;
        private @Autowire InterfaceA privateComponentC = null;
	}

	class DummyAttribute{};

	class ComponentE {
		@DummyAttribute
		public ComponentC componentC;
	}

	class ComponentDeclarationCocktail {
		alias noomer = int;

		@Autowire
		public ComponentA componentA;

		public void doesNothing() {
		}

		~this(){
		}
	}

	class ComponentX : InterfaceA {}

	class MonkeyShine {
		@Autowire!ComponentX
		public InterfaceA component;
	}

	class BootstrapBootstrap {
		@Autowire!ComponentX
		public InterfaceA componentX;

		@Autowire!ComponentC
		public InterfaceA componentC;
	}

	class LordOfTheComponents {
		@Autowire
		public InterfaceA[] components;
	}
	class ComponentCharlie {
		@Autowire
		@AssignNewInstance
		public ComponentA componentA;
	}

	// Test autowiring concrete type to existing instance
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!ComponentA;
		auto componentB = new ComponentB();
		container.autowire!(ComponentB)(componentB);
		assert(componentB !is null, "Autowirable dependency failed to autowire");
	}

	// Test autowiring interface type to existing instance
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(InterfaceA, ComponentC);
		auto componentD = new ComponentD();
		container.autowire!(ComponentD)(componentD);
		assert(componentD.componentC !is null, "Autowirable dependency failed to autowire");
	}

    // Test autowiring private members
    unittest {
        shared(DependencyContainer) container = new DependencyContainer();
        container.register!(InterfaceA, ComponentC);
        auto componentD = new ComponentD();
        container.autowire!(ComponentD)(componentD);
        assert(componentD.privateComponentC is componentD.componentC, "Autowire private dependency failed");
    }

	// Test autowiring will only happen once
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(InterfaceA, ComponentC).newInstance();
		auto componentD = new ComponentD();
		container.autowire!(ComponentD)(componentD);
		auto expectedComponent = componentD.componentC;
		container.autowire!(ComponentD)(componentD);
		auto actualComponent = componentD.componentC;
		assert(expectedComponent is actualComponent, "Autowiring the second time wired a different instance");
	}

	// Test autowiring unregistered type
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		auto componentD = new ComponentD();
		assertThrown!(ResolveException)(container.autowire!(ComponentD)(componentD), "Autowiring unregistered type should throw ResolveException");
	}

	// Test autowiring member with non-autowire attribute does not autowire
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		auto componentE = new ComponentE();
		container.autowire!ComponentE(componentE);
		assert(componentE.componentC is null, "Autowiring should not occur for members with attributes other than @Autowire");
	}

	// Test autowire class with alias declaration
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!ComponentA;
		auto componentDeclarationCocktail = new ComponentDeclarationCocktail();

		container.autowire(componentDeclarationCocktail);

		assert(componentDeclarationCocktail.componentA !is null, "Autowiring class with non-assignable declarations failed");
	}

	// Test autowire class with qualifier
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(InterfaceA, ComponentC);
		container.register!(InterfaceA, ComponentX);
		auto componentX = container.resolve!(InterfaceA, ComponentX);

		auto monkeyShine = new MonkeyShine();
		container.autowire(monkeyShine);

		assert(monkeyShine.component is componentX, "Autowiring class with qualifier failed");
	}

	// Test autowire class with multiple qualifiers
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(InterfaceA, ComponentC);
		container.register!(InterfaceA, ComponentX);
		auto componentC = container.resolve!(InterfaceA, ComponentC);
		auto componentX = container.resolve!(InterfaceA, ComponentX);

		auto bootstrapBootstrap = new BootstrapBootstrap();
		container.autowire(bootstrapBootstrap);

		assert(bootstrapBootstrap.componentX is componentX, "Autowiring class with multiple qualifiers failed");
		assert(bootstrapBootstrap.componentC is componentC, "Autowiring class with multiple qualifiers failed");
	}

	// Test getting instance from autowired registration will autowire instance
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!ComponentA;

		auto registration = new AutowiredRegistration!ComponentB(typeid(ComponentB), container).singleInstance();
		auto instance = cast(ComponentB) registration.getInstance(new AutowireInstantiationContext());

		assert(instance.componentA !is null);
	}

	// Test autowiring a dynamic array with all qualified types
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(InterfaceA, ComponentC);
		container.register!(InterfaceA, ComponentX);

		auto lord = new LordOfTheComponents();
		container.autowire(lord);

		assert(lord.components.length == 2, "Dynamic array was not autowired");
	}

	// Test autowiring new instance of singleinstance registration with newInstance UDA
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!ComponentA;

		auto regularComponentA = container.resolve!ComponentA;
		auto charlie = new ComponentCharlie();

		container.autowire(charlie);

		assert(charlie.componentA !is regularComponentA, "Autowiring class with AssignNewInstance did not yield a different instance");
	}
}
