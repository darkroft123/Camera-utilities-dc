package components;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import camera.ModchartFX;

class MenuDropdownComponent
{
	var state:ModchartFX;
	var cam:FlxCamera;

	public function new(state:ModchartFX, cam:FlxCamera)
	{
		this.state = state;
		this.cam = cam;
	}

	public function build(owner:ModchartFX, index:Int):Void
	{
		var btnBg = owner.menuButtonBGs[index];
		var items = owner.menus[index].items;

		var itemHeight = 32;
		var padding = 8;

		owner.menuBg = new FlxSprite(btnBg.x, btnBg.y + btnBg.height);
		owner.menuBg.makeGraphic(
			Std.int(btnBg.width + 200),
			items.length * itemHeight + padding * 2,
			ModchartFX.COL_MENU_BG
		);
		owner.menuBg.cameras = [cam];
		owner.add(owner.menuBg);

		owner.menuItems = [];
		owner.menuItemBGs = [];

		for (i in 0...items.length)
		{
			var bgItem = new FlxSprite(
				owner.menuBg.x,
				owner.menuBg.y + padding + i * itemHeight
			);

			bgItem.makeGraphic(
				Std.int(owner.menuBg.width),
				itemHeight,
				ModchartFX.COL_MENU_BG
			);

			bgItem.cameras = [cam];
			owner.add(bgItem);
			owner.menuItemBGs.push(bgItem);

			var item = new FlxText(
				bgItem.x,
				bgItem.y,
				bgItem.width,
				items[i],
				20
			);

			item.setFormat(
				Paths.font("vcr.ttf"),
				20,
				ModchartFX.COL_MENU_TXT
			);

			item.cameras = [cam];
			owner.add(item);
			owner.menuItems.push(item);
		}
	}

	public function close(owner:ModchartFX):Void
	{
		if (owner.menuBg == null)
			return;

		owner.menuBg.kill();
		owner.menuBg = null;

		for (t in owner.menuItems)
			t.kill();

		owner.menuItems = [];

		for (bg in owner.menuItemBGs)
			bg.kill();

		owner.menuItemBGs = [];
	}

	public function updateItems(owner:ModchartFX):Void
	{
		if (owner.menuBg != null && owner.menuItemBGs != null)
		{
			for (i in 0...owner.menuItems.length)
			{
				var item = owner.menuItems[i];
				var bg = owner.menuItemBGs[i];

				if (FlxG.mouse.overlaps(item))
				{
					bg.color = FlxColor.BLACK;
					item.color = FlxColor.WHITE;
				}
				else
				{
					bg.color = ModchartFX.COL_MENU_BG;
					item.color = ModchartFX.COL_MENU_TXT;
				}

				if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(item))
					owner.selectedItemIndex = i;
			}
		}
	}

	public function updateOutsideClick(owner:ModchartFX):Void
	{
		if (owner.menuBg != null
			&& FlxG.mouse.justPressed
			&& !FlxG.mouse.overlaps(owner.menuBg))
		{
			if (owner.ignoreNextClick)
				owner.ignoreNextClick = false;
			else
				owner.closeMenu();
		}
	}
}