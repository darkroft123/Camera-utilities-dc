package molecules;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import atoms.ColorConstants;

class Scrollbar
{
	public var container:FlxGroup;
	public var track:FlxSprite;
	public var thumb:FlxSprite;

	public var minVal:Float = 0;
	public var maxVal:Float = 100;
	public var currentVal:Float = 0;

	public var isDragging:Bool = false;
	public var onValueChange:(Float) -> Void;

	var dragOffset:Float = 0;
	var isHorizontal:Bool = true;
	var cam:FlxCamera;

	public function new(container:FlxGroup, x:Float, y:Float, width:Int, height:Int, min:Float, max:Float, isHorizontal:Bool = true, cam:FlxCamera)
	{
		this.container = container;
		this.minVal = min;
		this.maxVal = max;
		this.isHorizontal = isHorizontal;
		this.cam = cam;

		track = new FlxSprite(x, y);
		track.makeGraphic(width, height, FlxColor.fromRGB(40, 40, 40));
		track.scrollFactor.set(0, 0);
		track.cameras = [cam];
		container.add(track);

		thumb = new FlxSprite(x, y);
		var thumbW = isHorizontal ? Std.int(Math.max(width * 0.1, 20)) : width;
		var thumbH = isHorizontal ? height : Std.int(Math.max(height * 0.1, 20));

		thumb.makeGraphic(thumbW, thumbH, ColorConstants.BTN_ACTIVE);
		thumb.scrollFactor.set(0, 0);
		thumb.cameras = [cam];
		container.add(thumb);

		updateThumbPosition();
	}

	public function update():Void
	{
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(thumb, cam))
		{
			isDragging = true;
			dragOffset = isHorizontal ? FlxG.mouse.x - thumb.x : FlxG.mouse.y - thumb.y;
		}

		if (isDragging)
		{
			if (FlxG.mouse.pressed)
			{
				var pct:Float;
				if (isHorizontal)
				{
					var newX = FlxMath.bound(FlxG.mouse.x - dragOffset, track.x, track.x + track.width - thumb.width);
					thumb.x = newX;
					pct = (track.width - thumb.width) > 0 ? (newX - track.x) / (track.width - thumb.width) : 0;
				}
				else
				{
					var newY = FlxMath.bound(FlxG.mouse.y - dragOffset, track.y, track.y + track.height - thumb.height);
					thumb.y = newY;
					pct = (track.height - thumb.height) > 0 ? (newY - track.y) / (track.height - thumb.height) : 0;
				}

				currentVal = minVal + pct * (maxVal - minVal);
				if (onValueChange != null) onValueChange(currentVal);
			}
			else
			{
				isDragging = false;
			}
		}
	}

	public function setValue(val:Float):Void
	{
		currentVal = FlxMath.bound(val, minVal, maxVal);
		updateThumbPosition();
	}

	public function updateThumbPosition():Void
	{
		var range = maxVal - minVal;
		var pct = range > 0 ? (currentVal - minVal) / range : 0;

		if (isHorizontal)
		{
			thumb.x = track.x + pct * (track.width - thumb.width);
		}
		else
		{
			thumb.y = track.y + pct * (track.height - thumb.height);
		}
	}

	public function setRange(min:Float, max:Float):Void
	{
		minVal = min;
		maxVal = max;
		setValue(currentVal);
	}

	public function setY(newY:Float):Void
	{
		track.y = newY;
		if (isHorizontal) thumb.y = newY;
		updateThumbPosition();
	}

	public function destroy():Void
	{
		if (container != null)
		{
			container.remove(track, true);
			container.remove(thumb, true);
		}
		track.destroy();
		thumb.destroy();
	}
}
