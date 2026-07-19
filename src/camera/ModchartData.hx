package camera;

typedef ModifierEntry = {
	var name:String;
	var modifier:String;
	var value:Float;
	@:optional var duration:Null<Float>;
	@:optional var ease:String;
	var type:String; // "set" | "tween"
}

typedef TimelineModifierPlacement = {
	var modifierRef:String;
	var value:Float;
	var type:String; // "set" | "tween"
	@:optional var duration:Null<Float>;
	@:optional var ease:String;
	var beat:Float;
	@:optional var repeat:Array<Dynamic>; // [bool_enabled, int_count, float_gap]
}

@:structInit class SongStartData
{
	@:optional public var eventName:String;
	public var modifierRef:String;
	public var value:Float;
	@:optional public var duration:Null<Float>;
	@:optional public var ease:String;
	public var type:String; // "set" | "tween"
}

typedef CameraEventsSaveData = {
	var modifiers:Array<ModifierEntry>;
	var placements:Array<TimelineModifierPlacement>;
	@:optional var songStart:SongStartData;
}
