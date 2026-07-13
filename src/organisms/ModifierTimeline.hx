package organisms;

import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import pages.ModchartEditor;
import camera.ModchartData;
import templates.EditorLayout;
import game.Conductor;

class ModifierTimeline extends FlxGroup
{
	public var scrollX:Float = 0.0;
	public var zoomX:Float = 10.0;

	public var gridSprite:FlxSprite;
	public var cursorLine:FlxSprite;
	public var rulerLabel:FlxText;

	public var modifierBlocks:FlxTypedGroup<ModifierBlock>;
	public var beatLabels:FlxTypedGroup<FlxText>;

	public var state:ModchartEditor;
	var lastSongLen:Float = 0;

	public function new(state:ModchartEditor)
	{
		super();
		this.state = state;

		cameras = [state.camTimeline];

		var gridW = EditorLayout.GRID_COL_W;
		var gridH = Std.int(EditorLayout.timelineCamH);

		// Grid background
		gridSprite = new FlxSprite(0, 0);
		gridSprite.makeGraphic(gridW, gridH, 0xFF2A2A3E, true);
		gridSprite.scrollFactor.set(1, 1);
		gridSprite.cameras = [state.camTimeline];
		drawGrid();
		add(gridSprite);

		// Cursor line
		cursorLine = new FlxSprite(0, 0);
		cursorLine.makeGraphic(2, gridH, 0xFFFF5050);
		cursorLine.scrollFactor.set(0, 1);
		cursorLine.cameras = [state.camTimeline];
		add(cursorLine);

		// Ruler text (timestamp at current position)
		rulerLabel = new FlxText(gridW - 110, 2, 100, "0:00", 14);
		rulerLabel.setFormat(Paths.font("vcr.ttf"), 14, 0xFFCCCCCC, "right");
		rulerLabel.scrollFactor.set(0, 0);
		rulerLabel.cameras = [state.camTimeline];
		add(rulerLabel);

		modifierBlocks = new FlxTypedGroup<ModifierBlock>();
		add(modifierBlocks);

		beatLabels = new FlxTypedGroup<FlxText>();
		add(beatLabels);
	}

	public function drawGrid():Void
	{
		var pixels = gridSprite.pixels;
		pixels.fillRect(pixels.rect, 0xFF191524); // clear background

		var gridW = EditorLayout.GRID_COL_W;
		var gridH = Std.int(gridSprite.height);
		
		// visible beat range based on current scroll
		var startBeat:Int = Std.int(Math.max(0, Math.floor(scrollX / zoomX)));
		var endBeat:Int = Std.int(Math.ceil((scrollX + gridW) / zoomX)) + 1;

		var beatLineColor = 0x33FFFFFF; // semi-transparent white for beats
		var sectionLineColor = 0x66FFFFFF; // brighter white for 4-beat measures

		if (beatLabels != null) {
			beatLabels.forEachAlive(function(txt:FlxText) { txt.visible = false; });
		}
		var labelIndex = 0;

		for (i in startBeat...endBeat)
		{
			var xPos = Std.int(i * zoomX - scrollX);
			if (xPos < 0 || xPos >= gridW) continue;

			var isSection = (i % 4 == 0);
			var color = isSection ? sectionLineColor : beatLineColor;
			var lineW = isSection ? 2 : 1;

			var fillRect = new openfl.geom.Rectangle(xPos, 0, lineW, gridH);
			pixels.fillRect(fillRect, color);

			if (isSection && beatLabels != null)
			{
				var txt:FlxText = null;
				if (labelIndex >= beatLabels.length)
				{
					txt = new FlxText(xPos + 2, gridH - 16, 40, Std.string(i), 12);
					txt.setFormat(Paths.font("vcr.ttf"), 12, 0xFFFFFFFF, "left");
					txt.scrollFactor.set(0, 0); // stay locked vertically to camera
					txt.cameras = [state.camTimeline];
					beatLabels.add(txt);
				}
				else
				{
					txt = beatLabels.members[labelIndex];
				}
				txt.text = Std.string(i);
				txt.x = xPos + 2;
				txt.y = gridH - 16;
				txt.visible = true;
				labelIndex++;
			}
		}
		gridSprite.dirty = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var bpm = (Conductor.bpm > 0) ? Conductor.bpm : 120;
		var crochet = (60 / bpm) * 1000;
		var curTime = Conductor.songPosition;
		
		// Calculate scrollX to center the current song playback position
		var curBeat = curTime / crochet;
		var cursorTimelineX = curBeat * zoomX;
		var gridW = EditorLayout.GRID_COL_W;

		scrollX = cursorTimelineX - gridW / 2;
		if (scrollX < 0) scrollX = 0;

		// Position cursor line
		cursorLine.x = cursorTimelineX - scrollX - cursorLine.width / 2;

		// Update ruler label timestamp
		var totalSec = Math.floor(curTime / 1000);
		var min = Math.floor(totalSec / 60);
		var sec = totalSec % 60;
		rulerLabel.text = (min < 10 ? "0" : "") + min + ":" + (sec < 10 ? "0" : "") + sec;

		// Draw dynamic grid lines
		drawGrid();

		// Update positions and visual graphics of modifier blocks
		modifierBlocks.forEachAlive(function(block:ModifierBlock)
		{
			var rowIndex = -1;
			for (i in 0...state.loadedModifiers.length)
			{
				if (state.loadedModifiers[i].name == block.data.modifierRef)
				{
					rowIndex = i;
					break;
				}
			}

			if (rowIndex == -1)
			{
				block.visible = false;
				return;
			}

			block.visible = true;

			var blockX = block.data.beat * zoomX - scrollX;
			var blockY = rowIndex * EditorLayout.ROW_SIZE_Y;

			var durationBeats = (block.data.duration != null && block.data.duration > 0) ? block.data.duration : 1;
			var blockW = durationBeats * zoomX;
			var blockH = EditorLayout.ROW_SIZE_Y - 2;

			block.x = blockX;
			block.y = blockY;

			var blockW_int = Std.int(Math.max(4, blockW));
			var blockH_int = Std.int(Math.max(4, blockH));

			// Recreate graphic only if dimensions or selection/color state changed
			var stateKey:String = blockW_int + "x" + blockH_int + "_" + (block.isSelected ? "s" : "n") + "_" + block.data.type + "_" + block.data.ease;
			if (block.bg.width != blockW_int || block.bg.height != blockH_int || block.stateKey != stateKey)
			{
				block.stateKey = stateKey;
				block.bg.makeGraphic(blockW_int, blockH_int, FlxColor.TRANSPARENT, true);
				var pixels = block.bg.pixels;
				
				// 1. Draw semi-transparent background
				var bgColor = 0xAA12121A; // translucent dark blue-gray
				var bgRect = new openfl.geom.Rectangle(0, 0, blockW_int, blockH_int);
				pixels.fillRect(bgRect, bgColor);

				// 2. Draw border
				var borderColor = block.isSelected ? 0xFFFFFF00 : (block.data.type == "tween" ? 0xFF00AAFF : 0xFFAA00FF);
				
				// Top & Bottom borders
				var topRect = new openfl.geom.Rectangle(0, 0, blockW_int, 1);
				var botRect = new openfl.geom.Rectangle(0, blockH_int - 1, blockW_int, 1);
				pixels.fillRect(topRect, borderColor);
				pixels.fillRect(botRect, borderColor);
				// Left & Right borders
				var leftRect = new openfl.geom.Rectangle(0, 0, 1, blockH_int);
				var rightRect = new openfl.geom.Rectangle(blockW_int - 1, 0, 1, blockH_int);
				pixels.fillRect(leftRect, borderColor);
				pixels.fillRect(rightRect, borderColor);

				// 3. Draw inner graphics based on type
				if (block.data.type == "tween")
				{
					// Draw ease curve
					var easeFunc = atoms.EaseUtils.fromName(block.data.ease);
					var prevY:Int = -1;
					for (x in 0...blockW_int)
					{
						var t = x / (blockW_int - 1);
						if (blockW_int == 1) t = 0;
						var val = easeFunc(t);
						// Clamp and map to block height
						var yVal = Std.int(FlxMath.bound((1.0 - val) * (blockH_int - 4) + 2, 1, blockH_int - 2));

						if (prevY == -1) prevY = yVal;

						// Fill vertically to connect points smoothly
						var yStart = Math.min(prevY, yVal);
						var yEnd = Math.max(prevY, yVal);
						for (y in Std.int(yStart)...Std.int(yEnd + 1))
						{
							pixels.setPixel32(x, y, borderColor);
						}
						prevY = yVal;
					}
				}
				else
				{
					// Draw "Set" marker: a small vertical diamond/line in the center
					var centerX = Std.int(blockW_int / 2);
					var centerY = Std.int(blockH_int / 2);
					
					// Draw a 4x4 diamond shape
					for (dx in -2...3)
					{
						for (dy in -2...3)
						{
							if (Math.abs(dx) + Math.abs(dy) <= 2)
							{
								var px = centerX + dx;
								var py = centerY + dy;
								if (px >= 0 && px < blockW_int && py >= 0 && py < blockH_int)
								{
									pixels.setPixel32(px, py, borderColor);
								}
							}
						}
					}
				}
				block.bg.dirty = true;
			}

			block.label.text = block.data.modifierRef + " (" + block.data.value + ")";
			block.label.fieldWidth = blockW;
			block.label.x = 4;
			block.label.y = 2;
			block.label.borderStyle = OUTLINE;
			block.label.borderColor = 0xFF000000;
			block.label.borderSize = 1;
		});
	}

	public function loadPlacements():Void
	{
		modifierBlocks.clear();
		for (pl in state.timelinePlacements)
		{
			var block = new ModifierBlock(this, pl);
			block.cameras = [state.camTimeline];
			modifierBlocks.add(block);
		}
	}
}
