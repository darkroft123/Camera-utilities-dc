package components;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class MenuDropdownComponent
{
	public var bg:FlxSprite;
	public var items:Array<FlxText> = [];
	public var itemBGs:Array<FlxSprite> = [];

	public function new(x:Float, y:Float, items:Array<String>)
	{
		bg = new FlxSprite(x, y);
		bg.makeGraphic(200, items.length * 32 + 16, FlxColor.WHITE);

		for (i in 0...items.length)
		{
			var b = new FlxSprite(x, y + 8 + i * 32);
			b.makeGraphic(200, 32, FlxColor.WHITE);

			var t = new FlxText(x, y + 8 + i * 32, 200, items[i], 20);

			itemBGs.push(b);
			items.push(t);
		}
	}
}