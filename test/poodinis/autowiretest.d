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
	
	// Test autowiring concrete type to existing instance
	unittest {
		auto container = new Container();
		container.register!ComponentA;
		ComponentB componentB = new ComponentB();
		container.autowire!(ComponentB)(componentB);
		assert(!componentB.componentIsNull(), "Autowirable dependency failed to autowire");
	}
}