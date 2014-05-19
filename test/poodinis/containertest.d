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
		auto container = new Container();
		auto registration = container.register!(TestClass)();
		assert(registration.registeredType == typeid(TestClass), "Type of registered type not the same");
	}
	
	unittest {
		// Test resolve registered type
		auto container = new Container();
		container.register!(TestClass)();
		TestClass actualInstance = container.resolve!(TestClass)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestClass) actualInstance, "Resolved class is not the same type as expected");
	}
	
	unittest {
		// Test register interface
		auto container = new Container();
		container.register!(TestInterface, TestClass)();
		TestInterface actualInstance = container.resolve!(TestInterface)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestInterface) actualInstance, "Resolved class is not the same type as expected");
	}
	
	unittest {
		// Test register unrelated types fails
		auto container = new Container();
		assertThrown!RegistrationException(container.register!(UnrelatedClass, TestClass)(), "Registering unrelated types does not fail");
	}
	
	unittest {
		// Test register unrelated types with disabled check on registration
		auto container = new Container();
		assertNotThrown!RegistrationException(container.register!(UnrelatedClass, TestClass)(false), "Registering unrelated types while disabling type validity fails");
	}
	
	unittest {
		// Test resolve non-registered type
		auto container = new Container();
		assertThrown!ResolveException(container.resolve!(TestClass)(), "Resolving non-registered type does not fail");
	}
	
	unittest {
		// Test register unrelated class with disable global type validity disabled
		auto container = new Container();
		container.typeValidityCheckEnabled = false;
		assertNotThrown!RegistrationException(container.register!(UnrelatedClass, TestClass)(), "Registering unrelated types while disabling global type validity fails");
	}
	
	unittest {
		// Test clear registrations
		auto container = new Container();
		container.register!(TestClass)();
		container.clearRegistrations();
		assertThrown!ResolveException(container.resolve!(TestClass)(), "Resolving cleared type does not fail");
	}
	
}