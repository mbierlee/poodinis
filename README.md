Poodinis Dependency Injection Framework
=======================================
Version 7.0.0  
Copyright 2014-2016 Mike Bierlee  
Licensed under the terms of the MIT license - See [LICENSE.txt](LICENSE.txt)

Master: [![Build Status](https://api.travis-ci.org/mbierlee/poodinis.png?branch=master)](https://travis-ci.org/mbierlee/poodinis) - Dev: [![Build Status](https://api.travis-ci.org/mbierlee/poodinis.png?branch=develop)](https://travis-ci.org/mbierlee/poodinis)

Poodinis is a dependency injection framework for the D programming language. It is inspired by the [Spring Framework] and [Hypodermic] IoC container for C++. Poodinis supports registering and resolving classes either by concrete type or interface. Automatic injection of dependencies is supported through the use of UDAs (Referred to as autowiring).

Requires at least a D 2.068.0 compatible compiler  
Uses the Phobos standard library  
Can be built with DUB 0.9.24 or higher

History
-------
For a full overview of changes, see [CHANGES.md](CHANGES.md)

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
	auto dependencies = DependencyContainer.getInstance();
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

Future Work
-----------
* Component scan (auto-registration)
* Phobos collections autowiring
* Constructor injection
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
