Poodinis Dependency Injection Framework
=======================================
Version 8.0.3  
Copyright 2014-2019 Mike Bierlee  
Licensed under the terms of the MIT license - See [LICENSE.txt](LICENSE.txt)

Master: [![Build Status](https://api.travis-ci.org/mbierlee/poodinis.png?branch=master)](https://travis-ci.org/mbierlee/poodinis) - Dev: [![Build Status](https://api.travis-ci.org/mbierlee/poodinis.png?branch=develop)](https://travis-ci.org/mbierlee/poodinis)

Poodinis is a dependency injection framework for the D programming language. It is inspired by the [Spring Framework] and [Hypodermic] IoC container for C++. Poodinis supports registering and resolving classes either by concrete type or interface. Automatic injection of dependencies is supported through the use of UDAs or constructors.

Requires at least a D 2.068.2 compatible compiler  
Uses the Phobos standard library  
Can be built with DUB 1.1.1 or higher

Features
--------
* Member injection: Injection of dependencies in class members of any visibility (public, private, etc.)
* Constructor injection: Automatic injection of dependencies in class constructors on creation.
* Value injection: Value-types such as primitives or structs can be injected using custom value injectors.
* Type qualifiers: Inject concrete types into members defined only by abstract types.
* Application contexts: Control the creation of dependencies manually through factory methods.
* Multi-threadable: Dependency containers return the same dependencies across all threads.
* Minimal set-up: Creation and injection of conventional classes requires almost no manual dependency configuration.
* Well-tested: Developed test-driven, a great number of scenarios are tested as part of the test suite.  

See the [TUTORIAL.md](TUTORIAL.md) and [examples](example) for a complete walkthrough of all features.

Getting started
---------------
### DUB Dependency
See the Poodinis [DUB project page] for instructions on how to include Poodinis into your project.

### Quickstart
The following example shows the typical usage of Poodinis:
```d
import poodinis;

class Driver {}

interface Database {};

class RelationalDatabase : Database {
	private Driver driver;

	this(Driver driver) { // Automatically injected on creation by container
		this.driver = driver;
	}
}

class DataWriter {
	@Autowire
	private Database database; // Automatically injected when class is resolved
}

void main() {
	auto dependencies = new shared DependencyContainer();
	dependencies.register!Driver;
	dependencies.register!DataWriter;
	dependencies.register!(Database, RelationalDatabase);

	auto writer = dependencies.resolve!DataWriter;
}
```
Dependency set-up can further be reduced by enabling "Register on resolve". For more details and examples, see the [examples](example) directory.

Documentation
-------------
You can find the public API documentation [here](https://mbierlee.github.io/poodinis/).

Alternatively you can generate documentation from the source code using DUB:
```
dub build --build=ddox
```
The documentation can then be found in docs/

History
-------
For a full overview of changes, see [CHANGES.md](CHANGES.md)

Value Injectors
---------------
Poodinis doesn't come with implementations of value injectors. Value injectors are available in separate projects:
* [Proper-d value injector](https://github.com/mbierlee/poodinis-proper-d-injector)

Have you made any or do you know of any? Please add them to this section via a pull request or open an issue.

Projects Using Poodinis
-----------------------
* [Eloquent](https://github.com/SingingBush/eloquent): A lightweight web application written in D
* [ioc](https://github.com/FilipMalczak/ioc): Slow approach to Inversion of Control in D2 language

Future Work
-----------
* Component scan (auto-registration)
* Phobos collections autowiring
* Named qualifiers

Contributing
------------
Any and all pull requests are welcome! If you (only) want discuss changes before making them, feel free to open an Issue on github.
Please develop your changes on (a branch based on) the develop branch. Continuous integration is preferred so feature branches are not neccessary.

[Spring Framework]: http://projects.spring.io/spring-framework/
[Hypodermic]: https://github.com/ybainier/hypodermic/
[DUB]: http://code.dlang.org/
[DUB project page]: http://code.dlang.org/packages/poodinis
[Github issue tracker]: https://github.com/mbierlee/poodinis/issues
