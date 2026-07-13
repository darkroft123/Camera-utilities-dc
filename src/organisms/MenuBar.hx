package organisms;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxCamera;
import pages.ModchartEditor;
import atoms.ColorConstants;

class MenuBar
{
	var cam:FlxCamera;

	public function new(cam:FlxCamera)
	{
		this.cam = cam;
	}

	public function create(owner:ModchartEditor):Void
	{
		var xPos:Float = 10;

		for (i in 0...owner.menus.length)
		{
			var measure = new FlxText(0, 0, 0, owner.menus[i].name, 20);
			measure.setFormat(Paths.font("vcr.ttf"), 20);
			var q = measure.width + 28;

			var b = new FlxSprite(xPos, 7);
			b.makeGraphic(Std.int(q), 20, ColorConstants.BTN_NORMAL);
			b.cameras = [cam];
			owner.add(b);
			owner.menuButtonBGs.push(b);

			var txt = new FlxText(b.x, 6, q, owner.menus[i].name, 20);
			txt.setFormat(Paths.font("vcr.ttf"), 20, ColorConstants.TXT_NORMAL, "center");
			txt.cameras = [cam];
			owner.add(txt);
			owner.menuButtons.push(txt);

			xPos += q + 8;
		}
	}

	public function updateHover(owner:ModchartEditor):Void
	{
		for (i in 0...owner.menuButtonBGs.length)
		{
			if (FlxG.mouse.overlaps(owner.menuButtonBGs[i], cam) && owner.activeMenuIndex != i)
			{
				owner.menuButtonBGs[i].color = ColorConstants.BTN_ACTIVE;
				owner.menuButtons[i].color = ColorConstants.TXT_ACTIVE;
				if (FlxG.mouse.justPressed) owner.openMenu(i);
			}
			else if (owner.activeMenuIndex != i)
			{
				owner.menuButtonBGs[i].color = ColorConstants.BTN_NORMAL;
				owner.menuButtons[i].color = ColorConstants.TXT_NORMAL;
			}
		}
	}

	public function setActiveColors(owner:ModchartEditor, index:Int):Void
	{
		for (i in 0...owner.menuButtonBGs.length)
		{
			owner.menuButtonBGs[i].color = (i == index) ? ColorConstants.BTN_ACTIVE : ColorConstants.BTN_NORMAL;
			owner.menuButtons[i].color = (i == index) ? ColorConstants.TXT_ACTIVE : ColorConstants.TXT_NORMAL;
		}
	}

	public function resetColors(owner:ModchartEditor):Void
	{
		setActiveColors(owner, -1);
	}
}
