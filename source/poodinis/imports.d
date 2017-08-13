module poodinis.imports;

import std.traits;

public static string createImportsString(Type)() {
	string imports = `import ` ~ moduleName!Type ~ `;`;
	static if (__traits(compiles, TemplateArgsOf!Type)) {
		foreach(TemplateArgType; TemplateArgsOf!Type) {
			static if (!isBuiltinType!TemplateArgType) {
				imports ~= createImportsString!TemplateArgType;
			}
		}
	}

	return imports;
}