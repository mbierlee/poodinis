module poodinis.container;

struct Registration {
	TypeInfo_Class registratedType = null;
	
	public Object getInstance() {
		return registratedType.create();
	}
}

class Container {
	
	private static Registration[TypeInfo_Class] registrations;
	
	private this() {
	}
	
	public static Registration register(ClassType)() {
		Registration newRegistration = { typeid(ClassType) };
		registrations[newRegistration.registratedType] = newRegistration;
		return newRegistration;
	}
	
	public static ClassType resolve(ClassType)() {
		return cast(ClassType) registrations[typeid(ClassType)].getInstance();
	}
}
