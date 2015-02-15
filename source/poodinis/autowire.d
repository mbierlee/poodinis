/**
 * Contains functionality for autowiring dependencies using a dependency container.
 *
 * This module is used in a dependency container for autowiring dependencies when resolving them.
 * You typically only need this module if you want inject dependencies into a class instance not
 * managed by a dependency container.
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2015 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
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

/**
 * UDA for annotating class members as candidates for autowiring.
 *
 * Annotate member declarations in classes with this UDA to make them eligable for autowiring.
 *
 * Optionally a type as template parameter can be suplied to specify a qualifier. Qualifiers are used
 * to autowire members according the the type given. If class X, which inherits class Y, is given a qualifier
 * of type Y, then only class X's members inherited from type Y are autowired. If no qualifier is supplied, the
 * type of the member is used as qualifier.
 *
 * Examples:
 * Annotate member of class to be autowired:
 * ---
 * class Car {
 *    @Autowire
 *    public Engine engine;
 * }
 * ---
 *
 * Annotate member of class with qualifier:
 * ---
 * class V8Engine : Engine { ... }
 *
 * class Car {
 *    @Autowire!V8Engine
 *    public Engine engine;
 * }
 * ---
 * The members of member "engine" will now be autowired properly, because the autowire mechanism will
 * autowire member "engine" as if it's of type "V8Engine".
 */
struct Autowire(QualifierType = UseMemberType) {
	QualifierType qualifier;
};

/**
 * Alias to "Autowire" UDA for those used to Spring's @Autowired annotation.
 */
alias Autowired = Autowire;

/**
 * Autowires members of a given instance using dependencies registered in the given container.
 *
 * All public members of the given instance, which are annotated using the "Autowire" UDA, are autowired.
 * All members are resolved using the given container. Qualifiers are used to determine the type of class to
 * resolve for any member of instance.
 *
 * Note that private members will not be autowired because the autowiring mechanism is not able to by-pass
 * member visibility protection.
 *
 * See_Also: Autowire
 */
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

/**
 * Autowire the given instance using the global dependency container.
 *
 * See_Also: DependencyContainer
 */
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
