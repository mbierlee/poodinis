/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2015 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.stdio;

class TownSquare {

	@Autowire
	public MarketStall marketStall;

	public void makeSound() {
		marketStall.announceGoodsForSale();
	}

}

interface Goods {
	public string getGoodsName();
}

class Fish : Goods {
	public override string getGoodsName() {
		return "Fish";
	}
}

class MarketStall {
	private Goods goods;

	this(Goods goods) {
		this.goods = goods;
	}

	public void announceGoodsForSale() {
		writeln(goods.getGoodsName() ~ " for sale!");
	}
}

class ExampleApplicationContext : ApplicationContext {

	@Autowire
	public Goods goods;

	public override void registerDependencies(shared(DependencyContainer) container) {
		container.register!(Goods, Fish);
		container.register!TownSquare;
	}

	@Component
	public MarketStall marketStall() {
		return new MarketStall(goods);
	}

}

void main() {
	auto container = DependencyContainer.getInstance();
	container.registerContext!ExampleApplicationContext;

	auto townSquare = container.resolve!TownSquare;
	townSquare.makeSound();
}
