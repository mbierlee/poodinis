import poodinis.registration;

import std.exception;

version(unittest) {
	class TestType {
	}
	
	// Test getting instance without scope defined throws exception
	unittest {
		Registration registration = new Registration(null, null);
		registration.registeredType = typeid(TestType);
		assertThrown!(NoScopeDefinedException)(registration.getInstance());
	}
	
	// Test getting instance from single instance scope
	unittest {
		Registration registration = new Registration(null, null);
		registration.registationScope = new SingleInstanceScope(typeid(TestType));
		auto instance1 = registration.getInstance();
		auto instance2 = registration.getInstance();
		assert(instance1 is instance2, "Registration with single instance scope did not return the same instance");
	}
	
	// Test set single instance scope using scope setter
	unittest {
		Registration registration = new Registration(null, typeid(TestType));
		auto chainedRegistration = registration.singleInstance();
		auto instance1 = registration.getInstance();
		auto instance2 = registration.getInstance();
		assert(instance1 is instance2, "Registration with single instance scope did not return the same instance");
		assert(registration is chainedRegistration, "Registration returned by scope setting is not the same as the registration being set");
	}
}