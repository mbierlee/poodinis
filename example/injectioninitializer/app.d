/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2023 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;
import std.stdio;

class Doohickey {
}

void main() {
    auto dependencies = new shared DependencyContainer();
    dependencies.register!Doohickey.initializedBy({
        writeln("Creating Doohickey via initializer delegate.");
        return new Doohickey();
    });

    dependencies.resolve!Doohickey;
}
