/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.registration;

debug {
	import std.stdio;
	import std.string;
}

class Registration {
	TypeInfo registeredType = null;
	TypeInfo_Class instantiatableType = null;
	CreationScope registationScope = null;
	
	this(TypeInfo registeredType, TypeInfo_Class instantiatableType) {
		this.registeredType = registeredType;
		this.instantiatableType = instantiatableType;
	}
	
	public Object getInstance() {
		if (registationScope is null) {
			throw new NoScopeDefinedException(registeredType);
		}
		
		return registationScope.getInstance();
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
		debug {
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
			debug {
				writeln(format("DEBUG: Creating new instance of type %s (SingleInstanceScope)", instantiatableType.toString()));
			}
			instance = instantiatableType.create();
		} else {
			debug {
				writeln(format("DEBUG: Existing instance returned of type %s (SingleInstanceScope)", instantiatableType.toString()));
			}
		}
		
		
		return instance;
	}
}

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
		debug {
			writeln(format("DEBUG: Creating new instance of type %s (SingleInstanceScope)", instantiatableType.toString()));
		}
		return instantiatableType.create();
	}
}

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
		debug {
			writeln("DEBUG: Existing instance returned (ExistingInstanceScope)");
		}
		return instance;
	}
}

public Registration existingInstance(Registration registration, Object instance) {
	registration.registationScope = new ExistingInstanceScope(instance);
	return registration;
}
