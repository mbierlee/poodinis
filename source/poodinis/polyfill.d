/**
 * Forward-compatibility module for providing support for Phobos functionality
 * not available in older versions of Phobos.
 *
 * Should not implement functionalitiy which is gone from the latest Phobos.
 *
 * Implementations copied/re-implemented from std.exception and std.traits;
 *
 * The baseline compatibility is D/Phobos 2.068.2
 *
 * Authors: $(HTTP erdani.org, Andrei Alexandrescu),
 *            Jonathan M Davis,
 *            $(HTTP digitalmars.com, Walter Bright),
 *            Tomasz Stachowiak ($(D isExpressions)),
 *            $(HTTP erdani.org, Andrei Alexandrescu),
 *            Shin Fujishiro,
 *            $(HTTP octarineparrot.com, Robert Clipsham),
 *            $(HTTP klickverbot.at, David Nadlinger),
 *            Kenji Hara,
 *            Shoichi Kato,
 *            Mike Bierlee (m.bierlee@lostmoment.com)
 * Copyright: Copyright Digital Mars 2005 - 2009., Copyright Andrei Alexandrescu 2008-, Jonathan M Davis 2011-., 2014-2020 Mike Bierlee
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

static if (!__traits(compiles, isFunction)) {
    template isFunction(X...) if (X.length == 1)
    {
        static if (is(typeof(&X[0]) U : U*) && is(U == function) ||
                    is(typeof(&X[0]) U == delegate))
        {
            // x is a (nested) function symbol.
            enum isFunction = true;
        }
        else static if (is(X[0] T))
        {
            // x is a type.  Take the type of it and examine.
            enum isFunction = is(T == function);
        }
        else
            enum isFunction = false;
    }
}
