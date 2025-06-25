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
 * Copyright: 2014-2025 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.autowire;

import poodinis.container : DependencyContainer, PreDestroy, ResolveException, ResolveOption;
import poodinis.registration : Registration, InstantiationContext;
import poodinis.factory : InstanceFactory, InstanceFactoryParameters, CreatesSingleton;
import poodinis.valueinjection : ValueInjector, ValueInjectionException,
    ValueNotAvailableException, Value, MandatoryValue;
import poodinis.altphobos : isFunction;
import poodinis.imports : createImportsString;

import std.exception : enforce;
import std.string : format;
import std.traits : BaseClassesTuple, FieldNameTuple, fullyQualifiedName, hasUDA, isDynamicArray;
import std.range : ElementType;

debug {
    import std.stdio : writeln;
}

private struct UseMemberType {
}

/**
 * UDA for annotating class members as candidates for autowiring.
 *
 * Optionally a template parameter can be supplied to specify the type of a qualified class. The qualified type
 * of a concrete class is used to autowire members declared by supertype. If no qualifier is supplied, the type
 * of the member is used as qualifier.
 *
 * Note: @Autowire is considered legacy, but not deprecated. Using @Inject is preferred.
 *
 * Examples:
 * Annotate member of class to be autowired:
 * ---
 * class Car {
 *    @Autowire
 *    Engine engine;
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
 *    Engine fuelEngine;
 *
 *    @Autowire!ElectricEngine
 *    Engine electricEngine;
 * }
 * ---
 * The members of an instance of "HybridCar" will now be autowired properly, because the autowire mechanism will
 * autowire member "fuelEngine" as if it's of type "FuelEngine". This means that the members of instance "fuelEngine"
 * will also be autowired because the autowire mechanism knows that member "fuelEngine" is an instance of "FuelEngine"
 *
 * See_Also: Inject
 */
struct Autowire(QualifierType) {
    QualifierType qualifier;
}

/**
 * UDA for marking autowired dependencies optional.
 * Optional dependencies will not lead to a resolveException when there is no type registered for them.
 * The member will remain null.
 */
struct OptionalDependency {
}

/**
 * UDA for annotating class members to be autowired with a new instance regardless of their registration scope.
 *
 * Examples:
 *---
 * class Car {
 *     @Autowire
 *     @AssignNewInstance
 *     Antenna antenna;
 * }
 *---
 * antenna will always be assigned a new instance of class Antenna.
 */
struct AssignNewInstance {
}

private void printDebugAutowiredInstance(TypeInfo instanceType, void* instanceAddress) {
    debug {
        writeln(format("DEBUG: Autowiring members of [%s@%s]", instanceType, instanceAddress));
    }
}

/**
 * Autowires members of a given instance using dependencies registered in the given container.
 *
 * All members of the given instance, which are annotated using the "Autowire" UDA, are autowired.
 * Members can have any visibility (public, private, etc). All members are resolved using the given
 * container. Qualifiers are used to determine the type of class to resolve for any member of instance.
 *
 * See_Also: Autowire
 */
void autowire(Type)(shared(DependencyContainer) container, Type instance, bool isExistingInstance = false) {
    debug (poodinisVerbose) {
        printDebugAutowiredInstance(typeid(Type), &instance);
    }

    // Recurse into base class if there are more between Type and Object in the hierarchy
    static if (BaseClassesTuple!Type.length > 1) {
        autowire!(BaseClassesTuple!Type[0])(container, instance, isExistingInstance);
    }

    foreach (index, name; FieldNameTuple!Type) {
        autowireMember!(name, index, Type)(container, instance, isExistingInstance);
    }
}

private void printDebugAutowiringCandidate(TypeInfo candidateInstanceType,
    void* candidateInstanceAddress, TypeInfo instanceType, void* instanceAddress, string member) {
    debug {
        writeln(format("DEBUG: Autowired instance [%s@%s] to [%s@%s].%s", candidateInstanceType,
                candidateInstanceAddress, instanceType, instanceAddress, member));
    }
}

private void printDebugAutowiringArray(TypeInfo superTypeInfo,
    TypeInfo instanceType, void* instanceAddress, string member) {
    debug {
        writeln(format("DEBUG: Autowired all registered instances of super type %s to [%s@%s].%s",
                superTypeInfo, instanceType, instanceAddress, member));
    }
}

private void autowireMember(string member, size_t memberIndex, Type)(
    shared(DependencyContainer) container, Type instance, bool isExistingInstance) {
    foreach (attribute; __traits(getAttributes, Type.tupleof[memberIndex])) {
        static if (is(attribute == Autowire!T, T)) {
            injectInstance!(member, memberIndex, typeof(attribute.qualifier))(container, instance);
        } else static if (__traits(isSame, attribute, Autowire)) {
            injectInstance!(member, memberIndex, UseMemberType)(container, instance);
        } else static if (is(typeof(attribute) == Value) || is(typeof(attribute) == MandatoryValue)) {
            if (isExistingInstance) {
                continue;
            }
            enum key = attribute.key;
            enum isMandatory = is(typeof(attribute) == MandatoryValue);
            injectValue!(member, memberIndex, key, isMandatory)(container, instance);
        }
    }
}

private void injectInstance(string member, size_t memberIndex, QualifierType, Type)(
    shared(DependencyContainer) container, Type instance) {
    if (instance.tupleof[memberIndex] is null) {
        alias MemberType = typeof(Type.tupleof[memberIndex]);
        enum isOptional = hasUDA!(Type.tupleof[memberIndex], OptionalDependency);

        static if (isDynamicArray!MemberType) {
            injectMultipleInstances!(member, memberIndex, isOptional, MemberType)(container,
                instance);
        } else {
            injectSingleInstance!(member, memberIndex, isOptional, MemberType, QualifierType)(container,
                instance);
        }
    }
}

private void injectMultipleInstances(string member, size_t memberIndex,
    bool isOptional, MemberType, Type)(shared(DependencyContainer) container, Type instance) {
    alias MemberElementType = ElementType!MemberType;
    static if (isOptional) {
        auto instances = container.resolveAll!MemberElementType(ResolveOption.noResolveException);
    } else {
        auto instances = container.resolveAll!MemberElementType;
    }

    instance.tupleof[memberIndex] = instances;
    debug (poodinisVerbose) {
        printDebugAutowiringArray(typeid(MemberElementType), typeid(Type), &instance, member);
    }
}

private void injectSingleInstance(string member, size_t memberIndex,
    bool isOptional, MemberType, QualifierType, Type)(
    shared(DependencyContainer) container, Type instance) {
    debug (poodinisVerbose) {
        TypeInfo qualifiedInstanceType = typeid(MemberType);
    }

    enum assignNewInstance = hasUDA!(Type.tupleof[memberIndex], AssignNewInstance);

    MemberType qualifiedInstance;
    static if (!is(QualifierType == UseMemberType)) {
        qualifiedInstance = createOrResolveInstance!(MemberType, QualifierType,
            assignNewInstance, isOptional)(container);
        debug (poodinisVerbose) {
            qualifiedInstanceType = typeid(QualifierType);
        }
    } else {
        qualifiedInstance = createOrResolveInstance!(MemberType, MemberType,
            assignNewInstance, isOptional)(container);
    }

    instance.tupleof[memberIndex] = qualifiedInstance;

    debug (poodinisVerbose) {
        printDebugAutowiringCandidate(qualifiedInstanceType,
            &qualifiedInstance, typeid(Type), &instance, member);
    }
}

private QualifierType createOrResolveInstance(MemberType, QualifierType,
    bool createNew, bool isOptional)(shared(DependencyContainer) container) {
    static if (createNew) {
        auto instanceFactory = new InstanceFactory();
        instanceFactory.factoryParameters = InstanceFactoryParameters(typeid(MemberType),
            CreatesSingleton.no);
        return cast(MemberType) instanceFactory.getInstance();
    } else {
        static if (isOptional) {
            return container.resolve!(MemberType, QualifierType)(ResolveOption.noResolveException);
        } else {
            return container.resolve!(MemberType, QualifierType);
        }
    }
}

private void injectValue(string member, size_t memberIndex, string key, bool mandatory, Type)(
    shared(DependencyContainer) container, Type instance) {
    alias MemberType = typeof(Type.tupleof[memberIndex]);
    try {
        auto injector = container.resolve!(ValueInjector!MemberType);
        instance.tupleof[memberIndex] = injector.get(key);
        debug (poodinisVerbose) {
            printDebugValueInjection(typeid(Type), &instance, member, typeid(MemberType), key);
        }
    } catch (ResolveException e) {
        throw new ValueInjectionException(format(
                "Could not inject value of type %s into %s.%s: value injector is missing for this type.",
                typeid(MemberType), typeid(Type), member));
    } catch (ValueNotAvailableException e) {
        static if (mandatory) {
            throw new ValueInjectionException(format("Could not inject value of type %s into %s.%s",
                    typeid(MemberType), typeid(Type), member), e);
        }
    }
}

private void printDebugValueInjection(TypeInfo instanceType,
    void* instanceAddress, string member, TypeInfo valueType, string key) {
    debug {
        writeln(format("DEBUG: Injected value with key '%s' of type %s into [%s@%s].%s",
                key, valueType, instanceType, instanceAddress, member));
    }
}

/**
 * Autowire the given instance using the globally available dependency container.
 *
 * See_Also: DependencyContainer
 * Deprecated: Using the global container is undesired. See DependencyContainer.getInstance().
 */
deprecated void globalAutowire(Type)(Type instance) {
    DependencyContainer.getInstance().autowire(instance);
}

class AutowiredRegistration(RegistrationType : Object) : Registration {
    private shared(DependencyContainer) container;

    this(TypeInfo registeredType, InstanceFactory instanceFactory,
        shared(DependencyContainer) originatingContainer) {
        super(registeredType, typeid(RegistrationType), instanceFactory, originatingContainer);
    }

    override Object getInstance(
        InstantiationContext context = new AutowireInstantiationContext()) {
        enforce(!(originatingContainer is null),
            "The registration's originating container is null. There is no way to resolve autowire dependencies.");

        RegistrationType instance = cast(RegistrationType) super.getInstance(context);

        AutowireInstantiationContext autowireContext = cast(AutowireInstantiationContext) context;
        enforce(!(autowireContext is null),
            "Given instantiation context type could not be cast to an AutowireInstantiationContext. If you relied on using the default assigned context: make sure you're calling getInstance() on an instance of type AutowiredRegistration!");
        if (autowireContext.autowireInstance) {
            bool isExistingInstance = instanceFactory.factoryParameters
                .existingInstance !is null;
            originatingContainer.autowire(instance, isExistingInstance);
        }

        this.preDestructor = getPreDestructor(instance);

        return instance;
    }

    private void delegate() getPreDestructor(RegistrationType instance) {
        void delegate() preDestructor = null;
        static foreach (memberName; __traits(allMembers, RegistrationType)) {
            static if (__traits(compiles, __traits(getOverloads, RegistrationType, memberName))) {
                static foreach (overload; __traits(getOverloads, RegistrationType, memberName)) {
                    static if (__traits(compiles, __traits(getProtection, overload))
                        && __traits(getProtection, overload) == "public"
                        && isFunction!overload
                        && hasUDA!(overload, PreDestroy)) {
                        preDestructor = &__traits(getMember, instance, memberName);
                    }
                }
            }
        }

        return preDestructor;
    }
}

class AutowireInstantiationContext : InstantiationContext {
    bool autowireInstance = true;
}

version (unittest)  :  //

import poodinis;
import poodinis.testclasses;
import std.exception;

// Test autowiring concrete type to existing instance
unittest {
    auto container = new shared DependencyContainer();
    container.register!ComponentA;
    auto componentB = new ComponentB();
    container.autowire(componentB);
    assert(componentB !is null, "Autowirable dependency failed to autowire");
}

// Test autowiring interface type to existing instance
unittest {
    auto container = new shared DependencyContainer();
    container.register!(InterfaceA, ComponentC);
    auto componentD = new ComponentD();
    container.autowire(componentD);
    assert(componentD.componentC !is null, "Autowirable dependency failed to autowire");
}

// Test autowiring private members
unittest {
    auto container = new shared DependencyContainer();
    container.register!(InterfaceA, ComponentC);
    auto componentD = new ComponentD();
    container.autowire(componentD);
    assert(componentD.privateComponentC is componentD.componentC,
        "Autowire private dependency failed");
}

// Test autowiring will only happen once
unittest {
    auto container = new shared DependencyContainer();
    container.register!(InterfaceA, ComponentC).newInstance();
    auto componentD = new ComponentD();
    container.autowire(componentD);
    auto expectedComponent = componentD.componentC;
    container.autowire(componentD);
    auto actualComponent = componentD.componentC;
    assert(expectedComponent is actualComponent,
        "Autowiring the second time wired a different instance");
}

// Test autowiring unregistered type
unittest {
    auto container = new shared DependencyContainer();
    auto componentD = new ComponentD();
    assertThrown!(ResolveException)(container.autowire(componentD),
        "Autowiring unregistered type should throw ResolveException");
}

// Test autowiring member with non-autowire attribute does not autowire
unittest {
    auto container = new shared DependencyContainer();
    auto componentE = new ComponentE();
    container.autowire(componentE);
    assert(componentE.componentC is null,
        "Autowiring should not occur for members with attributes other than @Autowire");
}

// Test autowire class with alias declaration
unittest {
    auto container = new shared DependencyContainer();
    container.register!ComponentA;
    auto componentDeclarationCocktail = new ComponentDeclarationCocktail();

    container.autowire(componentDeclarationCocktail);

    assert(componentDeclarationCocktail.componentA !is null,
        "Autowiring class with non-assignable declarations failed");
}

// Test autowire class with qualifier
unittest {
    auto container = new shared DependencyContainer();
    container.register!(InterfaceA, ComponentC);
    container.register!(InterfaceA, ComponentX);
    auto componentX = container.resolve!(InterfaceA, ComponentX);

    auto monkeyShine = new MonkeyShine();
    container.autowire(monkeyShine);

    assert(monkeyShine.component is componentX, "Autowiring class with qualifier failed");
}

// Test autowire class with multiple qualifiers
unittest {
    auto container = new shared DependencyContainer();
    container.register!(InterfaceA, ComponentC);
    container.register!(InterfaceA, ComponentX);
    auto componentC = container.resolve!(InterfaceA, ComponentC);
    auto componentX = container.resolve!(InterfaceA, ComponentX);

    auto bootstrapBootstrap = new BootstrapBootstrap();
    container.autowire(bootstrapBootstrap);

    assert(bootstrapBootstrap.componentX is componentX,
        "Autowiring class with multiple qualifiers failed");
    assert(bootstrapBootstrap.componentC is componentC,
        "Autowiring class with multiple qualifiers failed");
}

// Test getting instance from autowired registration will autowire instance
unittest {
    auto container = new shared DependencyContainer();
    container.register!ComponentA;

    auto registration = new AutowiredRegistration!ComponentB(typeid(ComponentB),
        new InstanceFactory(), container).initializeFactoryType().singleInstance();
    auto instance = cast(ComponentB) registration.getInstance(
        new AutowireInstantiationContext());

    assert(instance.componentA !is null);
}

// Test autowiring a dynamic array with all qualified types
unittest {
    auto container = new shared DependencyContainer();
    container.register!(InterfaceA, ComponentC);
    container.register!(InterfaceA, ComponentX);

    auto lord = new LordOfTheComponents();
    container.autowire(lord);

    assert(lord.components.length == 2, "Dynamic array was not autowired");
}

// Test autowiring new instance of singleinstance registration with newInstance UDA
unittest {
    auto container = new shared DependencyContainer();
    container.register!ComponentA;

    auto regularComponentA = container.resolve!ComponentA;
    auto charlie = new ComponentCharlie();

    container.autowire(charlie);

    assert(charlie.componentA !is regularComponentA,
        "Autowiring class with AssignNewInstance did not yield a different instance");
}

// Test autowiring members from base class
unittest {
    auto container = new shared DependencyContainer();
    container.register!ComponentA;
    container.register!ComponentB;
    container.register!ComponentZ;

    auto instance = new ComponentZ();
    container.autowire(instance);

    assert(instance.componentA !is null);
}

// Test autowiring optional dependencies
unittest {
    auto container = new shared DependencyContainer();
    auto instance = new OuttaTime();

    container.autowire(instance);

    assert(instance.interfaceA is null);
    assert(instance.componentA is null);
    assert(instance.componentCs is null);
}

// Test autowiring class using value injection
unittest {
    auto container = new shared DependencyContainer();

    container.register!(ValueInjector!int, TestInjector);
    container.register!ComponentA;
    auto instance = new ValuedClass();

    container.autowire(instance);

    assert(instance.intValue == 8);
    assert(instance.unrelated !is null);
}

// Test that @Value is not injected at all for existingInstance (default value case)
unittest {
    auto container = new shared DependencyContainer();
    container.register!(ValueInjector!int, TestInjector);
    container.register!ComponentA;
    auto instance1 = new ValuedClass();
    container.register!ValuedClass.existingInstance(instance1);
    auto resolved1 = container.resolve!ValuedClass;
    assert(resolved1 is instance1, "Should resolve to the same instance");
    assert(resolved1.intValue == int.init, "@Value should not inject for existingInstance, even if default");
    assert(resolved1.unrelated !is null, "Other dependencies should still be autowired");
}

// Test that @Value is not injected at all for existingInstance (non-default value case)
unittest {
    auto container = new shared DependencyContainer();
    container.register!(ValueInjector!int, TestInjector);
    container.register!ComponentA;
    auto instance2 = new ValuedClass();
    instance2.intValue = 42;
    container.register!ValuedClass.existingInstance(instance2);
    auto resolved2 = container.resolve!ValuedClass;
    assert(resolved2 is instance2, "Should resolve to the same instance");
    assert(resolved2.intValue == 42, "@Value should not inject for existingInstance, even if non-default");
    assert(resolved2.unrelated !is null, "Other dependencies should still be autowired");
}
