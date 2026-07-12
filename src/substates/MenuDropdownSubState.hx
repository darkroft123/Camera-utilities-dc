package substates;

import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import pages.ModchartEditor;
import atoms.ColorConstants;

class MenuDropdownSubState extends FlxSubState
{
	var parentState:ModchartEditor;
	var menuIndex:Int;
	var menuBg:FlxSprite;
	var menuItems:Array<FlxText> = [];
	var menuItemBGs:Array<FlxSprite> = [];

	public function new(parentState:ModchartEditor, menuIndex:Int)
	{
		super();
		this.parentState = parentState;
		this.menuIndex = menuIndex;
	}

	override public function create():Void
	{
		super.create();
		cameras = [parentState.uiCam];

		var btnBg = parentState.menuButtonBGs[menuIndex];
		var items = parentState.menus[menuIndex].items;

		var itemHeight = 32;
		var padding = 8;

		menuBg = new FlxSprite(btnBg.x, btnBg.y + btnBg.height);
		menuBg.makeGraphic(
			Std.int(btnBg.width + 200),
			items.length * itemHeight + padding * 2,
			ColorConstants.MENU_BG
		);
		add(menuBg);

		for (i in 0...items.length)
		{
			var bgItem = new FlxSprite(menuBg.x, menuBg.y + padding + i * itemHeight);
			bgItem.makeGraphic(Std.int(menuBg.width), itemHeight, ColorConstants.MENU_BG);
			add(bgItem);
			menuItemBGs.push(bgItem);

			var item = new FlxText(bgItem.x + 5, bgItem.y + 4, bgItem.width - 10, items[i], 20);
			item.setFormat(Paths.font("vcr.ttf"), 20, ColorConstants.MENU_TXT);
			add(item);
			menuItems.push(item);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		for (i in 0...menuItems.length)
		{
			var item = menuItems[i];
			var bg = menuItemBGs[i];

			if (FlxG.mouse.overlaps(bg, parentState.uiCam))
			{
				bg.color = FlxColor.BLACK;
				item.color = FlxColor.WHITE;

				if (FlxG.mouse.justPressed)
				{
					var actionName = parentState.menus[menuIndex].name;
					close();
					parentState.handleMenuAction(actionName, i);
					parentState.closeMenu();
					return;
				}
			}
			else
			{
				bg.color = ColorConstants.MENU_BG;
				item.color = ColorConstants.MENU_TXT;
			}
		}

		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(menuBg, parentState.uiCam))
		{
			close();
			parentState.closeMenu();
		}
	}
}
