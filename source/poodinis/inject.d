/**
 * An analogue to JSR330
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2025 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.inject;

import poodinis.autowire : Autowire;

/** 
 * UDA for annotating class members as candidates for injection.
 *
 * See_Also: Autowire
 */
alias Inject = Autowire;
