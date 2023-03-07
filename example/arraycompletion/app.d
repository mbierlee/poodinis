/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2023 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.stdio;

interface Pie {
	public void eat();
}

class BlueBerryPie : Pie {
	public override void eat() {
		writeln("Nom nom nom. I like this one!");
	}
}

class ApplePie : Pie {
	public override void eat() {
		writeln("Nom nom nom. These aren't real apples...");
	}
}

class CardboardBoxPie : Pie {
	public override void eat() {
		writeln("Nom nom nom. This... is not a pie.");
	}
}

class PieEater {
	@Inject private Pie[] pies;

	public void eatThemAll() {
		foreach (pie; pies) {
			pie.eat();
		}
	}
}

void main() {
	auto dependencies = new shared DependencyContainer();
	dependencies.register!(Pie, BlueBerryPie);
	dependencies.register!(Pie, ApplePie);
	dependencies.register!(Pie, CardboardBoxPie);
	dependencies.register!(PieEater);

	auto eater = dependencies.resolve!PieEater;
	eater.eatThemAll();
}
