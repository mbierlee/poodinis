Poodinis Tutorial
=================
This tutorial will give you an overview of all functionality offered by Poodinis and how to use them.

The container
-------------
To register a class, a new dependency container must be instantiated:
```d
// Register a private container
auto dependencies = new DependencyContainer();
// Or use the singleton container
dependencies = DependencyContainer.getInstance();
```
###Registering dependencies
To make dependencies available, they have to be registered:
```d
// Register concrete class
dependencies.register!ExampleClass;
// Register by interface
dependencies.register!(ExampleInterface, ExampleClass);
```
In the above example, dependencies on the concrete class and interface will resolve an instance of class ExampleClass. Registering a class by interface does not automatically register by concrete type.

Resolving dependencies
----------------------
To manually resolve a dependency, all you have to do is resolve the dependency's type using the container in which it is registered:
```d
auto exampleClassInstance = dependencies.resolve!ExampleClass;
```
If the class is registered by interface and not by concrete type, you can still resolve the class by concrete type:

```d
auto exampleClassInstance = dependencies.resolve!ExampleInterface;
auto exampleClassInstance2 = dependencies.resolve!ExampleClass;
assert(exampleClassInstance is exampleClassInstance2);
```
If you want to prevent registrations from being both registered by interface and concrete type, use the DO_NOT_ADD_CONCRETE_TYPE_REGISTRATION option when registering:
```d
dependencies.register!(ExampleInterface, ExampleClass)(RegistrationOptions.DO_NOT_ADD_CONCRETE_TYPE_REGISTRATION);
auto exampleClassInstance = dependencies.resolve!ExampleInterface;
auto exampleClassInstance2 = dependencies.resolve!ExampleClass; // A ResolveException is thrown
```

Dependency creation behaviour
-----------------
You can control how a dependency is resolved by specifying a creation scope during registration. The scope determines which instance is returned, be it the same each time or a new one. The following scopes are available:

* Resolve a dependency using a single instance (default):

```d
dependencies.register!(ExampleClass).singleInstance();
```
* Resolve a dependency with a new instance each time it is resolved:

```d
dependencies.register!(ExampleClass).newInstance();
```
* Resolve a dependency using a pre-existing instance

```d
auto preExistingInstance = new ExampleClass();
dependencies.register!(ExampleClass).existingInstance(preExistingInstance);
```

Autowiring
----------
The real value of any dependency injection framework comes from its ability to autowire dependencies. Poodinis supports autowiring by simply applying the **@Autowire** UDA to a member of a class:
```d
class ExampleClassA {}

class ExampleClassB {
	@Autowire
	public ExampleClassA dependency;
}

dependencies.register!ExampleClassA;
auto exampleInstance = new ExampleClassB();
dependencies.autowire(exampleInstance);
assert(exampleInstance.dependency !is null);
```
At the moment, it is only possible to autowire public members or properties.

Dependencies are automatically autowired when a class is resolved. So when you register ExampleClassB, its member, *dependency*, is automatically autowired:
```d
dependencies.register!ExampleClassA;
dependencies.register!ExampleClassB;
auto instance = dependencies.resolve!ExampleClassB;
assert(instance.dependency !is null);
```
If an interface is to be autowired, you must register a concrete class by interface. Any class registered by concrete type can only be injected when a dependency on a concrete type is autowired.

Circular dependencies
---------------------
Poodinis can autowire circular dependencies when they are registered with singleInstance or existingInstance registration scopes. Circular dependencies in registrations with newInstance scopes will not be autowired, as this would cause an endless loop.

Registering and resolving using qualifiers
------------------------------------------
You can register multiple concrete types to a super type. When doing so, you will need to specify a qualifier when resolving that type:
```d
// Color is an interface, Blue and Red are classes implementing that interface
dependencies.register!(Color, Blue);
dependencies.register!(Color, Red);
auto blueInstance = dependencies.resolve!(Color, Blue);
```
If you want to autowire a type registered to multiple concrete types, specify a qualified type as template argument:
```d
class BluePaint {
	@Autowire!Blue
	public Color color;
}
```
If you registered multiple concrete types to the same supertype and you do not resolve using a qualifier, a ResolveException is thrown stating that there are multiple candidates for the type to be resolved.

Autowiring all registered instances to an array
-----------------------------------------------
If you have registered multiple concrete types to a super type, you can autowire them all to an array, in which case you can easily operate on them all:
```d
// Color is an interface, Blue and Red are classes implementing that interface

class ColorMixer {
	@Autowire
	public Color[] colors;
}

dependencies.register!(Color, Blue);
dependencies.register!(Color, Red);
auto mixer = dependencies.resolve!ColorMixer;
```
Member mixer.colors will now contain instances of Blue and Red. The order of the instances is not guarenteed to be that of the order in which they were registered.
