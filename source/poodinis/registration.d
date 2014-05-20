module poodinis.registration;

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
			instance = instantiatableType.create();
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
		return instance;
	}
}

public Registration existingInstance(Registration registration, Object instance) {
	registration.registationScope = new ExistingInstanceScope(instance);
	return registration;
}
