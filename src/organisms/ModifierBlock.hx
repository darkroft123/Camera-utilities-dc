package organisms;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import pages.ModchartEditor;
import camera.ModchartData;

class ModifierBlock extends FlxTypedSpriteGroup<FlxSprite>
{
	public var data:TimelineModifierPlacement;
	public var bg:FlxSprite;
	public var label:FlxText;

	public var isSelected:Bool = false;

	var isDragging:Bool = false;
	var dragStartMouseX:Float = 0;
	var dragStartBeat:Int = 0;

	var timeline:ModifierTimeline;

	public function new(timeline:ModifierTimeline, data:TimelineModifierPlacement)
	{
		super();
		this.timeline = timeline;
		this.data = data;

		bg = new FlxSprite();
		add(bg);

		label = new FlxText(0, 0, 100, "", 12);
		label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE);
		add(label);
	}

	public function updateInteraction(zoomX:Float, scrollX:Float, gridX:Float, ?cam:FlxCamera):Void
	{
		var mouseX = FlxG.mouse.x;
		var mouseY = FlxG.mouse.y;

		// Only interact if the block is visible (not scrolled under the sidebar)
		var stepPos = data.beat * 4;
		var rx = (stepPos - scrollX) * zoomX + gridX + ModifierTimeline.SIDEBAR_WIDTH;
		if (rx < gridX + ModifierTimeline.SIDEBAR_WIDTH) return;

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(bg, cam))
		{
			timeline.selectBlock(this);
			dragStartMouseX = mouseX;
			dragStartBeat = data.beat;
			isDragging = true;
		}

		if (isDragging && FlxG.mouse.pressed)
		{
			var deltaSteps = (mouseX - dragStartMouseX) / zoomX;
			var deltaBeats = Math.round(deltaSteps / 4);
			var useSnap = ModchartEditor.instance.snapToGrid && !FlxG.keys.pressed.SHIFT;
			if (useSnap) deltaBeats = Math.round(deltaBeats / 4) * 4;
			data.beat = Std.int(Math.max(0, dragStartBeat + deltaBeats));

			// Vertical drag to change track modifier
			var currentTrackIndex = Math.floor((mouseY - timeline.gridY) / 25);
			if (currentTrackIndex >= 0 && currentTrackIndex < timeline.state.loadedModifiers.length)
			{
				data.modifierRef = timeline.state.loadedModifiers[currentTrackIndex].name;
			}
		}
		else
		{
			isDragging = false;
		}
	}

	public function updateVisuals(scrollX:Float, zoomX:Float, gridX:Float, trackY:Float, trackH:Float):Void
	{
		var stepPos = data.beat * 4;
		var rx = (stepPos - scrollX) * zoomX + gridX + ModifierTimeline.SIDEBAR_WIDTH;
		x = rx;
		y = trackY;

		var w = Std.int(4 * zoomX);

		bg.x = x;
		bg.y = y + 1;
		bg.makeGraphic(w, Std.int(trackH - 2), isSelected ? FlxColor.fromRGB(80, 160, 240) : FlxColor.fromRGB(60, 100, 150));

		var modifierName = data.modifierRef;
		if (modifierName.length > 8) modifierName = modifierName.substr(0, 8) + "..";
		label.text = modifierName + ":" + data.type;
		label.x = x + 4;
		label.y = y + 3;

		// Mask block visual elements when scrolled under the frozen sidebar
		var isVisible = (rx >= gridX + ModifierTimeline.SIDEBAR_WIDTH - 2);
		bg.visible = isVisible;
		label.visible = isVisible && (rx + 4 >= gridX + ModifierTimeline.SIDEBAR_WIDTH);
	}
}
