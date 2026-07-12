package molecules;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import atoms.ColorConstants;

class DropdownMenu extends FlxTypedSpriteGroup<FlxSprite>
{
	public var bg:FlxSprite;
	public var label:FlxText;

	public var options:Array<String> = [];
	public var selectedOption:String = "";
	public var onSelect:(String) -> Void;

	public var isExpanded(default, null):Bool = false;

	var optionBgs:Array<FlxSprite> = [];
	var optionTexts:Array<FlxText> = [];
	var cam:FlxCamera;

	var menuW:Int;
	var menuH:Int;

	public function new(x:Float, y:Float, width:Int, height:Int, options:Array<String>, defaultOption:String, onSelect:(String) -> Void, cam:FlxCamera)
	{
		super(x, y);
		this.options = options;
		this.selectedOption = defaultOption;
		this.onSelect = onSelect;
		this.cam = cam;
		this.menuW = width;
		this.menuH = height;

		bg = new FlxSprite(0, 0);
		bg.makeGraphic(width, height, FlxColor.fromRGB(40, 40, 50));
		bg.scrollFactor.set(0, 0);
		bg.cameras = [cam];
		add(bg);

		label = new FlxText(5, 4, width - 10, defaultOption, 12);
		label.setFormat(Paths.font("vcr.ttf"), 12, ColorConstants.TXT_NORMAL, "left");
		label.scrollFactor.set(0, 0);
		label.cameras = [cam];
		add(label);
	}

	public function toggleExpand():Void
	{
		isExpanded = !isExpanded;
		clearDropdown();
		if (isExpanded) buildDropdown();
	}

	function buildDropdown():Void
	{
		for (i in 0...options.length)
		{
			var opt = options[i];
			var optY = menuH + i * menuH;

			var optBg = new FlxSprite(0, optY);
			optBg.makeGraphic(menuW, menuH, FlxColor.fromRGB(30, 30, 35));
			optBg.scrollFactor.set(0, 0);
			optBg.cameras = [cam];
			add(optBg);
			optionBgs.push(optBg);

			var optTxt = new FlxText(5, optY + 4, menuW - 10, opt, 12);
			optTxt.setFormat(Paths.font("vcr.ttf"), 12, ColorConstants.TXT_NORMAL, "left");
			optTxt.scrollFactor.set(0, 0);
			optTxt.cameras = [cam];
			add(optTxt);
			optionTexts.push(optTxt);
		}
	}

	function clearDropdown():Void
	{
		for (b in optionBgs) { remove(b); b.destroy(); }
		optionBgs = [];
		for (t in optionTexts) { remove(t); t.destroy(); }
		optionTexts = [];
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(bg, cam))
			{
				toggleExpand();
				return;
			}

			if (isExpanded)
			{
				var clickedIndex = -1;
				for (i in 0...optionBgs.length)
				{
					if (FlxG.mouse.overlaps(optionBgs[i], cam))
					{
						clickedIndex = i;
						break;
					}
				}

				if (clickedIndex != -1)
				{
					selectedOption = options[clickedIndex];
					label.text = selectedOption;
					clearDropdown();
					if (onSelect != null) onSelect(selectedOption);
				}
				else
				{
					clearDropdown();
				}
			}
		}

		if (isExpanded)
		{
			for (i in 0...optionBgs.length)
			{
				var hovered = FlxG.mouse.overlaps(optionBgs[i], cam);
				optionBgs[i].color = hovered ? FlxColor.fromRGB(80, 80, 100) : FlxColor.WHITE;
				optionTexts[i].color = hovered ? FlxColor.YELLOW : ColorConstants.TXT_NORMAL;
			}
		}
	}
}
