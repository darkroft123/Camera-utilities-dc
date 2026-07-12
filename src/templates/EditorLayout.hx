package templates;

import flixel.FlxG;

class EditorLayout
{
	public static inline var TOPBAR_HEIGHT:Int = 30;
	public static inline var MENU_Y:Float = 80;
	public static inline var MAX_VISIBLE_ACTIONS:Int = 8;

	public static var previewScale(get, never):Float;
	static function get_previewScale():Float return 0.5;

	public static var editorDefaultY(get, never):Float;
	static function get_editorDefaultY():Float return FlxG.height * 0.5 + 30;

	public static var leftPanelW:Int = 175;
	public static var leftPanelX:Int = 5;

	public static var midPanelX:Int = 185;
	public static var midPanelW:Int = 175;

	public static var rightPanelX(get, never):Float;
	static function get_rightPanelX():Float return midPanelX + midPanelW + 3;
	public static var rightPanelDefaultW(get, never):Int;
	static function get_rightPanelDefaultW():Int return Std.int(FlxG.width - rightPanelX - 5);
	public static var rightPanelDefaultH(get, never):Int;
	static function get_rightPanelDefaultH():Int return Std.int(FlxG.height - Std.int(editorDefaultY) - 30);

	public static var previewDefaultWidth(get, never):Int;
	static function get_previewDefaultWidth():Int return Std.int(FlxG.width * previewScale);
	public static var previewDefaultHeight(get, never):Int;
	static function get_previewDefaultHeight():Int return Std.int(FlxG.height * previewScale);

	public static function previewCenterX():Float
	{
		return (FlxG.width - previewDefaultWidth) * 0.5;
}

	public static function previewCenterY():Float
	{
		return 40.0;
	}
}
