import poodinis.container;

import std.stdio;

version(unittest) {
	interface TestInterface {
	}
	
	class TestClass : TestInterface {
	}
	
	class UnrelatedClass{
	}
	
	unittest {
		// Test register concrete type
		auto registration = Container.register!(TestClass)();
		assert(registration.registratedType == typeid(TestClass), "Type of registered type not the same");
	}
	
	unittest {
		// Test resolve registered type
		Container.register!(TestClass)();
		TestClass actualInstance = Container.resolve!(TestClass)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestClass) actualInstance, "Resolved class is not the same type as expected");
	}
	
	unittest {
		// Test register interface
		Container.register!(TestInterface, TestClass)();
		TestInterface actualInstance = Container.resolve!(TestInterface)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestInterface) actualInstance, "Resolved class is not the same type as expected");
	}
	
	unittest {
		// Test resolve type registered with unrelated type fails
		Container.register!(UnrelatedClass, TestClass)();
		UnrelatedClass actualInstance = Container.resolve!(UnrelatedClass)();
		assert(actualInstance is null, "Resolved type is not null");
	}
}