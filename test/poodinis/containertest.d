/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2015 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis.container;

import std.exception;
import core.thread;

version(unittest) {
	interface TestInterface {
	}

	class TestClass : TestInterface {
	}

	class TestClassDeux : TestInterface {
		@Autowire
		public UnrelatedClass unrelated;
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
		public ComponentCat cat;
	}

	class Eenie {
		@Autowire
		public Meenie meenie;
	}

	class Meenie {
		@Autowire
		public Moe moe;
	}

	class Moe {
		@Autowire
		public Eenie eenie;
	}

	class Ittie {
		@Autowire
		public Bittie bittie;
	}

	class Bittie {
		@Autowire
		public Banana banana;
	}

	class Banana {
		@Autowire
		public Bittie bittie;
	}

	interface SuperInterface {
	}

	class SuperImplementation : SuperInterface {
		@Autowire
		public Banana banana;
	}

	interface Color {
	}

	class Blue : Color {
	}

	class Red : Color {
	}

	class Spiders {
		@Autowire
		public TestInterface testMember;
	}

	class Recursive {
		@Autowire
		public Recursive recursive;
	}

	class Moolah {}

	class Wants {
		@Autowire
		public Moolah moolah;
	}

	class John {
		@Autowire
		public Wants wants;
	}

	// Test register concrete type
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		auto registration = container.register!(TestClass)();
		assert(registration.registeredType == typeid(TestClass), "Type of registered type not the same");
	}

	// Test resolve registered type
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(TestClass)();
		TestClass actualInstance = container.resolve!(TestClass)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestClass) actualInstance, "Resolved class is not the same type as expected");
	}

	// Test register interface
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(TestInterface, TestClass)();
		TestInterface actualInstance = container.resolve!(TestInterface)();
		assert(actualInstance !is null, "Resolved type is null");
		assert(cast(TestInterface) actualInstance, "Resolved class is not the same type as expected");
	}

	// Test resolve non-registered type
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		assertThrown!ResolveException(container.resolve!(TestClass)(), "Resolving non-registered type does not fail");
	}

	// Test clear registrations
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(TestClass)();
		container.clearAllRegistrations();
		assertThrown!ResolveException(container.resolve!(TestClass)(), "Resolving cleared type does not fail");
	}

	// Test get singleton of container
	unittest {
		auto instance1 = DependencyContainer.getInstance();
		auto instance2 = DependencyContainer.getInstance();
		assert(instance1 is instance2, "getInstance does not return the same instance");
	}

	// Test resolve single instance for type
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(TestClass)().singleInstance();
		auto instance1 = container.resolve!(TestClass);
		auto instance2 = container.resolve!(TestClass);
		assert(instance1 is instance2, "Resolved instance from single instance scope is not the each time it is resolved");
	}

	// Test resolve new instance for type
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(TestClass)().newInstance();
		auto instance1 = container.resolve!(TestClass);
		auto instance2 = container.resolve!(TestClass);
		assert(instance1 !is instance2, "Resolved instance from new instance scope is the same each time it is resolved");
	}

	// Test resolve existing instance for type
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		auto expectedInstance = new TestClass();
		container.register!(TestClass)().existingInstance(expectedInstance);
		auto actualInstance = container.resolve!(TestClass);
		assert(expectedInstance is actualInstance, "Resolved instance from existing instance scope is not the same as the registered instance");
	}

	// Test autowire resolved instances
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!AutowiredClass;
		container.register!ComponentClass;
		auto componentInstance = container.resolve!ComponentClass;
		auto autowiredInstance = container.resolve!AutowiredClass;
		assert(componentInstance.autowiredClass is autowiredInstance, "Member is not autowired upon resolving");
	}

	// Test circular autowiring
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!ComponentMouse;
		container.register!ComponentCat;
		auto mouse = container.resolve!ComponentMouse;
		auto cat = container.resolve!ComponentCat;
		assert(mouse.cat is cat && cat.mouse is mouse && mouse !is cat, "Circular dependencies should be autowirable");
	}

	// Test remove registration
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!TestClass;
		container.removeRegistration!TestClass;
		assertThrown!ResolveException(container.resolve!TestClass);
	}

	// Test autowiring does not autowire member where instance is non-null
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		auto existingA = new AutowiredClass();
		auto existingB = new ComponentClass();
		existingB.autowiredClass = existingA;

		container.register!AutowiredClass;
		container.register!(ComponentClass).existingInstance(existingB);
		auto resolvedA = container.resolve!AutowiredClass;
		auto resolvedB = container.resolve!ComponentClass;

		assert(resolvedB.autowiredClass is existingA && resolvedA !is existingA, "Autowiring shouldn't rewire member when it is already wired to an instance");
	}

	// Test autowiring circular dependency by third-degree
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!Eenie;
		container.register!Meenie;
		container.register!Moe;

		auto eenie = container.resolve!Eenie;

		assert(eenie.meenie.moe.eenie is eenie, "Autowiring third-degree circular dependency failed");
	}

	// Test autowiring deep circular dependencies
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!Ittie;
		container.register!Bittie;
		container.register!Banana;

		auto ittie = container.resolve!Ittie;

		assert(ittie.bittie is ittie.bittie.banana.bittie, "Autowiring deep dependencies failed.");
	}

	// Test autowiring deep circular dependencies with newInstance scope does not autowire new instance second time
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(Ittie).newInstance();
		container.register!(Bittie).newInstance();
		container.register!(Banana).newInstance();

		auto ittie = container.resolve!Ittie;

		assert(ittie.bittie.banana.bittie.banana is null, "Autowiring deep dependencies with newInstance scope autowired a reoccuring type.");
	}

	// Test autowiring type registered by interface
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!Banana;
		container.register!Bittie;
		container.register!(SuperInterface, SuperImplementation);

		SuperImplementation superInstance = cast(SuperImplementation) container.resolve!SuperInterface;

		assert(!(superInstance.banana is null), "Instance which was resolved by interface type was not autowired.");
	}

	// Test reusing a container after clearing all registrations
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!Banana;
		container.clearAllRegistrations();
		try {
			container.resolve!Banana;
		} catch (ResolveException e) {
			container.register!Banana;
			return;
		}
		assert(false);
	}

	// Test register multiple concrete classess to same interface type
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(Color, Blue);
		container.register!(Color, Red);
	}

	// Test removing all registrations for type with multiple registrations.
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(Color, Blue);
		container.register!(Color, Red);
		container.removeRegistration!Color;
	}

	// Test registering same registration again
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		auto firstRegistration = container.register!(Color, Blue);
		auto secondRegistration = container.register!(Color, Blue);

		assert(firstRegistration is secondRegistration, "First registration is not the same as the second of equal types");
	}

	// Test resolve registration with multiple qualifiers
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(Color, Blue);
		container.register!(Color, Red);
		try {
			container.resolve!Color;
		} catch (ResolveException e) {
			return;
		}
		assert(false);
	}

	// Test resolve registration with multiple qualifiers using a qualifier
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(Color, Blue);
		container.register!(Color, Red);
		auto blueInstance = container.resolve!(Color, Blue);
		auto redInstance = container.resolve!(Color, Red);

		assert(blueInstance !is redInstance, "Resolving type with multiple, different registrations yielded the same instance");
		assert(blueInstance !is null, "Resolved blue instance to null");
		assert(redInstance !is null, "Resolved red instance to null");
	}

	// Test autowire of unqualified member typed by interface.
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!Spiders;
		container.register!(TestInterface, TestClass);

		auto instance = container.resolve!Spiders;

		assert(!(instance is null), "Container failed to autowire member by interface");
	}

	// Register existing registration
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();

		auto firstRegistration = container.register!TestClass;
		auto secondRegistration = container.register!TestClass;

		assert(firstRegistration is secondRegistration, "Registering the same registration twice registers the dependencies twice.");
	}

	// Register existing registration by supertype
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();

		auto firstRegistration = container.register!(TestInterface, TestClass);
		auto secondRegistration = container.register!(TestInterface, TestClass);

		assert(firstRegistration is secondRegistration, "Registering the same registration by super type twice registers the dependencies twice.");
	}

	// Resolve dependency depending on itself
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!Recursive;

		auto instance = container.resolve!Recursive;

		assert(instance.recursive is instance, "Resolving dependency that depends on itself fails.");
		assert(instance.recursive.recursive is instance, "Resolving dependency that depends on itself fails.");
	}

	// Test autowire stack pop-back
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!Moolah;
		container.register!Wants.newInstance();
		container.register!John;

		container.resolve!Wants;
		auto john = container.resolve!John;

		assert(john.wants.moolah !is null, "Autowire stack did not clear entries properly");
	}

	// Test resolving registration registered in different thread
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();

		auto thread = new Thread(delegate() {
				container.register!TestClass;
		});
		thread.start();
		thread.join();

		container.resolve!TestClass;
	}

	// Test resolving instance previously resolved in different thread
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		shared(TestClass) actualTestClass;

		container.register!TestClass;

		auto thread = new Thread(delegate() {
				actualTestClass = cast(shared(TestClass)) container.resolve!TestClass;
		});
		thread.start();
		thread.join();

		shared(TestClass) expectedTestClass = cast(shared(TestClass)) container.resolve!TestClass;

		assert(expectedTestClass is actualTestClass, "Instance resolved in main thread is not the one resolved in thread");
	}

	// Test registering type with option ADD_CONCRETE_TYPE_REGISTRATION
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(TestInterface, TestClass)(RegistrationOptions.ADD_CONCRETE_TYPE_REGISTRATION);

		auto firstInstance = container.resolve!TestInterface;
		auto secondInstance = container.resolve!TestClass;

		assert(firstInstance is secondInstance);
	}

	// Test registering type with option DO_NOT_ADD_CONCRETE_TYPE_REGISTRATION
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(TestInterface, TestClass)(RegistrationOptions.DO_NOT_ADD_CONCRETE_TYPE_REGISTRATION);

		auto firstInstance = container.resolve!TestInterface;
		assertThrown!ResolveException(container.resolve!TestClass);
	}

	// Test registering type will register by contrete type by default
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(TestInterface, TestClass);

		auto firstInstance = container.resolve!TestInterface;
		auto secondInstance = container.resolve!TestClass;

		assert(firstInstance is secondInstance);
	}

	// Test resolving all registrations to an interface
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!(Color, Blue);
		container.register!(Color, Red);

		auto colors = container.resolveAll!Color;

		assert(colors.length == 2, "resolveAll did not yield all instances of interface type");
	}

	// Test autowiring instances resolved in array
	unittest {
		shared(DependencyContainer) container = new DependencyContainer();
		container.register!UnrelatedClass;
		container.register!(TestInterface, TestClassDeux);

		auto instances = container.resolveAll!TestInterface;
		auto instance = cast(TestClassDeux) instances[0];

		assert(instance.unrelated !is null);
	}
}
