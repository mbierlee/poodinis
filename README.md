Poodinis Dependency Injection Framework
=======================================
Version 0.1  
Copyright 2014 Mike bierlee  
Licensed under the terms of the MIT license - See [LICENSE.txt](LICENSE.txt)

Poodinis is a dependency injection framework for the D programming language. It is inspired by the [Spring Framework] and [Hypodermic] IoC container for C++. Poodinis supports registering and resolving classes either by concrete type or interface. Automatic injection of dependencies is supported through the use of UDAs (Referred to as autowiring).

Uses D 2.065.0 and Phobos.

History
-------
For a full overview of changes, see [CHANGES.md](CHANGES.md)

Getting started
---------------
###DUB Dependency
Poodinis can be included in a project using [DUB]:
```json
{
  "dependencies": {
    "poodinis": "0.1"
  }
}
```
###Quickstart
The following example shows the typical usage of Poodinis:
```d
import poodinis.container; // The only import needed for now

interface Database{};
class RelationalDatabase : Database {}

class DataWriter {
	@Autowire
	public Database database; // Automatically injected when class is resolved
}

void main() {
	auto container = Container.getInstance();
	container.register!DataWriter;
	container.register!(Database, RelationalDatabase);
	
	auto writer = container.resolve!DataWriter;
}
```

### The container
To register a class, a new dependency container must be instantiated:
```d
// Register a private container
auto container = new Container();
// Or use the singleton container
container = Container.getInstance();
```
###Registering dependencies
They make dependencies available, they have to be registered:
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
container.autowire!ExampleClassB(exampleInstance);
assert(exampleInstance.dependency !is null);
```
At the moment, it is only possible to autowire public members or properties.

Dependencies are automatically autowired when a class is resolved. So when you register ExampleClassB, its member, *dependency*, is automatically injected:
```d
container.register!ExampleClassA;
container.register!ExampleClassB;
auto instance = container.resolve!ExampleClassB;
assert(instance.dependency !is null);
```
If an interface is to be autowired, you must register a concrete class by interface. Any class registered by concrete type can only be injected when a dependency on a concrete type is autowired.

###Circular dependencies
Poodinis can autowire circular dependencies when they are registered with singleInstance or existingInstance registration scopes. See Known issues for the limitations on newInstance scopes. 

Known issues
------------
* Due to preventive measures of recursion issues in circular dependencies, registrations which are supposed to yield new instances will not autowire classes for which a circular dependency is detected. A new instance will be resolved but the instance's members will not be autowired. 

Future Work
-----------
* Thread safety
* Component scan (auto-registration)

[Spring Framework]: http://projects.spring.io/spring-framework/
[Hypodermic]: https://code.google.com/p/hypodermic/
[DUB]: http://code.dlang.org/
