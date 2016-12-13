/**
 * Forward-compatibility module for providing support for Phobos functionality
 * not available in older versions of Phobos.
 *
 * Should not implement functionalitiy which is gone from the latest Phobos.
 *
 * Implementations copied/re-implemented from std.traits, std.meta (std.typetuple)
 * and std.exception
 *
 * The baseline compatibility is D/Phobos 2.066.1
 *
 * Authors: $(HTTP erdani.org, Andrei Alexandrescu),
 *   Jonathan M Davis,
 *   $(HTTP digitalmars.com, Walter Bright),
 *   Tomasz Stachowiak ($(D isExpressions)),
 *   Shin Fujishiro,
 *   $(HTTP octarineparrot.com, Robert Clipsham),
 *   $(HTTP klickverbot.at, David Nadlinger),
 *   Kenji Hara,
 *   Shoichi Kato,
 *   Mike Bierlee (m.bierlee@lostmoment.com)
 * Copyright: Copyright Digital Mars 2005 - 2015, Copyright Andrei Alexandrescu 2008-, Jonathan M Davis 2011-., 2014-2016 Mike Bierlee
 * License:  $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module poodinis.polyfill;

import std.exception;
import std.traits;

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

static if (!__traits(compiles, enforce!Exception(true, "Message"))) {
	T enforce(E: Exception, T)(T value, string message) {
		if (value) {
			return value;
		}

		throw new E(message);
	}
}

static if (!__traits(compiles, FieldNameTuple)) {
	private enum NameOf(alias T) = T.stringof;

	template FieldNameTuple(T)
	{
		import std.typetuple : staticMap;
		static if (is(T == struct) || is(T == union))
			alias FieldNameTuple = staticMap!(NameOf, T.tupleof[0 .. $ - isNested!T]);
		else static if (is(T == class))
			alias FieldNameTuple = staticMap!(NameOf, T.tupleof);
		else
			alias FieldNameTuple = TypeTuple!"";
	}
}

static if (!__traits(compiles, hasUDA)) {
	template hasUDA(alias symbol, alias attribute)
	{
		public static bool hasUda() {
			foreach(uda; __traits(getAttributes, symbol)) {
				if (is(uda == attribute)) {
					return true;
				}
			}
			return false;
		}
		enum hasUDA = hasUda();
	}
}

static if (!__traits(compiles, Parameters)) {
	template Parameters(func...)
		if (func.length == 1 && isCallable!func)
	{
		static if (is(FunctionTypeOf!func P == function))
			alias Parameters = P;
		else
			static assert(0, "argument has no parameters");
	}
}
