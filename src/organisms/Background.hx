package organisms;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.FlxG;
import pages.ModchartEditor;

class Background
{
	public var bg:FlxSprite;

	public function new(state:ModchartEditor)
	{
		bg = new FlxSprite(0, 0);
		bg.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.fromRGB(25, 21, 36));
		bg.screenCenter();
		bg.antialiasing = true;
		state.add(bg);
	}
}
