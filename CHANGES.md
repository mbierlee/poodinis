Poodinis Changelog
==================
**Version 6.1.0**
* ADD setting persistent registration and resolve options
* DEPRECATE DO_NOT_ADD_CONCRETE_TYPE_REGISTRATION, use doNotAddConcreteTypeRegistration instead
* DEPRECATE supplying register()'s registration options as variadic arguments. Use register(SuperType, ConcreteType)(RegistrationOption[]) instead.
* ADD resolve options to container resolve()
* ADD ability to register a type while resolving it. Use resolve option registerBeforeResolving
* ADD ability to autowire private fields (Thanks to Extrawurst)
* FIX registration of application contexts with non-public members

**Version 6.0.0**
* CHANGE registration scopes are replaced by a single factory implementation. If you were not doing anything with the internal scope mechanism, you 
should not be affected by this change.
* ADD application contexts. You can register dependencies within an application context which allow you to fine-tune the creation of dependency instances.
* CHANGE all public poodinis imports to private. This should not affect you if you use the package import "poodinis" instead of individual modules.
* REMOVE deprecated ADD_CONCRETE_TYPE_REGISTRATION registration option.
* REMOVE deprecated RegistrationOptions alias.

**Version 5.0.0**
* DEPRECATE ADD_CONCRETE_TYPE_REGISTRATION registration option. It basically does nothing anymore. See next point.
* CHANGE adding registrations by super type always registers them by concrete type as well now. (Previously done with ADD_CONCRETE_TYPE_REGISTRATION). See DO_NOT_ADD_CONCRETE_TYPE_REGISTRATION for the reverse behaviour.
* CHANGE RegistrationOptions enum name to RegistrationOption
* DEPRECATE Usage of RegistrationOptions, please use RegistrationOption instead.

**Version 4.0.0**
* REMOVE deprecated module "dependency.d"

**Version 3.0.0**  
This version is only compatible with DMD 2.068.0 or higher!
* ADD UDA which always resolved a new instance to an autowired member, regardless of registration scope.

**Version 2.2.0**
* ADD canonical package module "package.d". Use "import poodinis;" to import the project.
* DEPRECATE module "dependency.d". Please use the canonical package module. See previous point.
* ADD autowiring of dynamic arrays. All registered instances of the element type of the array will be assigned to it.

**Version 2.1.0**
* ADD option for registering a class by concrete type when registering that class by supertype.

**Version 2.0.0**  
This version introduces changes which might be incompatible with your current codebase
* CHANGE dependency container to be synchronized. Sharing a dependency container between threads is now possible.
The implication is that all dependency container instances must be shared now.
You don't have to change anything if you were only using the singleton dependency container.

**Version 1.0.0**  
This version introduces changes which are incompatible with previous versions
* REMOVE deprecated autowire constructor
* REMOVE deprecated container alias
* ADD documentation for public API
* REMOVE @Autowired UDA. Use @Autowire instead.
* ADD quickstart from readme to compilable example project.
* ADD example project for the use of qualifiers

**Version 0.3.1**
* FIX issue where autowiring members which are declared by interface or supertype would get autowired incorrectly.

**Version 0.3.0**
* ADD alternative workaround to readme for autowire limitation
* CHANGE returning of resolved instances by returning them by qualifier type instead
* ADD debug specifier to reduce verbosity of debug output

**Version 0.2.0**
* ADD ability to register type with multiple concrete types. They can be correctly resolved using qualifiers.
* DEPRECATE template for autowiring in constructor. This workaround is buggy. Use qualifiers instead.

**Version 0.1.4**
* Make Poodinis compatible with D 2.066.0 and DUB 0.9.22
* FIX incorrect clearing of registrations  
This release should be backwards compatible with the previous versions of D and DUB, but please note that there are no more separate
configurations for release and debug builds. You have to specify a build type in DUB.

**Version 0.1.3**
* ADD global autowire function for convenience
* CHANGE workaround to be more simple
* FIX autowiring classes which contain non-symbolic declarations such as aliases. As a result, only variables are attempted to be autowired.

**Version 0.1.2**
* ADD workaround for failing to autowire types registered by supertype or interface

**Version 0.1.1**
* FIX: Also auto-wire members from base classes

**Version 0.1.0**
* Initial open-source release
* ADD support for registering and resolving
* ADD registration scopes
* ADD autowiring
