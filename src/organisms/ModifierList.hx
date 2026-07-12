package organisms;

import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import pages.ModchartEditor;
import camera.ModchartData;
import atoms.ColorConstants;
import atoms.Styles;

class ModifierList extends FlxGroup
{
	public var panelW:Int = 175;
	public var panelX:Int = 5;
	public var panelY:Int = 380;

	var panelBg:FlxSprite;
	var headerText:FlxText;
	var infoText:FlxText;

	var rowBgs:Array<FlxSprite> = [];
	var rowTexts:Array<FlxText> = [];
	var selectedIndex:Int = -1;

	var maxVisibleRows:Int = 10;

	public var onModifierSelected:Int->Void;

	var state:ModchartEditor;
	var cam:FlxCamera;

	public function new(state:ModchartEditor, cam:FlxCamera)
	{
		super();
		this.state = state;
		this.cam = cam;

		panelBg = new FlxSprite(panelX, panelY);
		panelBg.makeGraphic(panelW, Std.int(FlxG.height - panelY - 35), ColorConstants.PANEL_MID);
		panelBg.scrollFactor.set(0, 0);
		panelBg.cameras = [cam];
		add(panelBg);

		headerText = Styles.makeHeaderLabel("MODIFIERS", panelX + 5, panelY + 3, panelW - 10);
		headerText.cameras = [cam];
		add(headerText);

		var separator = new FlxSprite(panelX + 2, panelY + 20);
		separator.makeGraphic(panelW - 4, 1, ColorConstants.GRID_LINE);
		separator.scrollFactor.set(0, 0);
		separator.cameras = [cam];
		add(separator);

		var rowY = panelY + 24;
		for (i in 0...maxVisibleRows)
		{
			// CNE-style alternating row colors
			var bgColor = (i % 2 == 0) ? 0xFF1A1A2E : 0xFF22223A;
			var bg = new FlxSprite(panelX + 2, rowY + i * 20);
			bg.makeGraphic(panelW - 4, 20, bgColor);
			bg.scrollFactor.set(0, 0);
			bg.cameras = [cam];
			add(bg);
			rowBgs.push(bg);

			var txt = Styles.makeLabel("", panelX + 5, rowY + i * 20 + 2, panelW - 14, 11);
			txt.cameras = [cam];
			add(txt);
			rowTexts.push(txt);
		}

		infoText = Styles.makeInfoLabel("", panelX + 5, panelY + panelBg.height - 20, panelW - 10);
		infoText.cameras = [cam];
		add(infoText);

		rebuildList();
	}

	public function rebuildList():Void
	{
		var entries = state.loadedModifiers;
		for (i in 0...maxVisibleRows)
		{
			var hasEntry = i < entries.length;
			rowBgs[i].visible = hasEntry;
			rowTexts[i].visible = hasEntry;
			if (hasEntry)
			{
				var e = entries[i];
				rowTexts[i].text = (i + 1) + ". " + e.name + " (" + e.type + ")";
				rowBgs[i].color = (i == selectedIndex) ? ColorConstants.HIGHLIGHT_BLUE : ((i % 2 == 0) ? 0xFF1A1A2E : 0xFF22223A);
			}
		}
		infoText.text = "Total: " + entries.length + " | Click to select";
	}

	public function selectEntry(index:Int):Void
	{
		selectedIndex = (index >= 0 && index < state.loadedModifiers.length) ? index : -1;
		rebuildList();
		if (onModifierSelected != null) onModifierSelected(selectedIndex);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed)
		{
			var entries = state.loadedModifiers;
			for (i in 0...Std.int(Math.min(maxVisibleRows, entries.length)))
			{
				if (FlxG.mouse.overlaps(rowBgs[i], cam))
				{
					selectEntry(i);
					return;
				}
			}

			if (FlxG.mouse.x > panelX && FlxG.mouse.x < panelX + panelW && FlxG.mouse.y > panelY)
			{
				var clickY = FlxG.mouse.y;
				if (clickY > panelY + 22 + entries.length * 20 && clickY < panelY + 22 + maxVisibleRows * 20)
				{
					selectEntry(-1);
				}
			}
		}
	}

	public function getSelectedIndex():Int
	{
		return selectedIndex;
	}

	public function setY(newY:Float):Void
	{
		panelY = Std.int(newY);
		panelBg.y = newY;
		panelBg.makeGraphic(panelW, Std.int(FlxG.height - newY - 35), ColorConstants.PANEL_MID);
		headerText.y = panelY + 3;
		var rowY = panelY + 24;
		for (i in 0...maxVisibleRows)
		{
			rowBgs[i].y = rowY + i * 20;
			rowTexts[i].y = rowY + i * 20 + 2;
		}
		infoText.y = panelY + panelBg.height - 20;
	}
}
