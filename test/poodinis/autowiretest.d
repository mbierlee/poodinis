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
	
	// Test autowiring concrete type to existing instance
	unittest {
		auto container = new Container();
		container.register!ComponentA;
		ComponentB componentB = new ComponentB();
		container.autowire!(ComponentB)(componentB);
		assert(!componentB.componentIsNull(), "Autowirable dependency failed to autowire");
	}
	
	// Test autowiring interface type to existing instance
	unittest {
		auto container = new Container();
		container.register!(InterfaceA, ComponentC);
		ComponentD componentD = new ComponentD();
		container.autowire!(ComponentD)(componentD);
		assert(!componentD.componentIsNull(), "Autowirable dependency failed to autowire");
	}
	
	// Test autowiring will only happen once
	unittest {
		auto container = new Container();
		container.register!(InterfaceA, ComponentC).newInstance();
		ComponentD componentD = new ComponentD();
		container.autowire!(ComponentD)(componentD);
		auto expectedComponent = componentD.componentC;
		container.autowire!(ComponentD)(componentD);
		auto actualComponent = componentD.componentC;
		assert(expectedComponent is actualComponent, "Autowiring the second time wired a different instance");
	}
	
	// Test autowiring unregistered type
	unittest {
		auto container = new Container();
		ComponentD componentD = new ComponentD();
		assertThrown!(ResolveException)(container.autowire!(ComponentD)(componentD), "Autowiring unregistered type should throw ResolveException");
	}
}