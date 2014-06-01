/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.autowire;

public import poodinis.container;

class Autowire{};

public void autowire(Type)(Container container, Type instance) {
	foreach (member ; __traits(derivedMembers, Type)) {
		foreach (attribute; mixin(`__traits(getAttributes, Type.` ~ member ~ `)`) ) {
			if (is(attribute : Autowire) && __traits(getMember, instance, member) is null){
				__traits(getMember, instance, member) = container.resolve!(typeof(__traits(getMember, instance, member)));
			}
		}
	}
}