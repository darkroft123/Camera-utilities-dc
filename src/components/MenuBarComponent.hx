package components;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxCamera;
import camera.ModchartFX;

class MenuBarComponent
{
	var state:ModchartFX;
	var cam:FlxCamera;

	public function new(state:ModchartFX, cam:FlxCamera)
	{
		this.state = state;
		this.cam = cam;
	}

	public function create(owner:ModchartFX):Void
	{
		var xPos:Float = 10;

		for (i in 0...owner.menus.length)
		{
			var measure = new FlxText(0, 0, 0, owner.menus[i].name, 20);
			measure.setFormat(Paths.font("vcr.ttf"), 20);

			var q = measure.width + 28;

			var b = new FlxSprite(xPos, 7);
			b.makeGraphic(Std.int(q), 20, ModchartFX.COL_BTN_ACTIVE);
			b.cameras = [cam];
			owner.add(b);
			owner.menuButtonBGs.push(b);

			var txt = new FlxText(b.x, 6, q, owner.menus[i].name, 20);
			txt.setFormat(Paths.font("vcr.ttf"), 20, ModchartFX.COL_TXT_NORMAL, "center");
			txt.cameras = [cam];
			owner.add(txt);
			owner.menuButtons.push(txt);

			xPos += q + 8;
		}
	}

	public function updateHover(owner:ModchartFX):Void
	{
		for (i in 0...owner.menuButtonBGs.length)
		{
			if (FlxG.mouse.overlaps(owner.menuButtonBGs[i]) && owner.activeMenuIndex != i)
			{
				owner.menuButtonBGs[i].color = ModchartFX.COL_BTN_ACTIVE;
				owner.menuButtons[i].color = ModchartFX.COL_TXT_ACTIVE;

				if (FlxG.mouse.justPressed)
					owner.openMenu(i);
			}
			else if (owner.activeMenuIndex != i)
			{
				owner.menuButtonBGs[i].color = ModchartFX.COL_BTN_NORMAL;
				owner.menuButtons[i].color = ModchartFX.COL_TXT_NORMAL;
			}
		}
	}

	public function setActiveColors(owner:ModchartFX, index:Int):Void
	{
		for (i in 0...owner.menuButtonBGs.length)
		{
			owner.menuButtonBGs[i].color = (i == index) ? ModchartFX.COL_BTN_ACTIVE : ModchartFX.COL_BTN_NORMAL;
			owner.menuButtons[i].color = (i == index) ? ModchartFX.COL_TXT_ACTIVE : ModchartFX.COL_TXT_NORMAL;
		}
	}

	public function resetColors(owner:ModchartFX):Void
	{
		for (i in 0...owner.menuButtonBGs.length)
		{
			owner.menuButtonBGs[i].color = ModchartFX.COL_BTN_NORMAL;
			owner.menuButtons[i].color = ModchartFX.COL_TXT_NORMAL;
		}
	}
}