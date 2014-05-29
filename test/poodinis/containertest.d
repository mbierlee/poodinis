import poodinis.container;

import std.exception;

version(unittest) {
	interface TestInterface {
	}
	
	class TestClass : TestInterface {
	}
	
	class UnrelatedClass{
	}
	
	class FailOnCreationClass {
		this() {
			throw new Exception("This class should not be instantiated");
		}
	}
	
	// Test register concrete type
	unittest {
		auto container = new Container();
		auto registration = container.register!(TestClass)();
		assert(registration.registeredType == typeid(TestClass), "Type of registered type not the same");
	}
	
	// Test resolve registered type
	unittest {
		auto container = new Container();
		container.register!(TestClass)();
		TestClass actualInstance = container.resolve!(TestClass)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestClass) actualInstance, "Resolved class is not the same type as expected");
	}
	
	// Test register interface
	unittest {
		auto container = new Container();
		container.register!(TestInterface, TestClass)();
		TestInterface actualInstance = container.resolve!(TestInterface)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestInterface) actualInstance, "Resolved class is not the same type as expected");
	}
	
	// Test register unrelated types fails
	unittest {
		auto container = new Container();
		assertThrown!RegistrationException(container.register!(UnrelatedClass, TestClass)(), "Registering unrelated types does not fail");
	}
	
	// Test register unrelated types with disabled check on registration
	unittest {
		auto container = new Container();
		assertNotThrown!RegistrationException(container.register!(UnrelatedClass, TestClass)(false), "Registering unrelated types while disabling type validity fails");
	}
	
	// Test resolve non-registered type
	unittest {
		auto container = new Container();
		assertThrown!ResolveException(container.resolve!(TestClass)(), "Resolving non-registered type does not fail");
	}
	
	// Test register unrelated class with disable global type validity disabled
	unittest {
		auto container = new Container();
		container.typeValidityCheckEnabled = false;
		assertNotThrown!RegistrationException(container.register!(UnrelatedClass, TestClass)(), "Registering unrelated types while disabling global type validity fails");
	}
	
	// Test clear registrations
	unittest {
		auto container = new Container();
		container.register!(TestClass)();
		container.clearRegistrations();
		assertThrown!ResolveException(container.resolve!(TestClass)(), "Resolving cleared type does not fail");
	}
	
	// Test get singleton of container
	unittest {
		auto instance1 = Container.getInstance();
		auto instance2 = Container.getInstance();
		assert(instance1 is instance2, "getInstance does not return the same instance");
	}
	
	// Test registering concrete type does not do a validity check
	unittest {
		auto container = new Container();
		assert(container.typeValidityCheckEnabled);
		try {
			container.register!(FailOnCreationClass)();
		} catch (Exception)  {
			assert(false, "Registering concrete type executed a validity check");
		}
	}
	
	// Test resolve single instance for type
	unittest {
		auto container = new Container();
		container.register!(TestClass)().singleInstance();
		auto instance1 = container.resolve!(TestClass);
		auto instance2 = container.resolve!(TestClass);
		assert(instance1 is instance2, "Resolved instance from single instance scope is not the each time it is resolved");
	}
	
	// Test resolve new instance for type
	unittest {
		auto container = new Container();
		container.register!(TestClass)().newInstance();
		auto instance1 = container.resolve!(TestClass);
		auto instance2 = container.resolve!(TestClass);
		assert(instance1 !is instance2, "Resolved instance from new instance scope is the same each time it is resolved");
	}
	
	// Test resolve existing instance for type
	unittest {
		auto container = new Container();
		auto expectedInstance = new TestClass();
		container.register!(TestClass)().existingInstance(expectedInstance);
		auto actualInstance = container.resolve!(TestClass);
		assert(expectedInstance is actualInstance, "Resolved instance from existing instance scope is not the same as the registered instance");
	}
	
}