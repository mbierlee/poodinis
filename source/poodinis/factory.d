/**
 * This module contains instance factory facilities
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2016 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.factory;

import std.typecons;
import std.exception;

debug {
	import std.string;
	import std.stdio;
}

alias CreatesSingleton = Flag!"CreatesSingleton";
alias InstanceFactoryMethod = Object delegate();

class InstanceCreationException : Exception {
	this(string message, string file = __FILE__, size_t line = __LINE__) {
		super(message, file, line);
	}
}

class InstanceFactory {
	private TypeInfo_Class instanceType = null;
	private Object instance = null;
	private CreatesSingleton createsSingleton;
	private InstanceFactoryMethod factoryMethod;

	this(TypeInfo_Class instanceType, CreatesSingleton createsSingleton = CreatesSingleton.yes, Object existingInstance = null, InstanceFactoryMethod factoryMethod = null) {
		this.instanceType = instanceType;
		this.createsSingleton = existingInstance !is null ? CreatesSingleton.yes : createsSingleton;
		this.instance = existingInstance;
		this.factoryMethod = factoryMethod !is null ? factoryMethod : &this.createInstance;
	}

	public Object getInstance() {
		if (createsSingleton && instance !is null) {
			debug(poodinisVerbose) {
				writeln(format("DEBUG: Existing instance returned of type %s", instanceType.toString()));
			}

			return instance;
		}

		debug(poodinisVerbose) {
			writeln(format("DEBUG: Creating new instance of type %s", instanceType.toString()));
		}

		instance = factoryMethod();
		return instance;
	}

	private Object createInstance() {
		enforce!InstanceCreationException(instanceType, "Instance type is not defined, cannot create instance without knowing its type.");
		return instanceType.create();
	}
}
