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

public void registerContextComponents(ApplicationContextType : ApplicationContext)(ApplicationContextType context, shared(DependencyContainer) container) {
	import std.stdio;
	foreach (member ; __traits(allMembers, ApplicationContextType)) {
		static if (hasUDA!(__traits(getMember, context, member), Component)) {
			auto factoryMethod = &__traits(getMember, context, member);
			auto registration = container.register!(ReturnType!factoryMethod);
			registration.instanceFactory = new InstanceFactory(registration.instantiatableType, CreatesSingleton.yes, null, factoryMethod);
		}
	}
}
