/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.autowire;

public import poodinis.container;

import std.typetuple;

debug {
	import std.stdio;
	import std.string;
}

class Autowire{};

alias Autowired = Autowire;

public void autowire(Type)(DependencyContainer container, Type instance) {
	debug {
		auto memberType = typeid(Type);
		auto instanceAddress = &instance;
		writeln(format("DEBUG: Autowiring members of [%s@%s]", memberType, instanceAddress));
	}
	
	foreach (member ; __traits(allMembers, Type)) {
		static if(__traits(compiles, __traits( getMember, Type, member )) && __traits(compiles, __traits(getAttributes, __traits(getMember, Type, member )))) {
			foreach(attribute; __traits(getAttributes, __traits(getMember, Type, member))) {
				if (is(attribute : Autowire) && __traits(getMember, instance, member) is null){
					alias TypeTuple!(__traits(getMember, instance, member)) memberReference;
					auto autowirableInstance = container.resolve!(typeof(memberReference));
					debug {
						auto autowirableType = typeid(typeof(memberReference[0]));
						auto autowireableAddress = &autowirableInstance;
						writeln(format("DEBUG: Autowire instance [%s@%s] to [%s@%s].%s", autowirableType, autowireableAddress, memberType, instanceAddress, member));
					}
					
					__traits(getMember, instance, member) = autowirableInstance;
				}
			}
		}
	}
}

mixin template AutowireConstructor() {
	public this() {
		globalAutowire(this);
	}
}

public void globalAutowire(Type)(Type instance) {
	DependencyContainer.getInstance().autowire(instance);
}