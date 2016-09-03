Poodinis Dependency Injection Framework
=======================================
Version 7.0.0  
Copyright 2014-2016 Mike Bierlee  
Licensed under the terms of the MIT license - See [LICENSE.txt](LICENSE.txt)

Master: [![Build Status](https://api.travis-ci.org/mbierlee/poodinis.png?branch=master)](https://travis-ci.org/mbierlee/poodinis) - Dev: [![Build Status](https://api.travis-ci.org/mbierlee/poodinis.png?branch=develop)](https://travis-ci.org/mbierlee/poodinis)

Poodinis is a dependency injection framework for the D programming language. It is inspired by the [Spring Framework] and [Hypodermic] IoC container for C++. Poodinis supports registering and resolving classes either by concrete type or interface. Automatic injection of dependencies is supported through the use of UDAs or constructors.

Requires at least a D 2.068.0 compatible compiler  
Uses the Phobos standard library  
Can be built with DUB 0.9.24 or higher

Features
--------
* Member injection: Injection of dependencies in class members of any visibility (public, private, etc.)
* Constructor injection: Automatic injection of dependencies in class constructors on creation.
* Type qualifiers: Inject concrete types into members defined only by abstract types.
* Application contexts: Control the creation of dependencies manually through factory methods.
* Multi-threadable: Dependency containers return the same dependencies across all threads.
* Minimal set-up: Creation and injection of conventional classes requires almost no manual dependency configuration.
* Well-tested: Developed test-driven, a great number of scenarios are tested as part of the test suite. 
See the [TUTORIAL.md](TUTORIAL.md) and [examples](example) for a complete walkthrough of all features.

Getting started
---------------
###DUB Dependency
See the Poodinis [DUB project page] for instructions on how to include Poodinis into your project.

###Quickstart
The following example shows the typical usage of Poodinis:
```d
import poodinis;

interface Database{};
class RelationalDatabase : Database {}

class DataWriter {
	@Autowire
	private Database database; // Automatically injected when class is resolved
}

void main() {
	auto dependencies = new shared DependencyContainer();
	dependencies.register!DataWriter;
	dependencies.register!(Database, RelationalDatabase);

	auto writer = dependencies.resolve!DataWriter;
}
```
For more examples, see the [examples](example) directory.

###Tutorial
For an extended tutorial walking you through all functionality offered by Poodinis, see [TUTORIAL.md](TUTORIAL.md)

Documentation
-------------
You can generate Public API documentation from the source code using DUB:
```
dub build --build=ddox
```
The documentation can then be found in docs/

History
-------
For a full overview of changes, see [CHANGES.md](CHANGES.md)

Future Work
-----------
* Component scan (auto-registration)
* Phobos collections autowiring
* Named qualifiers
* Value type injection

Contributing
------------
Any and all pull requests are welcome! If you (only) want discuss changes before making them, feel free to open an Issue on github.
Please develop your changes on (a branch based on) the develop branch. Continuous integration is preferred so feature branches are not neccessary.

[Spring Framework]: http://projects.spring.io/spring-framework/
[Hypodermic]: https://github.com/ybainier/hypodermic/
[DUB]: http://code.dlang.org/
[DUB project page]: http://code.dlang.org/packages/poodinis
[Github issue tracker]: https://github.com/mbierlee/poodinis/issues
