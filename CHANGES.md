Poodinis Changelog
==================
**Version 1.0.0**
This version introduces changes which are incompatible with previous versions

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
