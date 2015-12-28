/**
 * Contains the implementation of the dependency container.
 *
 * Part of the Poodinis Dependency Injection framework.
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2015 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.container;

import std.string;
import std.algorithm;
import std.concurrency;

debug {
	import std.stdio;
}

import poodinis.registration;
import poodinis.autowire;
import poodinis.context;

/**
 * Exception thrown when errors occur while resolving a type in a dependency container.
 */
class ResolveException : Exception {
	this(string message, TypeInfo resolveType) {
		super(format("Exception while resolving type %s: %s", resolveType.toString(), message));
	}
}

/**
 * Exception thrown when errors occur while registering a type in a dependency container.
 */
class RegistrationException : Exception {
	this(string message, TypeInfo registrationType) {
		super(format("Exception while registering type %s: %s", registrationType.toString(), message));
	}
}

/**
 * Options which influence the process of registering dependencies
 */
public enum RegistrationOption {
	/**
	 * Prevent a concrete type being registered on itself. With this option you will always need
	 * to use the supertype as the type of the dependency.
	 */
	DO_NOT_ADD_CONCRETE_TYPE_REGISTRATION
}

/**
 * Deprecated: Use enum RegistrationOption instead
 */
alias RegistrationOptions = RegistrationOption;

/**
 * The dependency container maintains all dependencies registered with it.
 *
 * Dependencies registered by a container can be resolved as long as they are still registered with the container.
 * Upon resolving a dependency, an instance is fetched according to a specific scope which dictates how instances of
 * dependencies are created. Resolved dependencies will be autowired before being returned.
 *
 * In most cases you want to use a global singleton dependency container provided by getInstance() to manage all dependencies.
 * You can still create new instances of this class for exceptional situations.
 */
synchronized class DependencyContainer {
	private Registration[][TypeInfo] registrations;

	private Registration[] autowireStack;

	/**
	 * Register a dependency by concrete class type.
	 *
	 * A dependency registered by concrete class type can only be resolved by concrete class type.
	 * No qualifiers can be used when resolving dependencies which are registered by concrete type.
	 *
	 * The default registration scope is "single instance" scope.
	 *
	 * Returns:
	 * A registration is returned which can be used to change the registration scope.
	 *
	 * Examples:
	 * Register and resolve a class by concrete type:
	 * ---
	 * class Cat : Animal { ... }
	 * container.register!Cat;
	 * ---
	 *
	 * See_Also: singleInstance, newInstance, existingInstance
	 */
	public Registration register(ConcreteType)() {
		return register!(ConcreteType, ConcreteType)();
	}

	/**
	 * Register a dependency by super type.
	 *
	 * A dependency registered by super type can only be resolved by super type. A qualifier is typically
	 * used to resolve dependencies registered by super type.
	 *
	 * The default registration scope is "single instance" scope.
	 *
	 * Examples:
	 * Register and resolve by super type
	 * ---
	 * class Cat : Animal { ... }
	 * container.register!(Animal, Cat);
	 * ---
	 *
	 * See_Also: singleInstance, newInstance, existingInstance, RegistrationOptions
	 */
	public Registration register(SuperType, ConcreteType : SuperType, RegistrationOptionsTuple...)(RegistrationOptionsTuple options) {
		TypeInfo registeredType = typeid(SuperType);
		TypeInfo_Class concreteType = typeid(ConcreteType);

		debug(poodinisVerbose) {
			writeln(format("DEBUG: Register type %s (as %s)", concreteType.toString(), registeredType.toString()));
		}

		auto existingRegistration = getExistingRegistration(registeredType, concreteType);
		if (existingRegistration) {
			return existingRegistration;
		}

		auto newRegistration = new AutowiredRegistration!ConcreteType(registeredType, this);
		newRegistration.singleInstance();

		if (!hasOption(options, RegistrationOption.DO_NOT_ADD_CONCRETE_TYPE_REGISTRATION)) {
			static if (!is(SuperType == ConcreteType)) {
				auto concreteTypeRegistration = register!ConcreteType;
				concreteTypeRegistration.linkTo(newRegistration);
			}
		}

		registrations[registeredType] ~= cast(shared(Registration)) newRegistration;
		return newRegistration;
	}

	private bool hasOption(RegistrationOptionsTuple...)(RegistrationOptionsTuple options, RegistrationOption option) {
		foreach(presentOption ; options) {
			if (presentOption == option) {
				return true;
			}
		}

		return false;
	}

	private Registration getExistingRegistration(TypeInfo registrationType, TypeInfo qualifierType) {
		auto existingCandidates = registrationType in registrations;
		if (existingCandidates) {
			return getRegistration(cast(Registration[]) *existingCandidates, qualifierType);
		}

		return null;
	}

	private Registration getRegistration(Registration[] candidates, TypeInfo concreteType) {
		foreach(existingRegistration ; candidates) {
			if (existingRegistration.instanceType == concreteType) {
				return existingRegistration;
			}
		}

		return null;
	}

	/**
	 * Resolve dependencies.
	 *
	 * Dependencies can only resolved using this method if they are registered by concrete type or the only
	 * concrete type registered by super type.
	 *
	 * Resolved dependencies are automatically autowired before being returned.
	 *
	 * Returns:
	 * An instance is returned which is created according to the registration scope with which they are registered.
	 *
	 * Throws:
	 * ResolveException when type is not registered.
	 *
	 * Examples:
	 * Resolve dependencies registered by super type and concrete type:
	 * ---
	 * class Cat : Animal { ... }
	 * class Dog : Animal { ... }
	 *
	 * container.register!(Animal, Cat);
	 * container.register!Dog;
	 *
	 * container.resolve!Animal;
	 * container.resolve!Dog;
	 * ---
	 * You cannot resolve a dependency when it is registered by multiple super types:
	 * ---
	 * class Cat : Animal { ... }
	 * class Dog : Animal { ... }
	 *
	 * container.register!(Animal, Cat);
	 * container.register!(Animal, Dog);
	 *
	 * container.resolve!Animal; // Error: multiple candidates for type "Animal"
	 * container.resolve!Dog; // Error: No type is registered by concrete type "Dog", only by super type "Animal"
	 * ---
	 * You need to use the resolve method which allows you to specify a qualifier.
	 */
	public RegistrationType resolve(RegistrationType)() {
		return resolve!(RegistrationType, RegistrationType)();
	}

	/**
	 * Resolve dependencies using a qualifier.
	 *
	 * Dependencies can only resolved using this method if they are registered by super type.
	 *
	 * Resolved dependencies are automatically autowired before being returned.
	 *
	 * Returns:
	 * An instance is returned which is created according to the registration scope with which they are registered.
	 *
	 * Throws:
	 * ResolveException when type is not registered or there are multiple candidates available for type.
	 *
	 * Examples:
	 * Resolve dependencies registered by super type:
	 * ---
	 * class Cat : Animal { ... }
	 * class Dog : Animal { ... }
	 *
	 * container.register!(Animal, Cat);
	 * container.register!(Animal, Dog);
	 *
	 * container.resolve!(Animal, Cat);
	 * container.resolve!(Animal, Dog);
	 * ---
	 */
	public QualifierType resolve(RegistrationType, QualifierType : RegistrationType)() {
		TypeInfo resolveType = typeid(RegistrationType);
		TypeInfo qualifierType = typeid(QualifierType);

		debug(poodinisVerbose) {
			writeln("DEBUG: Resolving type " ~ resolveType.toString() ~ " with qualifier " ~ qualifierType.toString());
		}

		auto candidates = resolveType in registrations;
		if (!candidates) {
			throw new ResolveException("Type not registered.", resolveType);
		}

		Registration registration = getQualifiedRegistration(resolveType, qualifierType, cast(Registration[]) *candidates);
		return resolveAutowiredInstance!QualifierType(registration);
	}

	private QualifierType resolveAutowiredInstance(QualifierType)(Registration registration) {
		QualifierType instance;
		if (!(cast(Registration[]) autowireStack).canFind(registration)) {
			autowireStack ~= cast(shared(Registration)) registration;
			instance = cast(QualifierType) registration.getInstance(new AutowireInstantiationContext());
			autowireStack = autowireStack[0 .. $-1];
		} else {
			auto autowireContext = new AutowireInstantiationContext();
			autowireContext.autowireInstance = false;
			instance = cast(QualifierType) registration.getInstance(autowireContext);
		}
		return instance;
	}

	/**
	 * Resolve all dependencies registered to a super type.
	 *
	 * Returns:
	 * An array of autowired instances is returned. The order is undetermined.
	 *
	 * Examples:
	 * ---
	 * class Cat : Animal { ... }
	 * class Dog : Animal { ... }
	 *
	 * container.register!(Animal, Cat);
	 * container.register!(Animal, Dog);
	 *
	 * Animal[] animals = container.resolveAll!Animal;
	 * ---
	 */
	public RegistrationType[] resolveAll(RegistrationType)() {
		RegistrationType[] instances;
		TypeInfo resolveType = typeid(RegistrationType);

		auto qualifiedRegistrations = resolveType in registrations;
		if (!qualifiedRegistrations) {
			throw new ResolveException("Type not registered.", resolveType);
		}

		foreach(registration ; cast(Registration[]) *qualifiedRegistrations) {
			instances ~= resolveAutowiredInstance!RegistrationType(registration);
		}

		return instances;
	}

	private Registration getQualifiedRegistration(TypeInfo resolveType, TypeInfo qualifierType, Registration[] candidates) {
		if (resolveType == qualifierType) {
			if (candidates.length > 1) {
				string candidateList = candidates.toConcreteTypeListString();
				throw new ResolveException("Multiple qualified candidates available: " ~ candidateList ~ ". Please use a qualifier.", resolveType);
			}

			return candidates[0];
		}

		return getRegistration(candidates, qualifierType);
	}

	/**
	 * Clears all dependency registrations managed by this container.
	 */
	public void clearAllRegistrations() {
		registrations.destroy();
	}

	/**
	 * Removes a registered dependency by type.
	 *
	 * A dependency can be removed either by super type or concrete type, depending on how they are registered.
	 *
	 * Examples:
	 * ---
	 * container.removeRegistration!Animal;
	 * ---
	 */
	public void removeRegistration(RegistrationType)() {
		registrations.remove(typeid(RegistrationType));
	}

	/**
	* Register dependencies through an application context.
	*
	* An application context allows you to fine-tune dependency set-up and instantiation.
	* It is mostly used for dependencies which come from an external library or when you don't
	* want to use annotations to set-up dependencies in your classes.
	*/
	public void registerContext(Context : ApplicationContext)() {
		auto context = new Context();
		context.registerDependencies(this);
		context.registerContextComponents(this);
		this.register!(ApplicationContext, Context)().existingInstance(context);
		autowire(this, context);
	}

	/**
	 * Returns a global singleton instance of a dependency container.
	 */
	public static shared(DependencyContainer) getInstance() {
		static shared DependencyContainer instance;
		if (instance is null) {
			instance = new DependencyContainer();
		}
		return instance;
	}
}
