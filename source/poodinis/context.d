/**
 * Contains the implementation of application context setup.
 *
 * Part of the Poodinis Dependency Injection framework.
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2026 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.context;

import poodinis.container : DependencyContainer;
import poodinis.registration : Registration, existingInstance;
import poodinis.factory : CreatesSingleton, InstanceFactoryParameters;
import poodinis.autowire : autowire;

import std.traits : hasUDA, ReturnType;

class ApplicationContext {
    void registerDependencies(shared(DependencyContainer) container) {
    }
}

/**
* A component annotation is used for specifying which factory methods produce components in
* an application context.
*/
struct Component {
}

/**
* This annotation allows you to specify by which super type the component should be registered. This
* enables you to use type-qualified alternatives for dependencies.
*/
struct RegisterByType(Type) {
    Type type;
}

/**
* Components with the prototype registration will be scoped as dependencies which will create
* new instances every time they are resolved. The factory method will be called repeatedly.
*/
struct Prototype {
}

/**
* Register dependencies through an application context.
*
* An application context allows you to fine-tune dependency set-up and instantiation.
* It is mostly used for dependencies which come from an external library or when you don't
* want to use annotations to set-up dependencies in your classes.
*/
void registerContext(Context : ApplicationContext)(shared(DependencyContainer) container) {
    auto context = new Context();
    context.registerDependencies(container);
    context.registerContextComponents(container);
    container.register!(ApplicationContext, Context)().existingInstance(context);
    autowire(container, context);
}

void registerContextComponents(ApplicationContextType : ApplicationContext)(
    ApplicationContextType context, shared(DependencyContainer) container) {
    foreach (memberName; __traits(allMembers, ApplicationContextType)) {
        foreach (overload; __traits(getOverloads, ApplicationContextType, memberName)) {
            static if (__traits(getProtection, overload) == "public" && hasUDA!(overload, Component)) {
                auto factoryMethod = &__traits(getMember, context, memberName);
                Registration registration = null;
                auto createsSingleton = CreatesSingleton.yes;

                foreach (attribute; __traits(getAttributes, overload)) {
                    static if (is(attribute == RegisterByType!T, T)) {
                        registration = container.register!(typeof(attribute.type),
                            ReturnType!factoryMethod);
                    } else static if (__traits(isSame, attribute, Prototype)) {
                        createsSingleton = CreatesSingleton.no;
                    }
                }

                if (registration is null) {
                    registration = container.register!(ReturnType!factoryMethod);
                }

                registration.instanceFactory.factoryParameters = InstanceFactoryParameters(
                    registration.instanceType,
                    createsSingleton,
                    null,
                    factoryMethod
                );
            }
        }
    }
}

version (unittest)  :  //

import poodinis;
import poodinis.testclasses;
import std.exception;

//Test register component registrations from context
unittest {
    auto container = new shared DependencyContainer();
    auto context = new TestContext();
    context.registerContextComponents(container);
    auto bananaInstance = container.resolve!Banana;

    assert(bananaInstance.color == "Yellow");
}

//Test non-annotated methods are not registered
unittest {
    auto container = new shared DependencyContainer();
    auto context = new TestContext();
    context.registerContextComponents(container);
    assertThrown!ResolveException(container.resolve!Apple);
}

//Test register component by base type
unittest {
    auto container = new shared DependencyContainer();
    auto context = new TestContext();
    context.registerContextComponents(container);
    auto instance = container.resolve!Fruit;
    assert(instance.getShape() == "Pear shaped");
}

//Test register components with multiple candidates
unittest {
    auto container = new shared DependencyContainer();
    auto context = new TestContext();
    context.registerContextComponents(container);

    auto rabbit = container.resolve!(Animal, Rabbit);
    assert(rabbit.getYell() == "Squeeeeeel");

    auto wolf = container.resolve!(Animal, Wolf);
    assert(wolf.getYell() == "Wooooooooooo");
}

//Test register component as prototype
unittest {
    auto container = new shared DependencyContainer();
    auto context = new TestContext();
    context.registerContextComponents(container);

    auto firstInstance = container.resolve!PieChart;
    auto secondInstance = container.resolve!PieChart;

    assert(firstInstance !is null && secondInstance !is null);
    assert(firstInstance !is secondInstance);
}

// Test setting up simple dependencies through application context
unittest {
    auto container = new shared DependencyContainer();
    container.registerContext!SimpleContext;
    auto instance = container.resolve!CakeChart;

    assert(instance !is null);
}

// Test resolving dependency from registered application context
unittest {
    auto container = new shared DependencyContainer();
    container.registerContext!SimpleContext;
    auto instance = container.resolve!Apple;

    assert(instance !is null);
}

// Test autowiring application context
unittest {
    auto container = new shared DependencyContainer();
    container.register!Apple;
    container.registerContext!AutowiredTestContext;
    auto instance = container.resolve!ClassWrapper;

    assert(instance !is null);
    assert(instance.someClass !is null);
}

// Test autowiring application context with dependencies registered in same context
unittest {
    auto container = new shared DependencyContainer();
    container.registerContext!ComplexAutowiredTestContext;
    auto instance = container.resolve!ClassWrapperWrapper;
    auto wrapper = container.resolve!ClassWrapper;
    auto someClass = container.resolve!Apple;

    assert(instance !is null);
    assert(instance.wrapper is wrapper);
    assert(instance.wrapper.someClass is someClass);
}

// Test resolving registered context
unittest {
    auto container = new shared DependencyContainer();
    container.registerContext!TestContext;
    container.resolve!ApplicationContext;
}
