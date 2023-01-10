/**
 * Contains the implementation of application context setup.
 *
 * Part of the Poodinis Dependency Injection framework.
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2023 Mike Bierlee
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

class ApplicationContext
{
    public void registerDependencies(shared(DependencyContainer) container)
    {
    }
}

/**
* A component annotation is used for specifying which factory methods produce components in
* an application context.
*/
struct Component
{
}

/**
* This annotation allows you to specify by which super type the component should be registered. This
* enables you to use type-qualified alternatives for dependencies.
*/
struct RegisterByType(Type)
{
    Type type;
}

/**
* Components with the prototype registration will be scoped as dependencies which will create
* new instances every time they are resolved. The factory method will be called repeatedly.
*/
struct Prototype
{
}

/**
* Register dependencies through an application context.
*
* An application context allows you to fine-tune dependency set-up and instantiation.
* It is mostly used for dependencies which come from an external library or when you don't
* want to use annotations to set-up dependencies in your classes.
*/
public void registerContext(Context : ApplicationContext)(shared(DependencyContainer) container)
{
    auto context = new Context();
    context.registerDependencies(container);
    context.registerContextComponents(container);
    container.register!(ApplicationContext, Context)().existingInstance(context);
    autowire(container, context);
}

public void registerContextComponents(ApplicationContextType : ApplicationContext)(
        ApplicationContextType context, shared(DependencyContainer) container)
{
    foreach (member; __traits(allMembers, ApplicationContextType))
    {
        static if (__traits(getProtection, __traits(getMember, context,
                member)) == "public" && hasUDA!(__traits(getMember, context, member), Component))
        {
            auto factoryMethod = &__traits(getMember, context, member);
            Registration registration = null;
            auto createsSingleton = CreatesSingleton.yes;

            foreach (attribute; __traits(getAttributes, __traits(getMember, context, member)))
            {
                static if (is(attribute == RegisterByType!T, T))
                {
                    registration = container.register!(typeof(attribute.type),
                            ReturnType!factoryMethod);
                }
                else static if (__traits(isSame, attribute, Prototype))
                {
                    createsSingleton = CreatesSingleton.no;
                }
            }

            if (registration is null)
            {
                registration = container.register!(ReturnType!factoryMethod);
            }

            registration.instanceFactory.factoryParameters = InstanceFactoryParameters(
                    registration.instanceType, createsSingleton, null, factoryMethod);
        }
    }
}
