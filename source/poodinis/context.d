/**
 * Contains the implementation of application context setup.
 *
 * Part of the Poodinis Dependency Injection framework.
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2015 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.context;

import poodinis.container;
import poodinis.registration;

import std.traits;

class ApplicationContext {
	public void registerDependencies(shared(DependencyContainer) container) {}
}

/**
* A component annotation is used for specifying which factory methods produce components in
* an application context.
*/
struct Component {}

/**
* This annotation allows you to specify by which super type the component should be registered. This
* enables you to use type-qualified alternatives for dependencies.
*/
struct RegisterByType(Type) {
	Type type;
}

public void registerContextComponents(ApplicationContextType : ApplicationContext)(ApplicationContextType context, shared(DependencyContainer) container) {
	foreach (member ; __traits(allMembers, ApplicationContextType)) {
		static if (hasUDA!(__traits(getMember, context, member), Component)) {
			auto factoryMethod = &__traits(getMember, context, member);
			Registration registration = null;

			foreach(attribute; __traits(getAttributes, __traits(getMember, context, member))) {
				static if (is(attribute == RegisterByType!T, T)) {
					registration = container.register!(typeof(attribute.type), ReturnType!factoryMethod);
				}
			}

			if (registration is null) {
				registration = container.register!(ReturnType!factoryMethod);
			}

			registration.instanceFactory = new InstanceFactory(registration.instanceType, CreatesSingleton.yes, null, factoryMethod);
		}
	}
}
