/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2019 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.stdio;

class ADependency {
	@PostConstruct
	public void postConstructor() {
		writeln("The dependency is created.");
	}

	public void callMe() {
		writeln("The dependency was called.");
	}
}

class AClass {
	@Autowire
	public ADependency dependency; // Dependencies are autowired before the post-constructor is called.

	@PostConstruct
	public void postConstructor() {
		writeln("The class is created.");
		if (dependency !is null) {
			writeln("The dependency is autowired.");
		} else {
			writeln("The dependency was NOT autowired.");
		}
	}

	@PreDestroy
	public void preDestructor() {
		writeln("The class is no longer registered with the container.");
	}
}

public void main() {
	auto container = new shared DependencyContainer();
	container.register!ADependency;
	container.register!AClass;
	auto instance = container.resolve!AClass; // Will cause the post constructor to be called.
	container.removeRegistration!AClass; // Will cause the pre destructor to be called.

	// The instance won't be destroyed by the container and as long as there are references to it,
	// it will not be collected by the garbage collector either.
	instance.dependency.callMe();
}
