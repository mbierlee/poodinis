/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2015 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

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

	// Test getting instance from new instance scope
	unittest {
		Registration registration = new Registration(null, null);
		registration.registationScope = new NewInstanceScope(typeid(TestType));
		auto instance1 = registration.getInstance();
		auto instance2 = registration.getInstance();
		assert(instance1 !is instance2, "Registration with new instance scope did not return a different instance");
	}

	// Test set new instance scope using scope setter
	unittest {
		Registration registration = new Registration(null, typeid(TestType));
		auto chainedRegistration = registration.newInstance();
		auto instance1 = registration.getInstance();
		auto instance2 = registration.getInstance();
		assert(instance1 !is instance2, "Registration with new instance scope did not return a different instance");
		assert(registration is chainedRegistration, "Registration returned by scope setting is not the same as the registration being set");
	}

	// Test getting instance from existing instance scope
	unittest {
		Registration registration = new Registration(null, null);
		TestType expectedInstance = new TestType();
		registration.registationScope = new ExistingInstanceScope(expectedInstance);
		auto actualInstance = registration.getInstance();
		assert(expectedInstance is actualInstance, "Registration with existing instance did not return given instance");
	}

	// Test set existing instance scope using scope setter
	unittest {
		Registration registration = new Registration(null, null);
		auto expectedInstance = new TestType();
		auto chainedRegistration = registration.existingInstance(expectedInstance);
		auto actualInstance = registration.getInstance();
		assert(expectedInstance is expectedInstance, "Registration with existing instance scope did not return the same instance");
		assert(registration is chainedRegistration, "Registration returned by scope setting is not the same as the registration being set");
	}

}
