/**
 * This module contains facilities to support value injection. Actual injection is done by the
 * autowiring mechanism.
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2016 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */
module poodinis.valueinjection;

import std.exception;

/**
 * Thrown when something goes wrong during value injection.
 */
class ValueInjectionException : Exception {
	mixin basicExceptionCtors;
}

/**
 * UDA used for marking class members which should be value-injected.
 *
 * A key must be supplied, which can be in any format depending on how
 * a value injector reads it.
 *
 * When the injector throws a ValueNotAvailableException, the value is
 * not injected and will keep its original assignment.
 *
 * Examples:
 * ---
 * class MyClass {
 *     @Value("general.importantNumber")
 *     private int number = 8;
 * }
 * ---
 */
struct Value {
	/**
	 * The textual key used to find the value by injectors.
	 *
	 * The format is injector-specific.
	 */
	string key;
}

/**
 * Interface which should be implemented by value injectors.
 *
 * Each value injector injects one specific type. The type can be any primitive
 * type or that of a struct. While class types are also supported, value injectors
 * are not intended for them.
 *
 * Note that value injectors are also autowired before being used. Value injectors should
 * not contain dependencies on classes which require value injection. Neither should a
 * value injector have members which are to be value-injected.
 *
 * Value injection is not supported for constructor injection.
 *
 * Examples:
 * ---
 * class MyIntInjector : ValueInjector!int {
 *     public override int get(string key) { ... }
 * }
 *
 * // In order to make the container use your injector, register it by interface:
 * container.register!(ValueInjector!int, MyIntInjector);
 * ---
 */
interface ValueInjector(Type) {
	/**
	 * Get a value from the injector by key.
	 *
	 * The key can have any format. Generally you are encouraged
	 * to accept a dot separated path, for example: server.http.port
	 */
	Type get(string key);
}

