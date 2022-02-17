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
 * Copyright: Copyright Digital Mars 2005 - 2009., Copyright Andrei Alexandrescu 2008-, Jonathan M Davis 2011-., 2014-2022 Mike Bierlee
 * License:  $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module poodinis.polyfill;

import std.exception;

static if (!__traits(compiles, basicExceptionCtors))
{
    mixin template basicExceptionCtors()
    {
        /++
            Params:
                msg  = The message for the exception.
                file = The file where the exception occurred.
                line = The line number where the exception occurred.
                next = The previous exception in the chain of exceptions, if any.
        +/
        this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow
        {
            super(msg, file, line, next);
        }

        /++
            Params:
                msg  = The message for the exception.
                next = The previous exception in the chain of exceptions.
                file = The file where the exception occurred.
                line = The line number where the exception occurred.
        +/
        this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) @nogc @safe pure nothrow
        {
            super(msg, file, line, next);
        }
    }
}
else
{
    public import std.exception : basicExceptionCtors;
}
