Poodinis Dependency Injection Framework
=======================================
Version 0.3.1  
Copyright 2014-2015 Mike Bierlee  
Licensed under the terms of the MIT license - See [LICENSE.txt](LICENSE.txt)

[![Build Status](https://api.travis-ci.org/mbierlee/poodinis.png)](https://travis-ci.org/mbierlee/poodinis)

Poodinis is a dependency injection framework for the D programming language. It is inspired by the [Spring Framework] and [Hypodermic] IoC container for C++. Poodinis supports registering and resolving classes either by concrete type or interface. Automatic injection of dependencies is supported through the use of UDAs (Referred to as autowiring).

Uses D 2.066.0 and Phobos.
Can be built with DUB 0.9.22.

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
import poodinis.dependency;

interface Database{};
class RelationalDatabase : Database {}

class DataWriter {
	@Autowire
	public Database database; // Automatically injected when class is resolved
}

void main() {
	auto container = DependencyContainer.getInstance();
	container.register!DataWriter;
	container.register!(Database, RelationalDatabase);

	auto writer = container.resolve!DataWriter;
}
```

### The container
To register a class, a new dependency container must be instantiated:
```d
// Register a private container
auto container = new DependencyContainer();
// Or use the singleton container
container = DependencyContainer.getInstance();
```
###Registering dependencies
To make dependencies available, they have to be registered:
```d
// Register concrete class
container.register!ExampleClass;
// Register by interface
container.register!(ExampleInterface, ExampleClass);
```
In the above example, dependencies on the concrete class and interface will resolve an instance of class ExampleClass. Registering a class by interface does not automatically register by concrete type.

###Resolving dependencies
To manually resolve a dependency, all you have to do is resolve the dependency's type using the container in which it is registered:
```d
auto exampleClassInstance = container.resolve!ExampleClass;
```
If the class is registered by interface and not by concrete type, you cannot resolve the class by concrete type. Registration of both a concrete type and interface type will resolve different registrations, returning different instances:

```d
auto exampleClassInstance = container.resolve!ExampleClass;
auto exampleClassInstance2 = container.resolve!ExampleInterface;
assert(exampleClassInstance !is exampleClassInstance2);
```

###Dependency scopes
With dependency scopes, you can control how a dependency is resolved. The scope determines which instance is returned, be it the same each time or a new one. The following scopes are available:

* Resolve a dependency using a single instance (default):

```d
container.register!(ExampleClass).singleInstance();
```
* Resolve a dependency with a new instance each time it is resolved:

```d
container.register!(ExampleClass).newInstance();
```
* Resolve a dependency using a pre-existing instance

```d
auto preExistingInstance = new ExampleClass();
container.register!(ExampleClass).existingInstance(preExistingInstance);
```

###Autowiring
The real value of any dependency injection framework comes from its ability to autowire dependencies. Poodinis supports autowiring by simply applying the **@Autowire** UDA to a member of a class:
```d
class ExampleClassA {}

class ExampleClassB {
	@Autowire
	public ExampleClassA dependency;
}

container.register!ExampleClassA;
auto exampleInstance = new ExampleClassB();
container.autowire(exampleInstance);
assert(exampleInstance.dependency !is null);
```
At the moment, it is only possible to autowire public members or properties.

Dependencies are automatically autowired when a class is resolved. So when you register ExampleClassB, its member, *dependency*, is automatically autowired:
```d
container.register!ExampleClassA;
container.register!ExampleClassB;
auto instance = container.resolve!ExampleClassB;
assert(instance.dependency !is null);
```
If an interface is to be autowired, you must register a concrete class by interface. Any class registered by concrete type can only be injected when a dependency on a concrete type is autowired.

###Circular dependencies
Poodinis can autowire circular dependencies when they are registered with singleInstance or existingInstance registration scopes. Circular dependencies in registrations with newInstance scopes will not be autowired, as this would cause an endless loop.

###Registering and resolving using qualifiers
You can register multiple concrete types to a super type. When doing so, you will need to specify a qualifier when resolving that type:
```d
// Color is an interface, Blue and Red are classes implementing that interface
container.register!(Color, Blue);
container.register!(Color, Red);
auto blueInstance = container.resolve!(Color, Blue);
```
If you want to autowire a type registered to multiple concrete types, specify a qualified type as template argument:
```d
class BluePaint {
	@Autowire!Blue
	public Color color;
}
```
If you registered multiple concrete types to the same supertype and you do not resolve using a qualifier, a ResolveException is thrown stating that there are multiple candidates for the type to be resolved.

Known issues
------------
None! Found one? Let us know on github.

Future Work
-----------
* Thread safety
* Component scan (auto-registration)

[Spring Framework]: http://projects.spring.io/spring-framework/
[Hypodermic]: https://code.google.com/p/hypodermic/
[DUB]: http://code.dlang.org/
[DUB project page]: http://code.dlang.org/packages/poodinis
