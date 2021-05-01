/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2021 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.stdio;

interface Engine
{
	public void engage();
}

class FuelEngine : Engine
{
	public void engage()
	{
		writeln("VROOOOOOM!");
	}
}

class ElectricEngine : Engine
{
	public void engage()
	{
		writeln("hummmmmmmm....");
	}
}

class HybridCar
{
	alias KilometersPerHour = int;

	@Autowire!FuelEngine private Engine fuelEngine;

	@Autowire!ElectricEngine private Engine electricEngine;

	public void moveAtSpeed(KilometersPerHour speed)
	{
		if (speed <= 45)
		{
			electricEngine.engage();
		}
		else
		{
			fuelEngine.engage();
		}
	}
}

void main()
{
	auto dependencies = new shared DependencyContainer();

	dependencies.register!HybridCar;
	dependencies.register!(Engine, FuelEngine);
	dependencies.register!(Engine, ElectricEngine);

	auto car = dependencies.resolve!HybridCar;

	car.moveAtSpeed(10); // Should print "hummmmmmmm...."
	car.moveAtSpeed(50); // Should print "VROOOOOOM!"
}
