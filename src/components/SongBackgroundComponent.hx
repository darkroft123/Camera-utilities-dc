package components;

import flixel.FlxSprite;
import flixel.util.FlxColor;

class SongBackgroundComponent
{
	public var gray:FlxSprite;
	public var black:FlxSprite;
	public var line:FlxSprite;

	public function new()
	{
		gray = new FlxSprite(0, 720 - 330).makeGraphic(1285, 320, FlxColor.GRAY);
		gray.screenCenter(X);
		gray.scrollFactor.set(0, 0);

		black = new FlxSprite(0, 720 - 320).makeGraphic(1285, 320, FlxColor.BLACK);
		black.screenCenter(X);
		black.scrollFactor.set(0, 0);

		line = new FlxSprite(0, 720 - 280).makeGraphic(1285, 10, FlxColor.WHITE);
		line.screenCenter(X);
		line.scrollFactor.set(0, 0);
	}
}