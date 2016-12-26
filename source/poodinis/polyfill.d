/**
 * Forward-compatibility module for providing support for Phobos functionality
 * not available in older versions of Phobos.
 *
 * Should not implement functionalitiy which is gone from the latest Phobos.
 *
 * Implementations copied/re-implemented from std.exception
 *
 * The baseline compatibility is D/Phobos 2.068.2
 *
 * Authors: $(HTTP erdani.org, Andrei Alexandrescu),
 *   Jonathan M Davis,
 *   Mike Bierlee (m.bierlee@lostmoment.com)
 * Copyright: Copyright Andrei Alexandrescu 2008-, Jonathan M Davis 2011-., 2014-2016 Mike Bierlee
 * License:  $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module poodinis.polyfill;

import std.exception;

static if (!__traits(compiles, basicExceptionCtors)) {
	mixin template basicExceptionCtors()
	{
		this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow
		{
			super(msg, file, line, next);
		}

		this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) @safe pure nothrow
		{
			super(msg, file, line, next);
		}
	}
}
