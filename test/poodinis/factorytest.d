/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2016 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

version(unittest) {

	interface TestInterface {}

	class TestImplementation : TestInterface {
		public string someContent = "";
	}

	// Test instance factory with singletons
	unittest {
		auto factory = new InstanceFactory();
		factory.factoryParameters = InstanceFactoryParameters(typeid(TestImplementation), CreatesSingleton.yes);
		auto instanceOne = factory.getInstance();
		auto instanceTwo = factory.getInstance();

		assert(instanceOne !is null, "Created factory instance is null");
		assert(instanceOne is instanceTwo, "Created factory instance is not the same");
	}

	// Test instance factory with new instances
	unittest {
		auto factory = new InstanceFactory();
		factory.factoryParameters = InstanceFactoryParameters(typeid(TestImplementation), CreatesSingleton.no);
		auto instanceOne = factory.getInstance();
		auto instanceTwo = factory.getInstance();

		assert(instanceOne !is null, "Created factory instance is null");
		assert(instanceOne !is instanceTwo, "Created factory instance is the same");
	}

	// Test instance factory with existing instances
	unittest {
		auto existingInstance = new TestImplementation();
		auto factory = new InstanceFactory();
		factory.factoryParameters = InstanceFactoryParameters(typeid(TestImplementation), CreatesSingleton.yes, existingInstance);
		auto instanceOne = factory.getInstance();
		auto instanceTwo = factory.getInstance();

		assert(instanceOne is existingInstance, "Created factory instance is not the existing instance");
		assert(instanceTwo is existingInstance, "Created factory instance is not the existing instance when called again");
	}

	// Test instance factory with existing instances when setting singleton flag to "no"
	unittest {
		auto existingInstance = new TestImplementation();
		auto factory = new InstanceFactory();
		factory.factoryParameters = InstanceFactoryParameters(typeid(TestImplementation), CreatesSingleton.no, existingInstance);
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

		auto factory = new InstanceFactory();
		factory.factoryParameters = InstanceFactoryParameters(null, CreatesSingleton.yes, null, &factoryMethod);
		auto instance = cast(TestImplementation) factory.getInstance();

		assert(instance !is null, "No instance was created by factory or could not be cast to expected type");
		assert(instance.someContent == "Ducks!");
	}
}
