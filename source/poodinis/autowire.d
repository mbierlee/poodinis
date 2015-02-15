/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2015 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.autowire;

public import poodinis.container;

import std.typetuple;
import std.exception;

debug {
	import std.stdio;
	import std.string;
}

struct UseMemberType {};

struct Autowire(QualifierType = UseMemberType) {
	QualifierType qualifier;
};

alias Autowired = Autowire;

public void autowire(Type)(DependencyContainer container, Type instance) {
	// For the love of god, refactor this!

	debug(poodinisVerbose) {
		auto instanceType = typeid(Type);
		auto instanceAddress = &instance;
		writeln(format("DEBUG: Autowiring members of [%s@%s]", instanceType, instanceAddress));
	}

	foreach (member ; __traits(allMembers, Type)) {
		static if(__traits(compiles, __traits(getMember, Type, member)) && __traits(compiles, __traits(getAttributes, __traits(getMember, Type, member)))) {
			foreach(autowireAttribute; __traits(getAttributes, __traits(getMember, Type, member))) {
				static if (__traits(isSame, autowireAttribute, Autowire) || is(autowireAttribute == Autowire!T, T)) {
					if (__traits(getMember, instance, member) is null) {
						alias memberReference = TypeTuple!(__traits(getMember, instance, member));
						alias MemberType = typeof(memberReference)[0];

						debug(poodinisVerbose) {
							string qualifiedInstanceTypeString = typeid(MemberType).toString;
						}

						MemberType qualifiedInstance;
						static if (is(autowireAttribute == Autowire!T, T) && !is(autowireAttribute.qualifier == UseMemberType)) {
							alias QualifierType = typeof(autowireAttribute.qualifier);
							qualifiedInstance = container.resolve!(typeof(memberReference), QualifierType);
							debug(poodinisVerbose) {
								qualifiedInstanceTypeString = typeid(QualifierType).toString;
							}
						} else {
							qualifiedInstance = container.resolve!(typeof(memberReference));
						}

						__traits(getMember, instance, member) = qualifiedInstance;

						debug(poodinisVerbose) {
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

public void globalAutowire(Type)(Type instance) {
	DependencyContainer.getInstance().autowire(instance);
}

class AutowiredRegistration(RegistrationType : Object) : Registration {
	private DependencyContainer container;

	public this(TypeInfo registeredType, DependencyContainer container) {
		enforce(!(container is null), "Argument 'container' is null. Autowired registrations need to autowire using a container.");
		this.container = container;
		super(registeredType, typeid(RegistrationType));
	}

	public override Object getInstance(InstantiationContext context = new AutowireInstantiationContext()) {
		RegistrationType instance = cast(RegistrationType) super.getInstance(context);

		AutowireInstantiationContext autowireContext = cast(AutowireInstantiationContext) context;
		enforce(!(autowireContext is null), "Given instantiation context type could not be cast to an AutowireInstantiationContext. If you relied on using the default assigned context: make sure you're calling getInstance() on an instance of type AutowiredRegistration!");
		if (autowireContext.autowireInstance) {
			container.autowire(instance);
		}

		return instance;
	}

}

class AutowireInstantiationContext : InstantiationContext {
	public bool autowireInstance = true;
}
