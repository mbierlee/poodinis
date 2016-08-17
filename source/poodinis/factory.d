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

struct InstanceFactoryParameters {
	TypeInfo_Class instanceType;
	CreatesSingleton createsSingleton = CreatesSingleton.yes;
	Object existingInstance;
	InstanceFactoryMethod factoryMethod;
}

class InstanceFactory {
	private Object instance = null;
	private InstanceFactoryParameters _factoryParameters;

	public @property void factoryParameters(InstanceFactoryParameters factoryParameters) {
		if (factoryParameters.factoryMethod is null) {
			factoryParameters.factoryMethod = &this.createInstance;
		}

		if (factoryParameters.existingInstance !is null) {
			factoryParameters.createsSingleton = CreatesSingleton.yes;
			this.instance = factoryParameters.existingInstance;
		}

		_factoryParameters = factoryParameters;
	}

	public @property InstanceFactoryParameters factoryParameters() {
		return _factoryParameters;
	}

	public Object getInstance() {
		if (_factoryParameters.createsSingleton && instance !is null) {
			debug(poodinisVerbose) {
				writeln(format("DEBUG: Existing instance returned of type %s", _factoryParameters.instanceType.toString()));
			}

			return instance;
		}

		debug(poodinisVerbose) {
			writeln(format("DEBUG: Creating new instance of type %s", _factoryParameters.instanceType.toString()));
		}

		instance = _factoryParameters.factoryMethod();
		return instance;
	}

	private Object createInstance() {
		enforce!InstanceCreationException(_factoryParameters.instanceType, "Instance type is not defined, cannot create instance without knowing its type.");
		return _factoryParameters.instanceType.create();
	}
}
