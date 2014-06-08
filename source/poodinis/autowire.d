/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

module poodinis.autowire;

public import poodinis.container;

import std.typetuple;

debug {
	import std.stdio;
	import std.string;
}

class Autowire{};

public void autowire(Type)(Container container, Type instance) {
	foreach (member ; __traits(derivedMembers, Type)) {
		foreach (attribute; mixin(`__traits(getAttributes, Type.` ~ member ~ `)`) ) {
			if (is(attribute : Autowire) && __traits(getMember, instance, member) is null){
				alias TypeTuple!(__traits(getMember, instance, member)) memberReference;
				debug {
					auto autoWireType = typeid(typeof(memberReference));
					auto memberQualifier = typeid(Type).toString();
					writeln(format("Autowire %s to %s.%s", autoWireType, memberQualifier, member));
				}
				
				__traits(getMember, instance, member) = container.resolve!(typeof(memberReference));
			}
		}
	}
}