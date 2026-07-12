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
import molecules.Scrollbar;
import atoms.ColorConstants;
import atoms.Styles;

class ModifierTimeline extends FlxGroup
{
	public static inline var SIDEBAR_WIDTH:Int = 120;

	public var scrollX:Float = 0.0;
	public var zoomX:Float = 10.0;

	public var modifierBlocks:FlxTypedGroup<ModifierBlock>;
	public var gridSprite:FlxSprite;
	public var cursorLine:FlxSprite;

	public var sidebarBg:FlxSprite;
	public var sidebarTexts:FlxTypedGroup<FlxText>;
	public var rowBgSprites:Array<FlxSprite> = [];

	public var gridX:Float;
	public var gridY:Float;
	public var gridW:Int;
	public var gridH:Int;

	public var timelineScroll:Scrollbar;
	public var zoomScroll:Scrollbar;

	public var headerLabel:FlxText;
	public var separatorLine:FlxSprite;
	public var separatorLine2:FlxSprite;

	var beatRuler:BeatRuler;
	public var state:ModchartEditor;
	var cam:FlxCamera;

	public var selectedBlock:ModifierBlock = null;

	public function new(state:ModchartEditor, cam:FlxCamera, ?posX:Float, ?posY:Float, ?width:Int, ?height:Int)
	{
		super();
		this.state = state;
		this.cam = cam;

		gridX = (posX != null) ? posX : 195.0;
		gridY = (posY != null) ? posY : 370.0;
		gridW = (width != null) ? width : Std.int(FlxG.width - 205);
		gridH = (height != null) ? height : Std.int(FlxG.height - Std.int(gridY) - 30);

		headerLabel = Styles.makeHeaderLabel("TIMELINE (Modifier Placements)", gridX, gridY - 18, gridW, 14);
		headerLabel.cameras = [cam];
		add(headerLabel);

		gridSprite = new FlxSprite(gridX, gridY);
		gridSprite.scrollFactor.set(0, 0);
		gridSprite.cameras = [cam];
		add(gridSprite);

		modifierBlocks = new FlxTypedGroup<ModifierBlock>();
		add(modifierBlocks);

		cursorLine = new FlxSprite(gridX, gridY);
		cursorLine.makeGraphic(2, gridH, FlxColor.fromRGB(255, 80, 80));
		cursorLine.scrollFactor.set(0, 0);
		cursorLine.cameras = [cam];
		add(cursorLine);

		// CNE-style sidebar with alternating row backgrounds
		sidebarBg = new FlxSprite(gridX, gridY);
		sidebarBg.makeGraphic(SIDEBAR_WIDTH, gridH, ColorConstants.PANEL_MID);
		sidebarBg.scrollFactor.set(0, 0);
		sidebarBg.cameras = [cam];
		add(sidebarBg);

		// CNE-style separator line between sidebar and grid
		separatorLine = new FlxSprite(gridX + SIDEBAR_WIDTH - 2, gridY);
		separatorLine.makeGraphic(2, gridH, ColorConstants.GRID_LINE);
		separatorLine.scrollFactor.set(0, 0);
		separatorLine.cameras = [cam];
		add(separatorLine);

		// CNE-style second separator for the value column area
		separatorLine2 = new FlxSprite(gridX + SIDEBAR_WIDTH, gridY + gridH + 2);
		separatorLine2.makeGraphic(gridW - SIDEBAR_WIDTH, 1, ColorConstants.GRID_LINE);
		separatorLine2.scrollFactor.set(0, 0);
		separatorLine2.cameras = [cam];
		add(separatorLine2);

		sidebarTexts = new FlxTypedGroup<FlxText>();
		add(sidebarTexts);

		var scrollBarW = gridW - 4;
		var zoomW = 80;
		var timelineW = scrollBarW - zoomW - 4;
		var scrollY = gridY - 45;

		timelineScroll = new Scrollbar(this, gridX + 2, scrollY, timelineW, 20, 0, 1, true, cam);
		timelineScroll.onValueChange = function(val) {
			scrollX = val;
			drawGrid();
		};

		zoomScroll = new Scrollbar(this, gridX + 2 + timelineW + 4, scrollY, zoomW, 20, 2.0, 30.0, true, cam);
		zoomScroll.setValue(zoomX);
		zoomScroll.onValueChange = function(val) {
			zoomX = val;
			drawGrid();
		};

		beatRuler = new BeatRuler(state, cam, this);
		beatRuler.rulerY = gridY + gridH + 2;
		add(beatRuler);

		loadPlacements();
		drawGrid();
	}

	public function loadPlacements():Void
	{
		modifierBlocks.clear();
		for (pl in state.timelinePlacements)
		{
			var block = new ModifierBlock(this, pl);
			block.cameras = [cam];
			modifierBlocks.add(block);
		}
	}

	public function updateSidebar():Void
	{
		// Clear old row backgrounds
		for (r in rowBgSprites) { remove(r); r.destroy(); }
		rowBgSprites = [];

		sidebarTexts.clear();
		var numMods = state.loadedModifiers.length;
		for (i in 0...numMods)
		{
			// CNE-style alternating row backgrounds
			var rowBg = new FlxSprite(gridX, gridY + i * 25);
			rowBg.makeGraphic(SIDEBAR_WIDTH, 25, i % 2 == 0 ? 0xFF1A1A2E : 0xFF22223A);
			rowBg.scrollFactor.set(0, 0);
			rowBg.cameras = [cam];
			add(rowBg);
			rowBgSprites.push(rowBg);

			var mod = state.loadedModifiers[i];
			var name = mod.name;
			if (name.length > 12) name = name.substr(0, 10) + "..";

			var text = new FlxText(gridX + 5, gridY + 4 + i * 25, SIDEBAR_WIDTH - 10, name, 12);
			text.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE);
			text.scrollFactor.set(0, 0);
			text.cameras = [cam];
			sidebarTexts.add(text);
		}
	}

	public function drawGrid():Void
	{
		if (gridW <= 0 || gridH <= 0) return;
		gridSprite.makeGraphic(gridW, gridH, FlxColor.TRANSPARENT, true);
		var pixels = gridSprite.pixels;

		var numTracks = state.loadedModifiers.length;
		var rect = new openfl.geom.Rectangle(0, 0, gridW, 1);

		// CNE-style: alternating row backgrounds and thicker horizontal separators
		for (i in 0...numTracks)
		{
			rect.y = i * 25;
			rect.height = 1;
			pixels.fillRect(rect, ColorConstants.GRID_LINE);

			// Fill alternate rows with subtle background
			if (i % 2 == 0)
			{
				var fillRect = new openfl.geom.Rectangle(0, i * 25 + 1, gridW, 24);
				var bgColor = 0xFF18182A;
				pixels.fillRect(fillRect, bgColor);
			}
		}
		// Bottom border
		rect.y = numTracks * 25;
		rect.height = 1;
		pixels.fillRect(rect, ColorConstants.GRID_LINE);

		rect.width = 1;
		rect.height = gridH;
		rect.y = 0;

		var stepStart = Math.floor(scrollX);
		var stepEnd = Math.ceil(scrollX + (gridW - SIDEBAR_WIDTH) / zoomX);

		for (step in stepStart...stepEnd)
		{
			var rx = (step - scrollX) * zoomX + SIDEBAR_WIDTH;
			if (rx < SIDEBAR_WIDTH || rx > gridW) continue;

			if (step % 16 == 0)
			{
				rect.width = 2;
				rect.x = rx;
				pixels.fillRect(rect, ColorConstants.GRID_BEAT);
				rect.width = 1;
			}
			else if (step % 4 == 0)
			{
				rect.x = rx;
				pixels.fillRect(rect, ColorConstants.GRID_STEP);
			}
		}

		gridSprite.dirty = true;
		updateSidebar();
	}

	function syncEditorToPlacement():Void
	{
		if (selectedBlock == null) return;
		selectedBlock.data.value = state.modifierEditor.currentValue;
		selectedBlock.data.type = state.modifierEditor.currentType;
		if (selectedBlock.data.type == "tween")
		{
			selectedBlock.data.duration = Std.int(state.modifierEditor.currentDuration);
			selectedBlock.data.ease = state.modifierEditor.currentEase;
		}
		else
		{
			selectedBlock.data.duration = null;
			selectedBlock.data.ease = null;
		}
	}

	public function selectBlock(block:ModifierBlock):Void
	{
		syncEditorToPlacement();
		selectedBlock = block;
		for (b in modifierBlocks.members)
		{
			if (b != null) b.isSelected = (b == block);
		}
		if (block != null)
		{
			state.modifierEditor.loadPlacement(block.data);
		}
	}

	public function deleteSelectedBlock():Void
	{
		if (selectedBlock == null) return;
		state.timelinePlacements.remove(selectedBlock.data);
		modifierBlocks.remove(selectedBlock);
		selectedBlock.destroy();
		selectedBlock = null;
		state.modifierEditor.clearEditor();
	}

	public function clickToPlaceEvent(mouseX:Float, mouseY:Float):Bool
	{
		if (mouseX < gridX + SIDEBAR_WIDTH || mouseX > gridX + gridW) return false;
		if (mouseY < gridY || mouseY > gridY + gridH) return false;

		syncEditorToPlacement();

		// Calculate track index based on mouseY click
		var trackIndex = Math.floor((mouseY - gridY) / 25);
		if (trackIndex < 0 || trackIndex >= state.loadedModifiers.length)
		{
			return false;
		}

		var modifierRef = state.loadedModifiers[trackIndex].name;
		var value:Float = state.modifierEditor.currentValue;
		var type:String = state.modifierEditor.currentType;
		var duration:Int = Std.int(state.modifierEditor.currentDuration);
		var ease:String = state.modifierEditor.currentEase;

		var rawStep = scrollX + (mouseX - gridX - SIDEBAR_WIDTH) / zoomX;
		var snapSteps:Int = Std.int(state.beatSnap / 4);
		var snappedStep = Math.round(rawStep / snapSteps) * snapSteps;
		var snappedBeat:Int = Std.int(snappedStep / 4);

		var placement:TimelineModifierPlacement = {
			modifierRef: modifierRef,
			value: value,
			type: type,
			duration: (type == "tween") ? duration : null,
			ease: (type == "tween") ? ease : null,
			beat: snappedBeat
		};

		state.timelinePlacements.push(placement);
		var block = new ModifierBlock(this, placement);
		block.cameras = [cam];
		modifierBlocks.add(block);
		return true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var totalSteps = (FlxG.sound.music != null && game.Conductor.stepCrochet > 0) ? (FlxG.sound.music.length / game.Conductor.stepCrochet) : 1000.0;
		var visibleSteps = (gridW - SIDEBAR_WIDTH) / zoomX;
		var maxScroll = Math.max(0, totalSteps - visibleSteps);

		if (visibleSteps > 0)
		{
			timelineScroll.setRange(0, maxScroll);
			scrollX = FlxMath.bound(scrollX, 0, maxScroll);
		}

		timelineScroll.update();
		zoomScroll.update();

		if (!timelineScroll.isDragging)
		{
			timelineScroll.setValue(scrollX);
		}

		if ((FlxG.mouse.overlaps(gridSprite, cam) || FlxG.mouse.overlaps(cursorLine, cam)) && !FlxG.mouse.overlaps(zoomScroll.track, cam))
		{
			var wheel = FlxG.mouse.wheel;
			if (wheel != 0)
			{
				var oldScrollX = scrollX;
				scrollX = FlxMath.bound(scrollX - wheel * 4, 0, maxScroll);
				if (scrollX != oldScrollX)
				{
					timelineScroll.setValue(scrollX);
					drawGrid();
				}
			}
		}

		var cx = (state.curDecStep - scrollX) * zoomX + gridX + SIDEBAR_WIDTH;
		cursorLine.x = cx;
		cursorLine.visible = (cx >= gridX + SIDEBAR_WIDTH && cx <= gridX + gridW);

		// Position blocks horizontally and on their corresponding vertical tracks
		for (b in modifierBlocks.members)
		{
			if (b == null) continue;
			
			var trackIndex = -1;
			for (i in 0...state.loadedModifiers.length)
			{
				if (state.loadedModifiers[i].name == b.data.modifierRef)
				{
					trackIndex = i;
					break;
				}
			}

			if (trackIndex != -1)
			{
				b.visible = true;
				b.updateVisuals(scrollX, zoomX, gridX, gridY + 2 + trackIndex * 25, 22);
				b.updateInteraction(zoomX, scrollX, gridX, cam);
			}
			else
			{
				b.visible = false;
			}
		}

		if (FlxG.mouse.overlaps(gridSprite, cam) || FlxG.mouse.overlaps(cursorLine, cam))
		{
			if (FlxG.mouse.justPressed)
			{
				var onBlock = false;
				for (b in modifierBlocks.members)
				{
					if (b != null && b.visible && FlxG.mouse.overlaps(b.bg, cam)) { onBlock = true; break; }
				}
				if (!onBlock) clickToPlaceEvent(FlxG.mouse.x, FlxG.mouse.y);
			}
		}

		if (FlxG.keys.justPressed.BACKSPACE && !state.modifierEditor.hasFocusedInput())
		{
			syncEditorToPlacement();
			deleteSelectedBlock();
		}
	}

	public function setY(newY:Float):Void
	{
		gridY = newY;
		headerLabel.y = gridY - 18;
		gridSprite.y = gridY;
		cursorLine.y = gridY;
		sidebarBg.y = gridY;
		separatorLine.y = gridY;
		separatorLine2.y = gridY + gridH + 2;
		var scrollY = gridY - 45;
		timelineScroll.setY(scrollY);
		zoomScroll.setY(scrollY);
		beatRuler.rulerY = gridY + gridH + 2;
		drawGrid();
	}

	public function resize(newX:Float, newY:Float, newW:Int, newH:Int):Void
	{
		gridX = newX;
		gridY = newY;
		gridW = newW;
		gridH = newH;

		gridSprite.x = gridX;
		gridSprite.y = gridY;
		gridSprite.makeGraphic(gridW, gridH, FlxColor.TRANSPARENT, true);

		cursorLine.x = gridX;
		cursorLine.y = gridY;
		cursorLine.makeGraphic(2, gridH, FlxColor.fromRGB(255, 80, 80));

		sidebarBg.x = gridX;
		sidebarBg.y = gridY;
		sidebarBg.makeGraphic(SIDEBAR_WIDTH, gridH, ColorConstants.PANEL_MID);

		separatorLine.x = gridX + SIDEBAR_WIDTH - 2;
		separatorLine.y = gridY;
		separatorLine.makeGraphic(2, gridH, ColorConstants.GRID_LINE);

		separatorLine2.x = gridX + SIDEBAR_WIDTH;
		separatorLine2.y = gridY + gridH + 2;
		separatorLine2.makeGraphic(gridW - SIDEBAR_WIDTH, 1, ColorConstants.GRID_LINE);

		headerLabel.x = gridX;
		headerLabel.y = gridY - 18;
		headerLabel.fieldWidth = gridW;

		beatRuler.rulerX = gridX + SIDEBAR_WIDTH;
		beatRuler.rulerW = gridW - SIDEBAR_WIDTH;
		beatRuler.rulerY = gridY + gridH + 2;

		var scrollBarW = gridW - 4;
		var zoomW = 80;
		var timelineW = scrollBarW - zoomW - 4;
		var scrollY = gridY - 45;

		timelineScroll.track.x = gridX + 2;
		timelineScroll.setY(scrollY);

		zoomScroll.track.x = gridX + 2 + timelineW + 4;
		zoomScroll.setY(scrollY);

		drawGrid();
	}
}
