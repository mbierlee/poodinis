/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2016 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.exception;

version(unittest) {
	class Dependency {}

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

	class ConfigWithDefaults {
		@Value("conf.missing")
		int noms = 9;
	}

	class ConfigWithMandatory {
		@MandatoryValue("conf.mustbethere")
		int nums;
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

	// Test injection of values with defaults
	unittest {
		auto container = new shared DependencyContainer();
		container.register!ConfigWithDefaults;

		class IntInjector : ValueInjector!int {
			public override int get(string key) {
				throw new ValueNotAvailableException(key);
			}
		}

		container.register!(ValueInjector!int, IntInjector);

		auto instance = container.resolve!ConfigWithDefaults;
		assert(instance.noms == 9);
	}

	// Test mandatory injection of values which are available
	unittest {
		auto container = new shared DependencyContainer();
		container.register!ConfigWithMandatory;

		class IntInjector : ValueInjector!int {
			public override int get(string key) {
				return 7466;
			}
		}

		container.register!(ValueInjector!int, IntInjector);

		auto instance = container.resolve!ConfigWithMandatory;
		assert(instance.nums == 7466);
	}

	// Test mandatory injection of values which are not available
	unittest {
		auto container = new shared DependencyContainer();
		container.register!ConfigWithMandatory;

		class IntInjector : ValueInjector!int {
			public override int get(string key) {
				throw new ValueNotAvailableException(key);
			}
		}

		container.register!(ValueInjector!int, IntInjector);

		assertThrown!ResolveException(container.resolve!ConfigWithMandatory);
		assertThrown!ValueInjectionException(autowire(container, new ConfigWithMandatory()));
	}

	// Test injecting dependencies within value injectors
	unittest {
		auto container = new shared DependencyContainer();
		auto dependency = new Dependency();
		container.register!Dependency.existingInstance(dependency);

		class IntInjector : ValueInjector!int {

			@Autowire
			public Dependency dependency;

			public override int get(string key) {
				return 2345;
			}
		}

		container.register!(ValueInjector!int, IntInjector);
		auto injector = cast(IntInjector) container.resolve!(ValueInjector!int);

		assert(injector.dependency is dependency);
	}

	// Test injecting circular dependencies within value injectors
	unittest {
		auto container = new shared DependencyContainer();

		class IntInjector : ValueInjector!int {

			@Autowire
			public ValueInjector!int dependency;

			private int count = 0;

			public override int get(string key) {
				count += 1;
				if (count >= 3) {
					return count;
				}
				return dependency.get(key);
			}
		}

		container.register!(ValueInjector!int, IntInjector);
		auto injector = cast(IntInjector) container.resolve!(ValueInjector!int);

		assert(injector.dependency is injector);
		assert(injector.get("whatever") == 3);
	}

	// Test value injection within value injectors
	unittest {
		auto container = new shared DependencyContainer();

		class IntInjector : ValueInjector!int {

			@Value("five")
			public int count = 0;

			public override int get(string key) {
				if (key == "five") {
					return 5;
				}

				return count;
			}
		}

		container.register!(ValueInjector!int, IntInjector);
		auto injector = cast(IntInjector) container.resolve!(ValueInjector!int);

		assert(injector.count == 5);
	}

	// Test value injection within dependencies of value injectors
	unittest {
		auto container = new shared DependencyContainer();
		container.register!ConfigWithDefaults;

		class IntInjector : ValueInjector!int {

			@Autowire
			public ConfigWithDefaults config;

			public override int get(string key) {
				if (key == "conf.missing") {
					return 8899;
				}

				return 0;
			}
		}

		container.register!(ValueInjector!int, IntInjector);
		auto injector = cast(IntInjector) container.resolve!(ValueInjector!int);

		assert(injector.config.noms == 8899);
	}
}
