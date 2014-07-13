Poodinis Changelog
==================
**Version 0.1.3**
* ADD global autowire function for convinience
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
