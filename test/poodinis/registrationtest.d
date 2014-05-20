import poodinis.registration;

import std.exception;

version(unittest) {
	class TestType {
	}
	
	// Test getting instance without scope defined throws exception
	unittest {
		Registration registration = Registration();
		registration.registeredType = typeid(TestType);
		assertThrown!(NoScopeDefinedException)(registration.getInstance());
	}
	
	// Test getting instance from single instance scope
	unittest {
		Registration registration = Registration();
		registration.registeredType = typeid(TestType);
		registration.registationScope = new SingleInstanceScope(typeid(TestType));
		auto instance1 = registration.getInstance();
		auto instance2 = registration.getInstance();
		assert(instance1 is instance2, "Registration with single instance scope did not return the same instance");
	}
}