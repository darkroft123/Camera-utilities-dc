package atoms;

class EaseUtils
{
	public static function fromName(name:String):(Float) -> Float
	{
		return switch (name)
		{
			case "quadIn": flixel.tweens.FlxEase.quadIn;
			case "quadOut": flixel.tweens.FlxEase.quadOut;
			case "quadInOut": flixel.tweens.FlxEase.quadInOut;
			case "cubeIn": flixel.tweens.FlxEase.cubeIn;
			case "cubeOut": flixel.tweens.FlxEase.cubeOut;
			case "cubeInOut": flixel.tweens.FlxEase.cubeInOut;
			case "quartIn": flixel.tweens.FlxEase.quartIn;
			case "quartOut": flixel.tweens.FlxEase.quartOut;
			case "quartInOut": flixel.tweens.FlxEase.quartInOut;
			case "quintIn": flixel.tweens.FlxEase.quintIn;
			case "quintOut": flixel.tweens.FlxEase.quintOut;
			case "quintInOut": flixel.tweens.FlxEase.quintInOut;
			case "expoIn": flixel.tweens.FlxEase.expoIn;
			case "expoOut": flixel.tweens.FlxEase.expoOut;
			case "expoInOut": flixel.tweens.FlxEase.expoInOut;
			case "sineIn": flixel.tweens.FlxEase.sineIn;
			case "sineOut": flixel.tweens.FlxEase.sineOut;
			case "sineInOut": flixel.tweens.FlxEase.sineInOut;
			case "backIn": flixel.tweens.FlxEase.backIn;
			case "backOut": flixel.tweens.FlxEase.backOut;
			case "backInOut": flixel.tweens.FlxEase.backInOut;
			case "bounceIn": flixel.tweens.FlxEase.bounceIn;
			case "bounceOut": flixel.tweens.FlxEase.bounceOut;
			case "bounceInOut": flixel.tweens.FlxEase.bounceInOut;
			default: flixel.tweens.FlxEase.linear;
		}
	}

	public static var list:Array<String> = [
		"linear", "quadOut", "quadIn", "quadInOut", "cubeOut", "cubeIn", "cubeInOut",
		"sineOut", "sineIn", "sineInOut", "expoOut", "expoIn", "expoInOut",
		"backOut", "backIn", "backInOut", "bounceOut", "bounceIn", "bounceInOut"
	];
}
