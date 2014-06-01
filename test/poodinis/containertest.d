/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

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
	
	class AutowiredClass {
	}
	
	class ComponentClass {
		@Autowire
		public AutowiredClass autowiredClass;
	}
	
	class ComponentCat {
		@Autowire
		public ComponentMouse mouse;
	}
	
	class ComponentMouse {
		@Autowire
		public ComponentMouse cat;
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
	
	// Test resolve non-registered type
	unittest {
		auto container = new Container();
		assertThrown!ResolveException(container.resolve!(TestClass)(), "Resolving non-registered type does not fail");
	}
	
	// Test clear registrations
	unittest {
		auto container = new Container();
		container.register!(TestClass)();
		container.clearAllRegistrations();
		assertThrown!ResolveException(container.resolve!(TestClass)(), "Resolving cleared type does not fail");
	}
	
	// Test get singleton of container
	unittest {
		auto instance1 = Container.getInstance();
		auto instance2 = Container.getInstance();
		assert(instance1 is instance2, "getInstance does not return the same instance");
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
	
	// Test autowire resolved instances
	unittest {
		auto container = new Container();
		container.register!AutowiredClass;
		container.register!ComponentClass;
		auto componentInstance = container.resolve!ComponentClass;
		auto autowiredInstance = container.resolve!AutowiredClass;
		assert(componentInstance.autowiredClass is autowiredInstance, "Member is not autowired upon resolving");
	}

	// Test circular autowiring
	unittest {
		auto container = new Container();
		container.register!ComponentMouse;
		container.register!ComponentCat;
		auto mouse = container.resolve!ComponentMouse;
		auto cat = container.resolve!ComponentCat;
		assert(mouse.cat is cat && cat.mouse is mouse, "Circular dependencies should be autowirable");
	}
	
	// Test remove registration
	unittest {
		auto container = new Container();
		container.register!TestClass;
		container.removeRegistration!TestClass;
		assertThrown!ResolveException(container.resolve!TestClass);
	}
}