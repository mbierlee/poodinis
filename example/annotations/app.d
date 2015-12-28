/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2015 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.random;
import std.digest.md;
import std.stdio;
import std.conv;

class SuperSecurityDevice {
	private int seed;

	public this() {
		auto randomGenerator = Random(unpredictableSeed);
		seed = uniform(0, 999, randomGenerator);
	}

	public string getPassword() {
		return to!string(seed) ~ "t1m3sp13!!:";
	}
}

class SecurityManager {
	@Autowire
	public SuperSecurityDevice levelOneSecurity;

	@Autowire
	@AssignNewInstance
	public SuperSecurityDevice levelTwoSecurity;
}

void main() {
	auto dependencies = DependencyContainer.getInstance();
	dependencies.register!SuperSecurityDevice; // Registered with the default "Single instance" scope
	dependencies.register!SecurityManager;

	auto manager = dependencies.resolve!SecurityManager;

	writeln("Password for user one: " ~ manager.levelOneSecurity.getPassword());
	writeln("Password for user two: " ~ manager.levelTwoSecurity.getPassword());

	if (manager.levelOneSecurity is manager.levelTwoSecurity) {
		writeln("SECURITY BREACH!!!!!");
	}
}
