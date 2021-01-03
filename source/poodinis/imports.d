/**
 * This module contains instance factory facilities
 *
 * Authors:
 *  Mike Bierlee, m.bierlee@lostmoment.com
 * Copyright: 2014-2021 Mike Bierlee
 * License:
 *  This software is licensed under the terms of the MIT license.
 *  The full terms of the license can be found in the LICENSE file.
 */

module poodinis.imports;

import std.meta;
import std.traits;

public static string createImportsString(Type, ParentTypeList...)() {
    string imports = `import ` ~ moduleName!Type ~ `;`;
    static if (__traits(compiles, TemplateArgsOf!Type)) {
        foreach(TemplateArgType; TemplateArgsOf!Type) {
            static if (!isBuiltinType!TemplateArgType && staticIndexOf!(TemplateArgType, ParentTypeList) == -1) {
                imports ~= createImportsString!(TemplateArgType, ParentTypeList, Type);
            }
        }
    }

    return imports;
}