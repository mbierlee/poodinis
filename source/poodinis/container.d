module poodinis.container;

import std.string;
import std.array;

public import poodinis.registration;

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
	private bool _typeValidityCheckEnabled = true;
	
	@property public void typeValidityCheckEnabled(bool enabled) {
		_typeValidityCheckEnabled = enabled;
	}
	
	@property public bool typeValidityCheckEnabled() {
		return _typeValidityCheckEnabled;
	}
	
	public Registration register(ConcreteType)() {
		return register!(ConcreteType, ConcreteType)(false);
	}
	
	public Registration register(InterfaceType, ConcreteType)(bool checkTypeValidity = true) {
		TypeInfo registeredType = typeid(InterfaceType);
		TypeInfo_Class instantiatableType = typeid(ConcreteType);
		
		if (typeValidityCheckEnabled && checkTypeValidity) {
			checkValidity!(InterfaceType)(registeredType, instantiatableType);
		}
		
		Registration newRegistration = { registeredType, instantiatableType, new NullScope() };
		registrations[newRegistration.registeredType] = newRegistration;
		return newRegistration;
	}
	
	private void checkValidity(InterfaceType)(TypeInfo registeredType, TypeInfo_Class instanceType) {
		InterfaceType instanceCanBeCastToInterface = cast(InterfaceType) instanceType.create(); 
		if (!instanceCanBeCastToInterface) {
			string errorMessage = format("%s cannot be cast to %s.", instanceType.name, registeredType.toString());
			throw new RegistrationException(errorMessage, registeredType, instanceType);
		}
	}
	
	public ClassType resolve(ClassType)() {
		TypeInfo resolveType = typeid(ClassType);
		Registration* registration = resolveType in registrations;
		if (!registration) {
			throw new ResolveException("Type not registered.", resolveType);
		}
		return cast(ClassType) registration.getInstance();
	}
	
	public void clearRegistrations() {
		registrations.clear();
	}
	
	public static Container getInstance() {
		if (instance is null) {
			instance = new Container();
		}
		return instance;
	}
}
