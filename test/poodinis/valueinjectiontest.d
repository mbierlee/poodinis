/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2023 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;
import poodinis.test.testclasses;

import std.exception;

version (unittest) {

    struct LocalStruct {
        bool wasInjected = false;
    }

    class LocalStructInjector : ValueInjector!LocalStruct {
        public override LocalStruct get(string key) {
            auto data = LocalStruct(true);
            return data;
        }
    }

    class LocalClassWithStruct {
        @Value("")
        public LocalStruct localStruct;
    }

    // Test injection of values
    unittest {
        auto container = new shared DependencyContainer();
        container.register!MyConfig;
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
        container.register!(ValueInjector!int, DefaultIntInjector);

        auto instance = container.resolve!ConfigWithDefaults;
        assert(instance.noms == 9);
    }

    // Test mandatory injection of values which are available
    unittest {
        auto container = new shared DependencyContainer();
        container.register!ConfigWithMandatory;
        container.register!(ValueInjector!int, MandatoryAvailableIntInjector);

        auto instance = container.resolve!ConfigWithMandatory;
        assert(instance.nums == 7466);
    }

    // Test mandatory injection of values which are not available
    unittest {
        auto container = new shared DependencyContainer();
        container.register!ConfigWithMandatory;
        container.register!(ValueInjector!int, MandatoryUnavailableIntInjector);

        assertThrown!ResolveException(container.resolve!ConfigWithMandatory);
        assertThrown!ValueInjectionException(autowire(container, new ConfigWithMandatory()));
    }

    // Test injecting dependencies within value injectors
    unittest {
        auto container = new shared DependencyContainer();
        auto dependency = new Dependency();
        container.register!Dependency.existingInstance(dependency);
        container.register!(ValueInjector!int, DependencyInjectedIntInjector);
        auto injector = cast(DependencyInjectedIntInjector) container.resolve!(ValueInjector!int);

        assert(injector.dependency is dependency);
    }

    // Test injecting circular dependencies within value injectors
    unittest {
        auto container = new shared DependencyContainer();
        container.register!(ValueInjector!int, CircularIntInjector);
        auto injector = cast(CircularIntInjector) container.resolve!(ValueInjector!int);

        assert(injector.dependency is injector);
        assert(injector.get("whatever") == 3);
    }

    // Test value injection within value injectors
    unittest {
        auto container = new shared DependencyContainer();
        container.register!(ValueInjector!int, ValueInjectedIntInjector);
        auto injector = cast(ValueInjectedIntInjector) container.resolve!(ValueInjector!int);

        assert(injector.count == 5);
    }

    // Test value injection within dependencies of value injectors
    unittest {
        auto container = new shared DependencyContainer();
        container.register!ConfigWithDefaults;

        container.register!(ValueInjector!int, DependencyValueInjectedIntInjector);
        auto injector = cast(DependencyValueInjectedIntInjector) container.resolve!(
            ValueInjector!int);

        assert(injector.config.noms == 8899);
    }

    // Test resolving locally defined struct injector (github issue #20)
    unittest {
        auto container = new shared DependencyContainer();
        container.register!(ValueInjector!LocalStruct, LocalStructInjector);
        container.register!LocalClassWithStruct;

        auto injector = container.resolve!(ValueInjector!LocalStruct);
        assert(injector !is null);

        auto localClass = container.resolve!LocalClassWithStruct;
        assert(localClass.localStruct.wasInjected);
    }
}
