package organisms;

import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import pages.ModchartEditor;
import atoms.ColorConstants;

class BeatRuler extends FlxGroup
{
	public var rulerX:Float = 10.0;
	public var rulerY:Float = 580.0;
	public var rulerW:Int = 0;
	public var rulerH:Int = 32;

	var bg:FlxSprite;
	var tickSprites:Array<FlxSprite> = [];
	var labelSprites:Array<FlxText> = [];
	var gridRef:ModifierTimeline;
	var cam:FlxCamera;

	public function new(state:ModchartEditor, cam:FlxCamera, gridRef:ModifierTimeline)
	{
		super();
		this.cam = cam;
		this.gridRef = gridRef;

		rulerX = gridRef.gridX + ModifierTimeline.SIDEBAR_WIDTH;
		rulerW = Std.int(gridRef.gridW - ModifierTimeline.SIDEBAR_WIDTH);

		bg = new FlxSprite(rulerX, rulerY);
		bg.makeGraphic(Std.int(Math.max(rulerW, 1)), rulerH, FlxColor.fromRGB(20, 20, 30));
		bg.scrollFactor.set(0, 0);
		bg.cameras = [cam];
		add(bg);

		rebuildTicks();
	}

	public function rebuildTicks():Void
	{
		clearTicks();

		if (gridRef == null || rulerW <= 0) return;

		var scrollX = gridRef.scrollX;
		var zoomX = gridRef.zoomX;

		var beatStep:Int = 16;
		var drawStart = Math.floor(scrollX / beatStep) * beatStep;
		var drawEnd = Math.ceil((scrollX + rulerW / zoomX) / beatStep) * beatStep;

		for (step in Std.int(drawStart / beatStep)...Std.int(drawEnd / beatStep) + 1)
		{
			var stepPos = step * beatStep;
			var rx = (stepPos - scrollX) * zoomX;
			if (rx < -20 || rx > rulerW + 20) continue;

			var tick = new FlxSprite(rulerX + rx, rulerY);
			tick.makeGraphic(2, rulerH, ColorConstants.BTN_ACTIVE);
			tick.scrollFactor.set(0, 0);
			tick.cameras = [cam];
			add(tick);
			tickSprites.push(tick);

			var beatNum = step * 4;
			var label = new FlxText(rulerX + rx - 20, rulerY, 42, Std.string(beatNum), 16);
			label.setFormat(Paths.font("vcr.ttf"), 16, ColorConstants.TXT_NORMAL, "center");
			label.borderStyle = OUTLINE;
			label.borderColor = FlxColor.BLACK;
			label.borderSize = 1;
			label.scrollFactor.set(0, 0);
			label.cameras = [cam];
			add(label);
			labelSprites.push(label);
		}
	}

	function clearTicks():Void
	{
		for (s in tickSprites) { remove(s); s.destroy(); }
		tickSprites = [];
		for (s in labelSprites) { remove(s); s.destroy(); }
		labelSprites = [];
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		rulerX = gridRef.gridX + ModifierTimeline.SIDEBAR_WIDTH;
		rulerW = Std.int(gridRef.gridW - ModifierTimeline.SIDEBAR_WIDTH);
		bg.x = rulerX;
		bg.makeGraphic(Std.int(Math.max(rulerW, 1)), rulerH, FlxColor.fromRGB(12, 12, 20));
		rebuildTicks();
	}

	public function setY(newY:Float):Void
	{
		rulerY = newY;
		bg.y = rulerY;
	}
}
