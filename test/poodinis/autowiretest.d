/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis.autowire;

import std.exception;

version(unittest) {
	class ComponentA {
	}
	
	class ComponentB {
		public @Autowire ComponentA componentA;
		
		public bool componentIsNull() {
			return componentA is null;
		}
	}
	
	interface InterfaceA {
	}
	
	class ComponentC : InterfaceA {
	}
	
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
		@Autowire
		public ComponentA componentA;
		
		public this() {
			auto container = Container.getInstance();
			container.autowire!ComponentF(this);
		}
	}
	
	// Test autowiring concrete type to existing instance
	unittest {
		auto container = new Container();
		container.register!ComponentA;
		auto componentB = new ComponentB();
		container.autowire!(ComponentB)(componentB);
		assert(!componentB.componentIsNull(), "Autowirable dependency failed to autowire");
	}
	
	// Test autowiring interface type to existing instance
	unittest {
		auto container = new Container();
		container.register!(InterfaceA, ComponentC);
		auto componentD = new ComponentD();
		container.autowire!(ComponentD)(componentD);
		assert(!componentD.componentIsNull(), "Autowirable dependency failed to autowire");
	}
	
	// Test autowiring will only happen once
	unittest {
		auto container = new Container();
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
		auto container = new Container();
		auto componentD = new ComponentD();
		assertThrown!(ResolveException)(container.autowire!(ComponentD)(componentD), "Autowiring unregistered type should throw ResolveException");
	}
	
	// Test autowiring member with non-autowire attribute does not autowire
	unittest {
		auto container = new Container();
		auto componentE = new ComponentE();
		container.autowire!ComponentE(componentE);
		assert(componentE.componentC is null, "Autowiring should not occur for members with attributes other than @Autowire");
	}
	
	// Test autowire in constructor
	unittest {
		auto container = Container.getInstance();
		container.register!ComponentA;
		auto componentF = new ComponentF();
		auto autowiredComponentA = componentF.componentA;
		container.register!(ComponentF).existingInstance(componentF);
		assert(componentF.componentA !is null, "Constructor did not autowire component F");
		
		auto resolvedComponentF = container.resolve!ComponentF;
		assert(resolvedComponentF.componentA is autowiredComponentA, "Resolving instance of ComponentF rewired members");
	}
}