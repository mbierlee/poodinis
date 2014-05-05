module poodinis.container;

struct Registration {
	TypeInfo_Class registratedType = null;
}

class Container {
	
	private static Registration[] registrations;
	
	private this() {
	}
	
	public static Registration register(T)() {
		Registration newRegistration = { typeid(T) };
		registrations ~= newRegistration;
		return newRegistration;
	}
}
