/**
 * This module contains facilities to support value injection. Actual injection is done by the
 * autowiring mechanism.
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2024 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */
module poodinis.valueinjection;

import std.string : format;
import std.exception : basicExceptionCtors;

/**
 * Thrown when something goes wrong during value injection.
 */
class ValueInjectionException : Exception {
    mixin basicExceptionCtors;
}

/**
 * Thrown by injectors when the value with the given key cannot be found.
 */
class ValueNotAvailableException : Exception {
    this(string key) {
        super(format("Value for key %s is not available", key));
    }

    this(string key, Throwable cause) {
        super(format("Value for key %s is not available", key), cause);
    }
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
 * UDA used for marking class members which should be value-injected.
 *
 * When the injector throws a ValueNotAvailableException, it is re-thrown
 * instead of being suppressed.
 *
 * A key must be supplied, which can be in any format depending on how
 * a value injector reads it.
 *
 * Examples:
 * ---
 * class MyClass {
 *     @MandatoryValue("general.valueWhichShouldBeThere")
 *     private int number;
 * }
 * ---
 */
struct MandatoryValue {
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
 * Note that value injectors are also autowired before being used. Values within dependencies of
 * a value injector are not injected. Neither are values within the value injector itself.
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
     *
     * Throws: ValueNotAvailableException when the value for the given key is not available for any reason
     */
    Type get(string key);
}
