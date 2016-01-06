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
		Registration registration = new Registration(typeid(TestType), null);
		assertThrown!(InstanceCreationException)(registration.getInstance());
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

	// Test set new instance scope using scope setter
	unittest {
		Registration registration = new Registration(null, typeid(TestType));
		auto chainedRegistration = registration.newInstance();
		auto instance1 = registration.getInstance();
		auto instance2 = registration.getInstance();
		assert(instance1 !is instance2, "Registration with new instance scope did not return a different instance");
		assert(registration is chainedRegistration, "Registration returned by scope setting is not the same as the registration being set");
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

	// Test linking registrations
	unittest {
		Registration firstRegistration = new Registration(typeid(TestInterface), typeid(TestImplementation)).singleInstance();
		Registration secondRegistration = new Registration(typeid(TestImplementation), typeid(TestImplementation)).singleInstance().linkTo(firstRegistration);

		auto firstInstance = firstRegistration.getInstance();
		auto secondInstance = secondRegistration.getInstance();

		assert(firstInstance is secondInstance);
	}

	// Test instance factory with singletons
	unittest {
		auto factory = new InstanceFactory(typeid(TestImplementation), CreatesSingleton.yes, null);
		auto instanceOne = factory.getInstance();
		auto instanceTwo = factory.getInstance();

		assert(instanceOne !is null, "Created factory instance is null");
		assert(instanceOne is instanceTwo, "Created factory instance is not the same");
	}

	// Test instance factory with new instances
	unittest {
		auto factory = new InstanceFactory(typeid(TestImplementation), CreatesSingleton.no, null);
		auto instanceOne = factory.getInstance();
		auto instanceTwo = factory.getInstance();

		assert(instanceOne !is null, "Created factory instance is null");
		assert(instanceOne !is instanceTwo, "Created factory instance is the same");
	}

	// Test instance factory with existing instances
	unittest {
		auto existingInstance = new TestImplementation();
		auto factory = new InstanceFactory(typeid(TestImplementation), CreatesSingleton.yes, existingInstance);
		auto instanceOne = factory.getInstance();
		auto instanceTwo = factory.getInstance();

		assert(instanceOne is existingInstance, "Created factory instance is not the existing instance");
		assert(instanceTwo is existingInstance, "Created factory instance is not the existing instance when called again");
	}

	// Test instance factory with existing instances when setting singleton flag to "no"
	unittest {
		auto existingInstance = new TestImplementation();
		auto factory = new InstanceFactory(typeid(TestImplementation), CreatesSingleton.no, existingInstance);
		auto instance = factory.getInstance();

		assert(instance is existingInstance, "Created factory instance is not the existing instance");
	}

	// Test creating instance using custom factory method
	unittest {
		Object factoryMethod() {
			auto instance = new TestImplementation();
			instance.someContent = "Ducks!";
			return instance;
		}

		auto factory = new InstanceFactory(null, CreatesSingleton.yes, null, &factoryMethod);
		auto instance = cast(TestImplementation) factory.getInstance();

		assert(instance !is null, "No instance was created by factory or could not be cast to expected type");
		assert(instance.someContent == "Ducks!");
	}

}
