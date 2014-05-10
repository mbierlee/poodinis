import poodinis.container;

import std.stdio;

version(unittest) {
	class TestClass  {
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
		assert(typeid(actualInstance) == typeid(TestClass), "Resolved class is not the same type as expected");
	}
}