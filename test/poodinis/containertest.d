import poodinis.container;

import std.exception;

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
		assert(registration.registeredType == typeid(TestClass), "Type of registered type not the same");
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
		// Test register unrelated types fails
		assertThrown!RegistrationException(Container.register!(UnrelatedClass, TestClass)(), "Registering unrelated types does not fail");
	}
	
	unittest {
		// Test register unrelated types with disabled check on registration
		assertNotThrown!RegistrationException(Container.register!(UnrelatedClass, TestClass)(false), "Registering unrelated types while disabling type validity fails");
	}
	
}