package components;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;

typedef MenuData =
{
	var name:String;
	var items:Array<String>;
}

class MenuBarComponent
{
	public var buttons:Array<FlxText> = [];
	public var buttonBGs:Array<FlxSprite> = [];

	public var menus:Array<MenuData>;
	public var onMenuClick:Int->Void;

	public function new(menus:Array<MenuData>, onClick:Int->Void)
	{
		this.menus = menus;
		this.onMenuClick = onClick;

		var xPos:Float = 10;

		for (i in 0...menus.length)
		{
			var measure = new FlxText(0, 0, 0, menus[i].name, 20);
			var w = measure.width + 28;

			var bg = new FlxSprite(xPos, 7);
			bg.makeGraphic(Std.int(w), 20, FlxColor.WHITE);

			var txt = new FlxText(bg.x, 6, w, menus[i].name, 20);

			buttonBGs.push(bg);
			buttons.push(txt);

			xPos += w + 8;
		}
	}

	public function update()
	{
		for (i in 0...buttonBGs.length)
		{
			if (FlxG.mouse.overlaps(buttonBGs[i]))
			{
				buttonBGs[i].color = FlxColor.WHITE;
				buttons[i].color = FlxColor.BLACK;

				if (FlxG.mouse.justPressed)
					onMenuClick(i);
			}
		}
	}
}