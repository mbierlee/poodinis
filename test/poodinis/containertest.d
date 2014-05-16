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
		Container.clearRegistrations();
		auto registration = Container.register!(TestClass)();
		assert(registration.registeredType == typeid(TestClass), "Type of registered type not the same");
	}
	
	unittest {
		// Test resolve registered type
		Container.clearRegistrations();
		Container.register!(TestClass)();
		TestClass actualInstance = Container.resolve!(TestClass)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestClass) actualInstance, "Resolved class is not the same type as expected");
	}
	
	unittest {
		// Test register interface
		Container.clearRegistrations();
		Container.register!(TestInterface, TestClass)();
		TestInterface actualInstance = Container.resolve!(TestInterface)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestInterface) actualInstance, "Resolved class is not the same type as expected");
	}
	
	unittest {
		// Test register unrelated types fails
		Container.clearRegistrations();
		assertThrown!RegistrationException(Container.register!(UnrelatedClass, TestClass)(), "Registering unrelated types does not fail");
	}
	
	unittest {
		// Test register unrelated types with disabled check on registration
		Container.clearRegistrations();
		assertNotThrown!RegistrationException(Container.register!(UnrelatedClass, TestClass)(false), "Registering unrelated types while disabling type validity fails");
	}
	
	unittest {
		// Test resolve non-registered type
		Container.clearRegistrations();
		assertThrown!ResolveException(Container.resolve!(TestClass)(), "Resolving non-registered type does not fail");
	}
	
}