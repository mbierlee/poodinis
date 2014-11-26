/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.dependency;

import std.string;
import std.array;
import std.algorithm;

debug {
	import std.stdio;
}

public import poodinis.registration;
public import poodinis.autowire;

class RegistrationException : Exception {
	this(string message, TypeInfo registeredType, TypeInfo_Class concreteType) {
		super(format("Exception while registering type %s to %s: %s", registeredType.toString(), concreteType.name, message));
	}
}

class ResolveException : Exception {
	this(string message, TypeInfo resolveType) {
		super(format("Exception while resolving type %s: %s", resolveType.toString(), message));
	}
}

deprecated("Container has been renamed to DependencyContainer")
alias Container = DependencyContainer;

class DependencyContainer {

	private static DependencyContainer instance;
	
	private Registration[][TypeInfo] registrations;
	
	private Registration[] autowireStack;
	
	public Registration register(ConcreteType)() {
		return register!(ConcreteType, ConcreteType)();
	}
	
	public Registration register(InterfaceType, ConcreteType : InterfaceType)() {
		TypeInfo registeredType = typeid(InterfaceType);
		TypeInfo_Class concreteType = typeid(ConcreteType);
		
		debug {
			writeln(format("DEBUG: Register type %s (as %s)", concreteType.toString(), registeredType.toString()));
		}
		
		Registration newRegistration = new Registration(registeredType, concreteType);
		newRegistration.singleInstance();
		registrations[registeredType] ~= newRegistration;
		return newRegistration;
	}
	
	public RegistrationType resolve(RegistrationType)() {
		TypeInfo resolveType = typeid(RegistrationType);
		debug {
			writeln("DEBUG: Resolving type " ~ resolveType.toString());
		}
		
		auto candidates = resolveType in registrations;
		if (!candidates) {
			throw new ResolveException("Type not registered.", resolveType);
		}
		
		auto registration = (*candidates)[0];
		
		RegistrationType instance = cast(RegistrationType) registration.getInstance();
		
		if (!autowireStack.canFind(registration)) {
			autowireStack ~= registration;
			this.autowire!(RegistrationType)(instance);
			autowireStack.popBack();
		}
		
		return instance;
	}
	
	public void clearAllRegistrations() {
		registrations.destroy();
	}
	
	public void removeRegistration(RegistrationType)() {
		registrations.remove(typeid(RegistrationType));
	}
	
	public static DependencyContainer getInstance() {
		if (instance is null) {
			instance = new DependencyContainer();
		}
		return instance;
	}
}
