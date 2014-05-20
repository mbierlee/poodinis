module poodinis.registration;

struct Registration {
	TypeInfo registeredType = null;
	TypeInfo_Class instantiatableType = null;
	RegistrationScope registationScope = null;
	
	public Object getInstance() {
		if (registationScope is null) {
			throw new NoScopeDefinedException(registeredType);
		}
		
		return instantiatableType.create();
	}
}

class NoScopeDefinedException : Exception {
	this(TypeInfo type) {
		super("No scope defined for registration of type " ~ type.toString());
	}
}

interface RegistrationScope {
	public Object getInstance();
}

class NullScope : RegistrationScope {
	public Object getInstance() {
		return null;
	}
}
