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
	
	public static Registration register(T)() {
		Registration newRegistration = { typeid(T) };
		registrations[newRegistration.registratedType] = newRegistration;
		return newRegistration;
	}
	
	public static T resolve(T)() {
		return cast(T) registrations[typeid(T)].getInstance();
	}
}
