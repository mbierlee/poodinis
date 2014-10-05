/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.container;

import std.string;
import std.array;
import std.algorithm;

public import poodinis.registration;
public import poodinis.autowire;

class RegistrationException : Exception {
	this(string message, TypeInfo registeredType, TypeInfo_Class instantiatableType) {
		super(format("Exception while registering type %s to %s: %s", registeredType.toString(), instantiatableType.name, message));
	}
}

class ResolveException : Exception {
	this(string message, TypeInfo resolveType) {
		super(format("Exception while resolving type %s: %s", resolveType.toString(), message));
	}
}

class Container {

	private static Container instance;
	
	private Registration[TypeInfo] registrations;
	
	private Registration*[] autowireStack;
	
	public Registration register(ConcreteType)() {
		return register!(ConcreteType, ConcreteType)();
	}
	
	public Registration register(InterfaceType, ConcreteType : InterfaceType)() {
		TypeInfo registeredType = typeid(InterfaceType);
		TypeInfo_Class instantiatableType = typeid(ConcreteType);
		
		Registration newRegistration = new Registration(registeredType, instantiatableType);
		newRegistration.singleInstance();
		registrations[registeredType] = newRegistration;
		return newRegistration;
	}
	
	public RegistrationType resolve(RegistrationType)() {
		TypeInfo resolveType = typeid(RegistrationType);
		Registration* registration = resolveType in registrations;
		if (!registration) {
			throw new ResolveException("Type not registered.", resolveType);
		}
		
		RegistrationType instance = cast(RegistrationType) registration.getInstance();
		
		if (!autowireStack.canFind(registration)) {
			autowireStack ~= registration;
			this.autowire!(RegistrationType)(instance);
			autowireStack.popBack();
		}
		
		return instance;
	}
	
	public void clearAllRegistrations() {
		registrations = null;
	}
	
	public void removeRegistration(RegistrationType)() {
		registrations.remove(typeid(RegistrationType));
	}
	
	public static Container getInstance() {
		if (instance is null) {
			instance = new Container();
		}
		return instance;
	}
}
