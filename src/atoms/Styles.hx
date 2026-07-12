package atoms;

import flixel.text.FlxText;
import flixel.util.FlxColor;

class Styles
{
	public static function makeLabel(text:String, x:Float, y:Float, width:Float, fontSize:Int = 12, ?color:FlxColor):FlxText
	{
		var t = new FlxText(x, y, width, text, fontSize);
		t.setFormat(Paths.font("vcr.ttf"), fontSize, color != null ? color : FlxColor.WHITE);
		t.scrollFactor.set(0, 0);
		return t;
	}

	public static function makeInfoLabel(text:String, x:Float, y:Float, width:Float, fontSize:Int = 10):FlxText
	{
		var t = makeLabel(text, x, y, width, fontSize, FlxColor.WHITE);
		return t;
	}

	public static function makeHeaderLabel(text:String, x:Float, y:Float, width:Float, fontSize:Int = 14):FlxText
	{
		var t = makeLabel(text, x, y, width, fontSize, FlxColor.WHITE);
		return t;
	}
}
