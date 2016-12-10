/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2016 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.exception;

version(unittest) {
	struct Thing {
		int x;
	}

	class MyConfig {
		@Value("conf.stuffs")
		int stuffs;

		@Value("conf.name")
		string name;

		@Value("conf.thing")
		Thing thing;
	}

	// Test injection of values
	unittest {
		auto container = new shared DependencyContainer();
		container.register!MyConfig;

		class IntInjector : ValueInjector!int {
			public override int get(string key) {
				assert(key == "conf.stuffs");
				return 364;
			}
		}

		class StringInjector : ValueInjector!string {
			public override string get(string key) {
				assert(key == "conf.name");
				return "Le Chef";
			}
		}

		class ThingInjector : ValueInjector!Thing {
			public override Thing get(string key) {
				assert(key == "conf.thing");
				return Thing(8899);
			}
		}

		container.register!(ValueInjector!int, IntInjector);
		container.register!(ValueInjector!string, StringInjector);
		container.register!(ValueInjector!Thing, ThingInjector);

		auto instance = container.resolve!MyConfig;
		assert(instance.stuffs == 364);
		assert(instance.name == "Le Chef");
		assert(instance.thing.x == 8899);
	}

	// Test injection of values throws exception when injector is not there
	unittest {
		auto container = new shared DependencyContainer();
		container.register!MyConfig;
		assertThrown!ResolveException(container.resolve!MyConfig);

		assertThrown!ValueInjectionException(autowire(container, new MyConfig()));
	}
}
