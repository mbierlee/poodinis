/**
 * Contains the implementation of the dependency container.
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
import std.array;
import std.algorithm;

debug {
	import std.stdio;
}

public import poodinis.registration;
public import poodinis.autowire;

/**
 * Exception thrown when errors occur while registering a type in a dependency container.
 */
class RegistrationException : Exception {
	this(string message, TypeInfo registeredType, TypeInfo_Class concreteType) {
		super(format("Exception while registering type %s to %s: %s", registeredType.toString(), concreteType.name, message));
	}
}

/**
 * Exception thrown when errors occur while resolving a type in a dependency container.
 */
class ResolveException : Exception {
	this(string message, TypeInfo resolveType) {
		super(format("Exception while resolving type %s: %s", resolveType.toString(), message));
	}
}

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
class DependencyContainer {

	private static DependencyContainer instance;

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
	 * class Cat : Animal {}
	 *
	 * container.register!Cat;
	 *
	 * container.resolve!Cat;
	 * container.resolve!(Animal, Cat); // Error! dependency is not registered by super type.
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
	 * class Cat : Animal {}
	 *
	 * container.register!(Animal, Cat);
	 *
	 * container.resolve!(Animal, Cat);
	 * container.resolve!Cat; // Error! dependency is not registered by concrete type.
	 * ---
	 *
	 * See_Also: singleInstance, newInstance, existingInstance
	 */
	public Registration register(InterfaceType, ConcreteType : InterfaceType)() {
		TypeInfo registeredType = typeid(InterfaceType);
		TypeInfo_Class concreteType = typeid(ConcreteType);

		debug(poodinisVerbose) {
			writeln(format("DEBUG: Register type %s (as %s)", concreteType.toString(), registeredType.toString()));
		}

		auto existingCandidates = registeredType in registrations;
		if (existingCandidates) {
			auto existingRegistration = getRegistration(*existingCandidates, concreteType);
			if (existingRegistration) {
				return existingRegistration;
			}
		}

		AutowiredRegistration!ConcreteType newRegistration = new AutowiredRegistration!ConcreteType(registeredType, this);
		newRegistration.singleInstance();
		registrations[registeredType] ~= newRegistration;
		return newRegistration;
	}

	private Registration getRegistration(Registration[] candidates, TypeInfo concreteType) {
		foreach(existingRegistration ; candidates) {
			if (existingRegistration.instantiatableType == concreteType) {
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
	 * class Cat : Animal {}
	 * class Dog : Animal {}
	 *
	 * container.register!(Animal, Cat);
	 * container.register!Dog;
	 *
	 * container.resolve!Animal;
	 * container.resolve!Dog;
	 * ---
	 * You cannot resolve a dependency when it is registered by multiple super types:
	 * ---
	 * class Cat : Animal {}
	 * class Dog : Animal {}
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
	 * class Cat : Animal {}
	 * class Dog : Animal {}
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

		Registration registration = getQualifiedRegistration(resolveType, qualifierType, *candidates);
		QualifierType instance;

		if (!autowireStack.canFind(registration)) {
			autowireStack ~= registration;
			instance = cast(QualifierType) registration.getInstance(new AutowireInstantiationContext());
			autowireStack.popBack();
		} else {
			auto autowireContext = new AutowireInstantiationContext();
			autowireContext.autowireInstance = false;
			instance = cast(QualifierType) registration.getInstance(autowireContext);
		}

		return instance;
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
	 * Returns a global singleton instance of a dependency container.
	 */
	public static DependencyContainer getInstance() {
		if (instance is null) {
			instance = new DependencyContainer();
		}
		return instance;
	}
}
