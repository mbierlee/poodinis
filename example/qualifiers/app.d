/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2024 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.stdio;

interface Engine {
	void engage();
}

class FuelEngine : Engine {
	void engage() {
		writeln("VROOOOOOM!");
	}
}

class ElectricEngine : Engine {
	void engage() {
		writeln("hummmmmmmm....");
	}
}

class HybridCar {
	alias KilometersPerHour = int;

	@Inject!FuelEngine private Engine fuelEngine;

	@Inject!ElectricEngine private Engine electricEngine;

	void moveAtSpeed(KilometersPerHour speed) {
		if (speed <= 45) {
			electricEngine.engage();
		} else {
			fuelEngine.engage();
		}
	}
}

void main() {
	auto dependencies = new shared DependencyContainer();

	dependencies.register!HybridCar;
	dependencies.register!(Engine, FuelEngine);
	dependencies.register!(Engine, ElectricEngine);

	auto car = dependencies.resolve!HybridCar;

	car.moveAtSpeed(10); // Should print "hummmmmmmm...."
	car.moveAtSpeed(50); // Should print "VROOOOOOM!"
}
