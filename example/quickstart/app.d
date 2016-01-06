/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2016 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

interface Database{};
class RelationalDatabase : Database {}

class DataWriter {
	@Autowire
	public Database database; // Automatically injected when class is resolved
}

void main() {
	auto dependencies = DependencyContainer.getInstance();
	dependencies.register!DataWriter;
	dependencies.register!(Database, RelationalDatabase);

	auto writer = dependencies.resolve!DataWriter;
}
