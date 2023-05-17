/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2023 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.stdio;

class TownSquare {
	@Inject private MarketStall marketStall;

	void makeSound() {
		marketStall.announceGoodsForSale();
	}
}

interface Goods {
	string getGoodsName();
}

class Fish : Goods {
	override string getGoodsName() {
		return "Fish";
	}
}

class MarketStall {
	private Goods goods;

	this(Goods goods) {
		this.goods = goods;
	}

	void announceGoodsForSale() {
		writeln(goods.getGoodsName() ~ " for sale!");
	}
}

class ExampleApplicationContext : ApplicationContext {
	@Inject private Goods goods;

	override void registerDependencies(shared(DependencyContainer) container) {
		container.register!(Goods, Fish);
		container.register!TownSquare;
	}

	@Component MarketStall marketStall() {
		return new MarketStall(goods);
	}
}

void main() {
	auto container = new shared DependencyContainer();
	container.registerContext!ExampleApplicationContext;

	auto townSquare = container.resolve!TownSquare;
	townSquare.makeSound();
}
