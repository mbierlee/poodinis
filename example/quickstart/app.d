/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2026 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

class Driver {
}

interface Database {
}

class RelationalDatabase : Database {
	private Driver driver;

	this(Driver driver) { // Automatically injected on creation by container
		this.driver = driver;
	}
}

class DataWriter {
	@Inject private Database database; // Automatically injected when class is resolved
}

void main() {
	auto dependencies = new shared DependencyContainer();
	dependencies.register!Driver;
	dependencies.register!DataWriter;
	dependencies.register!(Database, RelationalDatabase);

	auto writer = dependencies.resolve!DataWriter;
}
