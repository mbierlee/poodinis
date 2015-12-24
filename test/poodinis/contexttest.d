/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2015 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.exception;

version(unittest) {

	class Banana {
		public string color;

		this(string color) {
			this.color = color;
		}
	}

	class Apple {}

	class TestContext : ApplicationContext {

		@Component
		public Banana banana() {
			return new Banana("Yellow");
		}

		public Apple apple() {
			return new Apple();
		}
	}

	//Test register component registrations from context
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		auto context = new TestContext();
		context.registerContextComponents(container);
		auto bananaInstance = container.resolve!Banana;

		assert(bananaInstance.color == "Yellow");
	}

	//Test non-annotated methods are not registered
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		auto context = new TestContext();
		context.registerContextComponents(container);
		assertThrown!ResolveException(container.resolve!Apple);
	}

}
