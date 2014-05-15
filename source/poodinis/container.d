module poodinis.container;

struct Registration {
	TypeInfo registratedType = null;
	TypeInfo_Class instantiatableType = null;
	
	public Object getInstance() {
		return instantiatableType.create();
	}
}

class Container {
	
	private static Registration[TypeInfo] registrations;
	
	private this() {
	}
	
	public static Registration register(ConcreteType)() {
		return register!(ConcreteType, ConcreteType)();
	}
	
	public static Registration register(InterfaceType, ConcreteType)() {
		Registration newRegistration = { typeid(InterfaceType), typeid(ConcreteType) };
		registrations[newRegistration.registratedType] = newRegistration;
		return newRegistration;
	}
	
	public static ClassType resolve(ClassType)() {
		return cast(ClassType) registrations[typeid(ClassType)].getInstance();
	}
}
