/**
 * Tweaks to Phobos's standard templates.
 *
 * Implementations copied and adapted from std.traits;
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
 * Copyright: Copyright Digital Mars 2005 - 2009., Copyright Andrei Alexandrescu 2008-, Jonathan M Davis 2011-., 2014-2025 Mike Bierlee
 * License:  $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module poodinis.altphobos;

template isFunction(X...) {
    static if (X.length == 1) {
        static if (is(typeof(&X[0]) U : U*) && is(U == function) || is(typeof(&X[0]) U == delegate)) {
            // x is a (nested) function symbol.
            enum isFunction = true;
        } else static if (is(X[0] T)) {
            // x is a type.  Take the type of it and examine.
            enum isFunction = is(T == function);
        } else
            enum isFunction = false;
    } else {
        enum isFunction = false;
    }
}
