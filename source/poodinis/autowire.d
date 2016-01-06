/**
 * Contains functionality for autowiring dependencies using a dependency container.
 *
 * This module is used in a dependency container for autowiring dependencies when resolving them.
 * You typically only need this module if you want inject dependencies into a class instance not
 * managed by a dependency container.
 *
 * Part of the Poodinis Dependency Injection framework.
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2016 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.autowire;

import poodinis.container;
import poodinis.registration;

import std.exception;
import std.stdio;
import std.string;
import std.traits;
import std.range;

struct UseMemberType {};

/**
 * UDA for annotating class members as candidates for autowiring.
 *
 * Optionally a template parameter can be supplied to specify the type of a qualified class. The qualified type
 * of a concrete class is used to autowire members declared by supertype. If no qualifier is supplied, the type
 * of the member is used as qualifier.
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
 * class FuelEngine : Engine { ... }
 * class ElectricEngine : Engine { ... }
 *
 * class HybridCar {
 *    @Autowire!FuelEngine
 *    public Engine fuelEngine;
 *
 *    @Autowire!ElectricEngine
 *    public Engine electricEngine;
 * }
 * ---
 * The members of an instance of "HybridCar" will now be autowired properly, because the autowire mechanism will
 * autowire member "fuelEngine" as if it's of type "FuelEngine". This means that the members of instance "fuelEngine"
 * will also be autowired because the autowire mechanism knows that member "fuelEngine" is an instance of "FuelEngine"
 */
struct Autowire(QualifierType = UseMemberType) {
	QualifierType qualifier;
};

/**
 * UDA for annotating class members to be autowired with a new instance regardless of their registration scope.
 *
 * Examples:
 *---
 * class Car {
 *     @Autowire
 *     @AssignNewInstance
 *     public Antenna antenna;
 * }
 *---
 * antenna will always be assigned a new instance of class Antenna.
 */
struct AssignNewInstance {}

private void printDebugAutowiredInstance(TypeInfo instanceType, void* instanceAddress) {
	writeln(format("DEBUG: Autowiring members of [%s@%s]", instanceType, instanceAddress));
}

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
public void autowire(Type)(shared(DependencyContainer) container, Type instance) {
	debug(poodinisVerbose) {
		printDebugAutowiredInstance(typeid(Type), &instance);
	}

	foreach (member ; __traits(allMembers, Type)) {
		autowireMember!member(container, instance);
	}
}

private void printDebugAutowiringCandidate(TypeInfo candidateInstanceType, void* candidateInstanceAddress, TypeInfo instanceType, void* instanceAddress, string member) {
	writeln(format("DEBUG: Autowired instance [%s@%s] to [%s@%s].%s", candidateInstanceType, candidateInstanceAddress, instanceType, instanceAddress, member));
}

private void printDebugAutowiringArray(TypeInfo superTypeInfo, TypeInfo instanceType, void* instanceAddress, string member) {
	writeln(format("DEBUG: Autowired all registered instances of super type %s to [%s@%s].%s", superTypeInfo, instanceType, instanceAddress, member));
}

private void autowireMember(string member, Type)(shared(DependencyContainer) container, Type instance) {
	static if(__traits(compiles, __traits(getMember, instance, member)) && __traits(compiles, __traits(getAttributes, __traits(getMember, instance, member)))) {
		foreach(autowireAttribute; __traits(getAttributes, __traits(getMember, instance, member))) {
			static if (__traits(isSame, autowireAttribute, Autowire) || is(autowireAttribute == Autowire!T, T)) {
				if (__traits(getMember, instance, member) is null) {
					alias MemberType = typeof(__traits(getMember, instance, member));

					enum assignNewInstance = hasUDA!(__traits(getMember, instance, member), AssignNewInstance);

					static if (isDynamicArray!MemberType) {
						alias MemberElementType = ElementType!MemberType;
						auto instances = container.resolveAll!MemberElementType;
						__traits(getMember, instance, member) = instances;
						debug(poodinisVerbose) {
							printDebugAutowiringArray(typeid(MemberElementType), typeid(Type), &instance, member);
						}
					} else {
						debug(poodinisVerbose) {
							TypeInfo qualifiedInstanceType = typeid(MemberType);
						}

						MemberType qualifiedInstance;
						static if (is(autowireAttribute == Autowire!T, T) && !is(autowireAttribute.qualifier == UseMemberType)) {
							alias QualifierType = typeof(autowireAttribute.qualifier);
							qualifiedInstance = createOrResolveInstance!(MemberType, QualifierType, assignNewInstance)(container);
							debug(poodinisVerbose) {
								qualifiedInstanceType = typeid(QualifierType);
							}
						} else {
							qualifiedInstance = createOrResolveInstance!(MemberType, MemberType, assignNewInstance)(container);
						}

						__traits(getMember, instance, member) = qualifiedInstance;

						debug(poodinisVerbose) {
							printDebugAutowiringCandidate(qualifiedInstanceType, &qualifiedInstance, typeid(Type), &instance, member);
						}
					}
				}

				break;
			}
		}
	}
}

private QualifierType createOrResolveInstance(MemberType, QualifierType, bool createNew)(shared(DependencyContainer) container) {
	static if (createNew) {
		auto instanceFactory = new InstanceFactory(typeid(MemberType), CreatesSingleton.no, null);
		return cast(MemberType) instanceFactory.getInstance();
	} else {
		return container.resolve!(MemberType, QualifierType);
	}
}

/**
 * Autowire the given instance using the globally available dependency container.
 *
 * See_Also: DependencyContainer
 */
public void globalAutowire(Type)(Type instance) {
	DependencyContainer.getInstance().autowire(instance);
}

class AutowiredRegistration(RegistrationType : Object) : Registration {
	private shared(DependencyContainer) container;

	public this(TypeInfo registeredType, shared(DependencyContainer) container) {
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
