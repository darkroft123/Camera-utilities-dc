package atoms;

class EaseUtils
{
	public static function fromName(name:String):(Float) -> Float
	{
		if (name == null) return flixel.tweens.FlxEase.linear;
		return switch (name.toLowerCase())
		{
			case "quadin": flixel.tweens.FlxEase.quadIn;
			case "quadout": flixel.tweens.FlxEase.quadOut;
			case "quadinout": flixel.tweens.FlxEase.quadInOut;
			case "cubein": flixel.tweens.FlxEase.cubeIn;
			case "cubeout": flixel.tweens.FlxEase.cubeOut;
			case "cubeinout": flixel.tweens.FlxEase.cubeInOut;
			case "quartin": flixel.tweens.FlxEase.quartIn;
			case "quartout": flixel.tweens.FlxEase.quartOut;
			case "quartinout": flixel.tweens.FlxEase.quartInOut;
			case "quintin": flixel.tweens.FlxEase.quintIn;
			case "quintout": flixel.tweens.FlxEase.quintOut;
			case "quintinout": flixel.tweens.FlxEase.quintInOut;
			case "expoin": flixel.tweens.FlxEase.expoIn;
			case "expoout": flixel.tweens.FlxEase.expoOut;
			case "expoinout": flixel.tweens.FlxEase.expoInOut;
			case "sinein": flixel.tweens.FlxEase.sineIn;
			case "sineout": flixel.tweens.FlxEase.sineOut;
			case "sineinout": flixel.tweens.FlxEase.sineInOut;
			case "backin": flixel.tweens.FlxEase.backIn;
			case "backout": flixel.tweens.FlxEase.backOut;
			case "backinout": flixel.tweens.FlxEase.backInOut;
			case "bouncein": flixel.tweens.FlxEase.bounceIn;
			case "bounceout": flixel.tweens.FlxEase.bounceOut;
			case "bounceinout": flixel.tweens.FlxEase.bounceInOut;
			case "classic": function(t:Float) return 1 - Math.pow(1 - 0.04, t * 60);
			default: flixel.tweens.FlxEase.linear;
		}
	}

	public static var list:Array<String> = [
		"linear", "quadOut", "quadIn", "quadInOut", "cubeOut", "cubeIn", "cubeInOut",
		"quartOut", "quartIn", "quartInOut", "quintOut", "quintIn", "quintInOut",
		"sineOut", "sineIn", "sineInOut", "expoOut", "expoIn", "expoInOut",
		"backOut", "backIn", "backInOut", "bounceOut", "bounceIn", "bounceInOut",
		"classic"
	];
}
