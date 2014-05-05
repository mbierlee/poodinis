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
	
}