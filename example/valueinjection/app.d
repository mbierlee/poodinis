/**
 * Poodinis Dependency Injection Framework
 * Copyright 2014-2018 Mike Bierlee
 * This software is licensed under the terms of the MIT license.
 * The full terms of the license can be found in the LICENSE file.
 */

import poodinis;

import std.stdio;
import std.string;

class IntValueInjector : ValueInjector!int {
	int get(string key) {
		switch(key) {
			case "http.port":
				return 8080;
			case "http.keep_alive":
				return 60;
			default:
				throw new ValueNotAvailableException(key);
		}
	}
}

class StringValueInjector : ValueInjector!string {
	string get(string key) {
		switch(key) {
			case "http.hostname":
				return "acme.org";
			default:
				throw new ValueNotAvailableException(key);
		}
	}
}

class HttpServer {

	@Value("http.port")
	private int port = 80;

	@Value("http.hostname")
	private string hostName = "localhost";

	@Value("http.max_connections")
	private int maxConnections = 1000; // Default assignment is kept because max_connections is not available within the injector

	@MandatoryValue("http.keep_alive")
	private int keepAliveTime; // A ResolveException is thrown when the value is not available, default assignments are not used.

	public void serve() {
		writeln(format("Serving pages for %s:%s with max connection count of %s", hostName, port, maxConnections));
	}
}

void main() {
	auto dependencies = new shared DependencyContainer();
	dependencies.register!(ValueInjector!int, IntValueInjector);
	dependencies.register!(ValueInjector!string, StringValueInjector);
	dependencies.register!HttpServer;

	auto server = dependencies.resolve!HttpServer;
	server.serve(); // Prints "Serving pages for acme.org:8080 with max connection count of 1000"
}
