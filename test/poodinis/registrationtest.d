/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2016 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.exception;

version(unittest) {
	class TestType {}

	interface TestInterface {}

	class TestImplementation : TestInterface {
		public string someContent = "";
	}

	// Test getting instance without scope defined throws exception
	unittest {
		Registration registration = new Registration(typeid(TestType), null, null);
		assertThrown!(InstanceCreationException)(registration.getInstance(), null);
	}

	// Test set single instance scope using scope setter
	unittest {
		Registration registration = new Registration(null, typeid(TestType), null);
		auto chainedRegistration = registration.singleInstance();
		auto instance1 = registration.getInstance();
		auto instance2 = registration.getInstance();
		assert(instance1 is instance2, "Registration with single instance scope did not return the same instance");
		assert(registration is chainedRegistration, "Registration returned by scope setting is not the same as the registration being set");
	}

	// Test set new instance scope using scope setter
	unittest {
		Registration registration = new Registration(null, typeid(TestType), null);
		auto chainedRegistration = registration.newInstance();
		auto instance1 = registration.getInstance();
		auto instance2 = registration.getInstance();
		assert(instance1 !is instance2, "Registration with new instance scope did not return a different instance");
		assert(registration is chainedRegistration, "Registration returned by scope setting is not the same as the registration being set");
	}

	// Test set existing instance scope using scope setter
	unittest {
		Registration registration = new Registration(null, null, null);
		auto expectedInstance = new TestType();
		auto chainedRegistration = registration.existingInstance(expectedInstance);
		auto actualInstance = registration.getInstance();
		assert(expectedInstance is expectedInstance, "Registration with existing instance scope did not return the same instance");
		assert(registration is chainedRegistration, "Registration returned by scope setting is not the same as the registration being set");
	}

	// Test linking registrations
	unittest {
		Registration firstRegistration = new Registration(typeid(TestInterface), typeid(TestImplementation), null).singleInstance();
		Registration secondRegistration = new Registration(typeid(TestImplementation), typeid(TestImplementation), null).singleInstance().linkTo(firstRegistration);

		auto firstInstance = firstRegistration.getInstance();
		auto secondInstance = secondRegistration.getInstance();

		assert(firstInstance is secondInstance);
	}

}
