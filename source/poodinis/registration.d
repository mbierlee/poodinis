module poodinis.registration;

struct Registration {
	TypeInfo registeredType = null;
	TypeInfo_Class instantiatableType = null;
	
	public Object getInstance() {
		return instantiatableType.create();
	}
}
