/**
 * This module contains objects for defining and scoping dependency registrations.
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

module poodinis.registration;

import std.typecons;
import std.exception;

debug {
	import std.stdio;
	import std.string;
}

class InstanceCreationException : Exception {
	this(string message, string file = __FILE__, size_t line = __LINE__) {
		super(message, file, line);
	}
}

class Registration {
	private TypeInfo _registeredType = null;
	private TypeInfo_Class _instantiatableType = null;
	private Registration linkedRegistration;

	public @property registeredType() {
		return _registeredType;
	}

	public @property instantiatableType() {
		return _instantiatableType;
	}

	public InstanceFactory instanceFactory = null;

	this(TypeInfo registeredType, TypeInfo_Class instantiatableType) {
		this._registeredType = registeredType;
		this._instantiatableType = instantiatableType;
	}

	public Object getInstance(InstantiationContext context = new InstantiationContext()) {
		if (linkedRegistration !is null) {
			return linkedRegistration.getInstance(context);
		}


		if (instanceFactory is null) {
			throw new InstanceCreationException("No instance factory defined for registration of type " ~ registeredType.toString());
		}

		return instanceFactory.getInstance();
	}

	public Registration linkTo(Registration registration) {
		this.linkedRegistration = registration;
		return this;
	}
}

alias CreatesSingleton = Flag!"CreatesSingleton";

class InstanceFactory {
	private TypeInfo_Class instanceType = null;
	private Object instance = null;
	private CreatesSingleton createsSingleton;

	this(TypeInfo_Class instanceType, CreatesSingleton createsSingleton = CreatesSingleton.yes, Object existingInstance = null) {
		this.instanceType = instanceType;
		this.createsSingleton = existingInstance !is null ? CreatesSingleton.yes : createsSingleton;
		this.instance = existingInstance;
	}

	public Object getInstance() {
		if (createsSingleton && instance !is null) {
			debug(poodinisVerbose) {
				writeln(format("DEBUG: Existing instance returned of type %s", instanceType.toString()));
			}

			return instance;
		}

		enforce!InstanceCreationException(instanceType, "Instance type is not defined, cannot create instance without knowing its type.");
		debug(poodinisVerbose) {
			writeln(format("DEBUG: Creating new instance of type %s", instanceType.toString()));
		}

		instance = instanceType.create();
		return instance;
	}
}

/**
 * Scopes registrations to return the same instance every time a given registration is resolved.
 *
 * Effectively makes the given registration a singleton.
 */
public Registration singleInstance(Registration registration) {
	registration.instanceFactory = new InstanceFactory(registration.instantiatableType, CreatesSingleton.yes, null);
	return registration;
}

/**
 * Scopes registrations to return a new instance every time the given registration is resolved.
 */
public Registration newInstance(Registration registration) {
	registration.instanceFactory = new InstanceFactory(registration.instantiatableType, CreatesSingleton.no, null);
	return registration;
}

/**
 * Scopes registrations to return the given instance every time the given registration is resolved.
 */
public Registration existingInstance(Registration registration, Object instance) {
	registration.instanceFactory = new InstanceFactory(registration.instantiatableType, CreatesSingleton.yes, instance);
	return registration;
}

public string toConcreteTypeListString(Registration[] registrations) {
	auto concreteTypeListString = "";
	foreach (registration ; registrations) {
		if (concreteTypeListString.length > 0) {
			concreteTypeListString ~= ", ";
		}
		concreteTypeListString ~= registration.instantiatableType.toString();
	}
	return concreteTypeListString;
}

class InstantiationContext {}
