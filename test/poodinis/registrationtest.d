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
}