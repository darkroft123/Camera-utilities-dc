package camera;

import pages.ModchartEditor;

typedef ModifierDefinition = {
	var id:String;
	var displayName:String;
	var defaultValue:Float;
	var apply:(value:Float, state:ModchartEditor) -> Void;
}

class ModifierRegistry
{
	public static var definitions:Map<String, ModifierDefinition> = new Map();

	public static function register(id:String, displayName:String, defaultValue:Float, apply:(value:Float, state:ModchartEditor) -> Void):Void
	{
		definitions.set(id, {
			id: id,
			displayName: displayName,
			defaultValue: defaultValue,
			apply: apply
		});
	}

	public static function applyModifier(id:String, value:Float, state:ModchartEditor):Void
	{
		if (definitions.exists(id))
			definitions.get(id).apply(value, state);
	}

	public static function getDefaultValue(id:String):Float
	{
		if (definitions.exists(id))
			return definitions.get(id).defaultValue;
		return 0.0;
	}
}
