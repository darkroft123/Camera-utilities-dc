package templates;

import flixel.FlxG;

class EditorLayout
{
	public static inline var TOPBAR_HEIGHT:Int = 30;
	public static inline var TIMELINE_HEIGHT:Int = 320;
	public static inline var ROW_SIZE_X:Float = 20.0;
	public static inline var ROW_SIZE_Y:Float = 20.0;
	public static inline var LIST_COL_W:Int = 192;
	public static inline var VALUES_COL_W:Int = 0;
	public static inline var EDIT_COL_W:Int = 320;
	public static inline var SEP_W:Int = 2;
	public static var GRID_COL_X(get, never):Float;
	static function get_GRID_COL_X():Float return LIST_COL_W + VALUES_COL_W + EDIT_COL_W + (SEP_W * 3);
	public static var GRID_COL_W(get, never):Int;
	static function get_GRID_COL_W():Int return Std.int(FlxG.width - GRID_COL_X);

	public static var timelineWindowY(get, never):Float;
	static function get_timelineWindowY():Float return FlxG.height - TIMELINE_HEIGHT;

	public static var timelineCamY(get, never):Float;
	static function get_timelineCamY():Float return timelineWindowY + TOPBAR_HEIGHT;

	public static var timelineCamH(get, never):Float;
	static function get_timelineCamH():Float return FlxG.height - timelineCamY;

	public static inline var editorCamScale:Float = 0.5;

	public static function previewCamX(scale:Float):Float
	{
		return (FlxG.width - FlxG.width * scale) * 0.5;
	}

	public static function previewCamY(scale:Float):Float
	{
		var previewH = FlxG.height - TIMELINE_HEIGHT;
		return (previewH - previewH * scale) * 0.5;
	}

	public static var editorPreviewH(get, never):Float;
	static function get_editorPreviewH():Float return FlxG.height - TIMELINE_HEIGHT;
}
