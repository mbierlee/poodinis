/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2016 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.exception;

version(unittest) {

	interface Fruit {
		string getShape();
	}

	interface Animal {
		string getYell();
	}

	class Banana {
		public string color;

		this(string color) {
			this.color = color;
		}
	}

	class Apple {}

	class Pear : Fruit {
		public override string getShape() {
			return "Pear shaped";
		}
	}

	class Rabbit : Animal {
		public override string getYell() {
			return "Squeeeeeel";
		}
	}

	class Wolf : Animal {
		public override string getYell() {
			return "Wooooooooooo";
		}
	}

	class PieChart {}

	class TestContext : ApplicationContext {

		@Component
		public Banana banana() {
			return new Banana("Yellow");
		}

		public Apple apple() {
			return new Apple();
		}

		@Component
		@RegisterByType!Fruit
		public Pear pear() {
			return new Pear();
		}

		@Component
		@RegisterByType!Animal
		public Rabbit rabbit() {
			return new Rabbit();
		}

		@Component
		@RegisterByType!Animal
		public Wolf wolf() {
			return new Wolf();
		}

		@Component
		@Prototype
		public PieChart pieChart() {
			return new PieChart();
		}
	}

	//Test register component registrations from context
	unittest {
		auto container = new shared DependencyContainer();
		auto context = new TestContext();
		context.registerContextComponents(container);
		auto bananaInstance = container.resolve!Banana;

		assert(bananaInstance.color == "Yellow");
	}

	//Test non-annotated methods are not registered
	unittest {
		auto container = new shared DependencyContainer();
		auto context = new TestContext();
		context.registerContextComponents(container);
		assertThrown!ResolveException(container.resolve!Apple);
	}

	//Test register component by base type
	unittest {
		auto container = new shared DependencyContainer();
		auto context = new TestContext();
		context.registerContextComponents(container);
		auto instance = container.resolve!Fruit;
		assert(instance.getShape() == "Pear shaped");
	}

	//Test register components with multiple candidates
	unittest {
		auto container = new shared DependencyContainer();
		auto context = new TestContext();
		context.registerContextComponents(container);

		auto rabbit = container.resolve!(Animal, Rabbit);
		assert(rabbit.getYell() == "Squeeeeeel");

		auto wolf = container.resolve!(Animal, Wolf);
		assert(wolf.getYell() == "Wooooooooooo");
	}

	//Test register component as prototype
	unittest {
		auto container = new shared DependencyContainer();
		auto context = new TestContext();
		context.registerContextComponents(container);

		auto firstInstance = container.resolve!PieChart;
		auto secondInstance = container.resolve!PieChart;

		assert(firstInstance !is null && secondInstance !is null);
		assert(firstInstance !is secondInstance);
	}

}
