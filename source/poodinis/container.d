module poodinis.container;

import std.string;
import std.array;

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
		this.autowire!(RegistrationType)(instance); 
		return instance;
	}
	
	public void clearAllRegistrations() {
		registrations.clear();
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
