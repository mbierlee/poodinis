/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.autowire;

public import poodinis.dependency;

import std.typetuple;

debug {
	import std.stdio;
	import std.string;
}

class Autowire{};

struct Qualifier(T) {
	T qualifier;
}

alias Autowired = Autowire;

public void autowire(Type)(DependencyContainer container, Type instance) {
	// For the love of god, refactor this!
	
	debug {
		auto instanceType = typeid(Type);
		auto instanceAddress = &instance;
		writeln(format("DEBUG: Autowiring members of [%s@%s]", instanceType, instanceAddress));
	}
	
	foreach (member ; __traits(allMembers, Type)) {
		static if(__traits(compiles, __traits(getMember, Type, member)) && __traits(compiles, __traits(getAttributes, __traits(getMember, Type, member)))) {
			foreach(autowireAttribute; __traits(getAttributes, __traits(getMember, Type, member))) {
				static if (is(autowireAttribute : Autowire)) {
					if (__traits(getMember, instance, member) is null) {
						alias TypeTuple!(__traits(getMember, instance, member)) memberReference;
						alias MemberType = typeof(memberReference)[0];
						debug {
							string qualifiedInstanceTypeString = typeid(MemberType).toString;
						}
						
						MemberType qualifiedInstance;
						auto resolvedThroughQualifier = false;
						foreach (qualifierAttribute; __traits(getAttributes, __traits(getMember, Type, member))) {
							static if (is(qualifierAttribute == Qualifier!T, T)) {
								alias QualifierType = typeof(qualifierAttribute.qualifier);
								qualifiedInstance = container.resolve!(typeof(memberReference), QualifierType);
								
								debug {
									qualifiedInstanceTypeString = typeid(QualifierType).toString;
								}
								
								resolvedThroughQualifier = true;
								break;
							}
						}
						
						if (!resolvedThroughQualifier) {
							qualifiedInstance = container.resolve!(typeof(memberReference));
						}
						
						__traits(getMember, instance, member) = qualifiedInstance;
						
						debug {
							auto qualifiedInstanceAddress = &qualifiedInstance;
							writeln(format("DEBUG: Autowired instance [%s@%s] to [%s@%s].%s", qualifiedInstanceTypeString, qualifiedInstanceAddress, instanceType, instanceAddress, member));
						}
					}
					
					break;
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