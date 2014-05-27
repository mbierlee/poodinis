import poodinis.autowire;

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
		public @Autowire InterfaceA componentC;
		
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
}