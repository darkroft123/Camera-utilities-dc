package camera;

typedef ModifierEntry = {
	var name:String;
	var modifier:String;
	var value:Float;
	@:optional var duration:Int;
	@:optional var ease:String;
	var type:String; // "set" | "tween"
}

typedef TimelineModifierPlacement = {
	var modifierRef:String;
	var value:Float;
	var type:String; // "set" | "tween"
	@:optional var duration:Int;
	@:optional var ease:String;
	var beat:Int;
}

typedef CameraEventsSaveData = {
	var modifiers:Array<ModifierEntry>;
	var placements:Array<TimelineModifierPlacement>;
}
