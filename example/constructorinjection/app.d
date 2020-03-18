/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2020 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

class Scheduler {
	private Calendar calendar;

	// All parameters will autmatically be assigned when Scheduler is created.
	this(Calendar calendar) {
		this.calendar = calendar;
	}

	public void scheduleJob() {
		calendar.findOpenDate();
	}

}

class Calendar {
	private HardwareClock hardwareClock;

	// This constructor contains built-in type "int" and thus will not be used.
	this(int initialDateTimeStamp, HardwareClock hardwareClock) {
	}

	// This constructor is chosen instead as candidate for injection when Calendar is created.
	this(HardwareClock hardwareClock) {
		this.hardwareClock = hardwareClock;
	}

	public void findOpenDate() {
		hardwareClock.doThings();
	}
}

import std.stdio;

class HardwareClock {
	// Parameterless constructors will halt any further selection of constructors.
	this() {
		writeln("default constructor");
	}	
	
	this(string name) {
		writeln(name);
	}

	// As a result, this constructor will not be used when HardwareClock is created.
	this(Calendar calendar) {
		throw new Exception("This constructor should not be used by Poodinis");
	}

	public void doThings() {
		writeln("Things are being done!");
	}
}

void main() {
	import poodinis; // Locally imported to emphasize that classes do not depend on Poodinis.

	auto dependencies = new shared DependencyContainer();
	dependencies.register!Scheduler;
	dependencies.register!Calendar;
	dependencies.register!HardwareClock( {
		writeln("Running the creator");
		return new HardwareClock("clock name");
	});

	auto scheduler = dependencies.resolve!Scheduler;
	scheduler.scheduleJob();
}
