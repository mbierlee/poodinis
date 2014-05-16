module poodinis.container;

import std.string;
import std.array;

struct Registration {
	TypeInfo registeredType = null;
	TypeInfo_Class instantiatableType = null;
	
	public Object getInstance() {
		return instantiatableType.create();
	}
}

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
	
	private static Registration[TypeInfo] registrations;
	
	private this() {
	}
	
	public static Registration register(ConcreteType)() {
		return register!(ConcreteType, ConcreteType)();
	}
	
	public static Registration register(InterfaceType, ConcreteType)(bool checkTypeValidity = true) {
		TypeInfo registeredType = typeid(InterfaceType);
		TypeInfo_Class instantiatableType = typeid(ConcreteType);
		
		if (checkTypeValidity) {
			checkValidity!(InterfaceType)(registeredType, instantiatableType);
		}
		
		Registration newRegistration = { registeredType, instantiatableType };
		registrations[newRegistration.registeredType] = newRegistration;
		return newRegistration;
	}
	
	private static void checkValidity(InterfaceType)(TypeInfo registeredType, TypeInfo_Class instanceType) {
		InterfaceType instanceCanBeCastToInterface = cast(InterfaceType) instanceType.create(); 
		if (!instanceCanBeCastToInterface) {
			string errorMessage = format("%s cannot be cast to %s.", instanceType.name, registeredType.toString());
			throw new RegistrationException(errorMessage, registeredType, instanceType);
		}
	}
	
	public static ClassType resolve(ClassType)() {
		TypeInfo resolveType = typeid(ClassType);
		Registration* registration = resolveType in registrations;
		if (!registration) {
			throw new ResolveException("Type not registered.", resolveType);
		}
		return cast(ClassType) registration.getInstance();
	}
	
	public static void clearRegistrations() {
		registrations.clear();
	}
}
