/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2021 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

class Violin {
}

interface InstrumentPlayer {
}

class ViolinPlayer : InstrumentPlayer {
	// Autowired concrete types can be registered on resolve
	@Autowire
	private Violin violin;
}

class Orchestra {
	// Autowired non-concrete types can be registered on resolved, given they have a qualifier.
	@Autowire!ViolinPlayer
	private InstrumentPlayer violinPlayer;
}

void main() {
	auto dependencies = new shared DependencyContainer();

	/*
	 * By using the resolve option "registerBeforeResolving" you can register the resolved class
	 * immediately. Note that any autowired member will not automatically be registered as well.
	 */
	auto violinPlayer = dependencies.resolve!Violin(ResolveOption.registerBeforeResolving);

	/*
	 * You can make the resolve option persistent by setting it on the container with setPersistentResolveOptions().
	 * This will register all resolved types and their autowired members (recursively).
	 * Note that you will still get ResolveExceptions when a non-concrete type is autowired (without qualifier).
	 * In those cases you will still have to register those particular dependencies beforehand.
	 */
	dependencies.setPersistentResolveOptions(ResolveOption.registerBeforeResolving);
	auto orchestra = dependencies.resolve!Orchestra;
}
