/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2024 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.random;
import std.digest.md;
import std.stdio;
import std.conv;

class SecurityAuditor {
	void submitAudit() {
		writeln("Hmmmyes I have received your audit. It is.... adequate.");
	}
}

class SuperSecurityDevice {
	private int seed;

	this() {
		auto randomGenerator = Random(unpredictableSeed);
		seed = uniform(0, 999, randomGenerator);
	}

	string getPassword() {
		return to!string(seed) ~ "t1m3sp13!!:";
	}
}

class SecurityManager {
	@Inject private SuperSecurityDevice levelOneSecurity;

	@Inject @AssignNewInstance private SuperSecurityDevice levelTwoSecurity;

	@Inject @OptionalDependency private SecurityAuditor auditor;

	void doAudit() {
		if (auditor !is null) {
			auditor.submitAudit();
		} else {
			writeln("I uh, will skip the audit for now...");
		}
	}
}

void main() {
	auto dependencies = new shared DependencyContainer();
	dependencies.register!SuperSecurityDevice; // Registered with the default "Single instance" scope
	dependencies.register!SecurityManager;

	auto manager = dependencies.resolve!SecurityManager;

	writeln("Password for user one: " ~ manager.levelOneSecurity.getPassword());
	writeln("Password for user two: " ~ manager.levelTwoSecurity.getPassword());

	if (manager.levelOneSecurity is manager.levelTwoSecurity) {
		writeln("SECURITY BREACH!!!!!"); // Should not be printed since levelTwoSecurity is a new instance.
	} else {
		writeln("Security okay!");
	}

	manager.doAudit(); // Will not cause the SecurityAuditor to print, since we didn't register a SecurityAuditor.
}
