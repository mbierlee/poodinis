module poodinis.container;

import std.string;

struct Registration {
	TypeInfo registratedType = null;
	TypeInfo_Class instantiatableType = null;
	
	public Object getInstance() {
		return instantiatableType.create();
	}
}

class RegistrationException : Exception {
	this(string message, TypeInfo registratedType, TypeInfo_Class instantiatableType) {
		super(format("Exception while registering type %s to %s: %s", registratedType.toString(), instantiatableType.name, message));
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
		registrations[newRegistration.registratedType] = newRegistration;
		return newRegistration;
	}
	
	private static void checkValidity(InterfaceType)(TypeInfo registeredType, TypeInfo_Class instanceType) {
		InterfaceType instanceCanBeCastToInterface = cast(InterfaceType) instanceType.create(); 
		if (!instanceCanBeCastToInterface) {
			string errorMessage = format("%s cannot be cast to %s", instanceType.name, registeredType.toString());
			throw new RegistrationException(errorMessage, registeredType, instanceType);
		}
	}
	
	public static ClassType resolve(ClassType)() {
		return cast(ClassType) registrations[typeid(ClassType)].getInstance();
	}
}
