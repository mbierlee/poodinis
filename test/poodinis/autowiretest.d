/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis.autowire;

import std.exception;

version(unittest) {
	class ComponentA {}
	
	class ComponentB {
		public @Autowire ComponentA componentA;
		
		public bool componentIsNull() {
			return componentA is null;
		}
	}
	
	interface InterfaceA {}
	
	class ComponentC : InterfaceA {}
	
	class ComponentD {
		public @Autowire InterfaceA componentC = null;
		
		public bool componentIsNull() {
			return componentC is null;
		}
	}
	
	class DummyAttribute{};
	
	class ComponentE {
		@DummyAttribute
		public ComponentC componentC;
	}
	
	class ComponentF {
		@Autowired
		public ComponentA componentA;
		
		mixin AutowireConstructor;
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
		@Autowire
		@Qualifier!ComponentX
		public InterfaceA component;
	}
	
	class BootstrapBootstrap {
		@Autowire
		@Qualifier!ComponentX
		public InterfaceA componentX;
		
		@Autowire
		@Qualifier!ComponentC
		public InterfaceA componentC;
	}
	
	// Test autowiring concrete type to existing instance
	unittest {
		auto container = new DependencyContainer();
		container.register!ComponentA;
		auto componentB = new ComponentB();
		container.autowire!(ComponentB)(componentB);
		assert(!componentB.componentIsNull(), "Autowirable dependency failed to autowire");
	}
	
	// Test autowiring interface type to existing instance
	unittest {
		auto container = new DependencyContainer();
		container.register!(InterfaceA, ComponentC);
		auto componentD = new ComponentD();
		container.autowire!(ComponentD)(componentD);
		assert(!componentD.componentIsNull(), "Autowirable dependency failed to autowire");
	}
	
	// Test autowiring will only happen once
	unittest {
		auto container = new DependencyContainer();
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
		auto container = new DependencyContainer();
		auto componentD = new ComponentD();
		assertThrown!(ResolveException)(container.autowire!(ComponentD)(componentD), "Autowiring unregistered type should throw ResolveException");
	}
	
	// Test autowiring member with non-autowire attribute does not autowire
	unittest {
		auto container = new DependencyContainer();
		auto componentE = new ComponentE();
		container.autowire!ComponentE(componentE);
		assert(componentE.componentC is null, "Autowiring should not occur for members with attributes other than @Autowire");
	}
	
	// Test autowire in constructor
	unittest {
		auto container = DependencyContainer.getInstance();
		container.register!ComponentA;
		auto componentF = new ComponentF();
		auto autowiredComponentA = componentF.componentA;
		container.register!(ComponentF).existingInstance(componentF);
		assert(componentF.componentA !is null, "Constructor did not autowire component F");
		
		auto resolvedComponentF = container.resolve!ComponentF;
		assert(resolvedComponentF.componentA is autowiredComponentA, "Resolving instance of ComponentF rewired members");
		
		container.clearAllRegistrations();
	}
	
	// Test autowire class with alias declaration
	unittest {
		auto container = new DependencyContainer();
		container.register!ComponentA;
		auto componentDeclarationCocktail = new ComponentDeclarationCocktail();
		
		container.autowire(componentDeclarationCocktail);
		
		assert(componentDeclarationCocktail.componentA !is null, "Autowiring class with non-assignable declarations failed");
	}
	
	// Test autowire class with qualifier
	unittest {
		auto container = new DependencyContainer();
		container.register!(InterfaceA, ComponentC);
		container.register!(InterfaceA, ComponentX);
		auto componentX = container.resolve!(InterfaceA, ComponentX);
		
		auto monkeyShine = new MonkeyShine();
		container.autowire(monkeyShine);
		
		assert(monkeyShine.component is componentX, "Autowiring class with qualifier failed");
	}
	
	// Test autowire class with multiple qualifiers
	unittest {
		auto container = new DependencyContainer();
		container.register!(InterfaceA, ComponentC);
		container.register!(InterfaceA, ComponentX);
		auto componentC = container.resolve!(InterfaceA, ComponentC);
		auto componentX = container.resolve!(InterfaceA, ComponentX);
		
		auto bootstrapBootstrap = new BootstrapBootstrap();
		container.autowire(bootstrapBootstrap);
		
		assert(bootstrapBootstrap.componentX is componentX, "Autowiring class with multiple qualifiers failed");
		assert(bootstrapBootstrap.componentC is componentC, "Autowiring class with multiple qualifiers failed");
	}
}