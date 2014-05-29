module poodinis.autowire;

public import poodinis.container;

class Autowire{};

public void autowire(Type)(Container container, Type instance) {
	import std.stdio;
	foreach (member ; __traits(derivedMembers, Type)) {
		foreach (attribute; mixin(`__traits(getAttributes, Type.` ~ member ~ `)`) ) {
			if (is(attribute : Autowire) && __traits(getMember, instance, member) is null){
				__traits(getMember, instance, member) = container.resolve!(typeof(__traits(getMember, instance, member)));
			}
		}
	}
}