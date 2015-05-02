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

debug {
	import std.stdio;
	import std.string;
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

	public CreationScope registationScope = null;

	this(TypeInfo registeredType, TypeInfo_Class instantiatableType) {
		this._registeredType = registeredType;
		this._instantiatableType = instantiatableType;
	}

	public Object getInstance(InstantiationContext context = new InstantiationContext()) {
		if (linkedRegistration !is null) {
			return linkedRegistration.getInstance(context);
		}


		if (registationScope is null) {
			throw new NoScopeDefinedException(registeredType);
		}

		return registationScope.getInstance();
	}

	public Registration linkTo(Registration registration) {
		this.linkedRegistration = registration;
		return this;
	}
}

class NoScopeDefinedException : Exception {
	this(TypeInfo type) {
		super("No scope defined for registration of type " ~ type.toString());
	}
}

interface CreationScope {
	public Object getInstance();
}

class NullScope : CreationScope {
	public Object getInstance() {
		debug(poodinisVerbose) {
			writeln("DEBUG: No instance created (NullScope)");
		}
		return null;
	}
}

class SingleInstanceScope : CreationScope {
	TypeInfo_Class instantiatableType = null;
	Object instance = null;

	this(TypeInfo_Class instantiatableType) {
		this.instantiatableType = instantiatableType;
	}

	public Object getInstance() {
		if (instance is null) {
			debug(poodinisVerbose) {
				writeln(format("DEBUG: Creating new instance of type %s (SingleInstanceScope)", instantiatableType.toString()));
			}
			instance = instantiatableType.create();
		} else {
			debug(poodinisVerbose) {
				writeln(format("DEBUG: Existing instance returned of type %s (SingleInstanceScope)", instantiatableType.toString()));
			}
		}


		return instance;
	}
}

/**
 * Scopes registrations to return the same instance every time a given registration is resolved.
 *
 * Effectively makes the given registration a singleton.
 */
public Registration singleInstance(Registration registration) {
	registration.registationScope = new SingleInstanceScope(registration.instantiatableType);
	return registration;
}

class NewInstanceScope : CreationScope {
	TypeInfo_Class instantiatableType = null;

	this(TypeInfo_Class instantiatableType) {
		this.instantiatableType = instantiatableType;
	}

	public Object getInstance() {
		debug(poodinisVerbose) {
			writeln(format("DEBUG: Creating new instance of type %s (SingleInstanceScope)", instantiatableType.toString()));
		}
		return instantiatableType.create();
	}
}

/**
 * Scopes registrations to return a new instance every time the given registration is resolved.
 */
public Registration newInstance(Registration registration) {
	registration.registationScope = new NewInstanceScope(registration.instantiatableType);
	return registration;
}

class ExistingInstanceScope : CreationScope {
	Object instance = null;

	this(Object instance) {
		this.instance = instance;
	}

	public Object getInstance() {
		debug(poodinisVerbose) {
			writeln("DEBUG: Existing instance returned (ExistingInstanceScope)");
		}
		return instance;
	}
}

/**
 * Scopes registrations to return the given instance every time the given registration is resolved.
 */
public Registration existingInstance(Registration registration, Object instance) {
	registration.registationScope = new ExistingInstanceScope(instance);
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
