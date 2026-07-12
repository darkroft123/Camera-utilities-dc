package molecules;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import atoms.ColorConstants;

class ProgressSlider extends FlxGroup
{
	public var trackBg:FlxSprite;
	public var trackFill:FlxSprite;
	public var thumb:FlxSprite;

	public var onSeek:(Float) -> Void;

	public var isDragging(default, null):Bool = false;
	var sliderLeft:Float;
	var sliderRight:Float;
	var _value:Float = 0;
	var cam:FlxCamera;

	public function new(x:Float, y:Float, width:Int, cam:FlxCamera)
	{
		super();

		sliderLeft = x;
		sliderRight = x + width;
		this.cam = cam;

		trackBg = new FlxSprite(x, y);
		trackBg.makeGraphic(width, 12, FlxColor.fromRGB(40, 40, 50));
		trackBg.scrollFactor.set(0, 0);
		trackBg.cameras = [cam];
		add(trackBg);

		trackFill = new FlxSprite(x, y);
		trackFill.makeGraphic(1, 12, FlxColor.fromRGB(100, 180, 255));
		trackFill.scrollFactor.set(0, 0);
		trackFill.cameras = [cam];
		add(trackFill);

		thumb = new FlxSprite(x, y - 4);
		thumb.makeGraphic(8, 20, ColorConstants.BTN_ACTIVE);
		thumb.scrollFactor.set(0, 0);
		thumb.cameras = [cam];
		add(thumb);
	}

	public var value(get, set):Float;
	function get_value():Float return _value;
	function set_value(v:Float):Float
	{
		_value = FlxMath.bound(v, 0, 1);
		updateVisuals();
		return _value;
	}

	function updateVisuals():Void
	{
		var fillW = Std.int(Math.max(_value * (sliderRight - sliderLeft), 1));
		trackFill.setGraphicSize(fillW, 12);
		trackFill.updateHitbox();
		thumb.x = sliderLeft + _value * (sliderRight - sliderLeft) - thumb.width * 0.5;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(trackBg, cam))
		{
			isDragging = true;
			updateFromMouse();
			if (onSeek != null) onSeek(_value);
		}

		if (isDragging)
		{
			if (FlxG.mouse.pressed)
			{
				updateFromMouse();
				if (onSeek != null) onSeek(_value);
			}
			else
			{
				isDragging = false;
			}
		}
	}

	function updateFromMouse():Void
	{
		value = FlxMath.bound((FlxG.mouse.x - sliderLeft) / (sliderRight - sliderLeft), 0, 1);
	}

	public function resizeTo(newWidth:Int):Void
	{
		sliderRight = sliderLeft + newWidth;
		trackBg.makeGraphic(newWidth, 12, FlxColor.fromRGB(40, 40, 50));
		trackBg.updateHitbox();
		updateVisuals();
	}

	public var y(get, set):Float;
	function get_y():Float return trackBg.y;
	function set_y(v:Float):Float
	{
		trackBg.y = v;
		trackFill.y = v;
		thumb.y = v - 4;
		return v;
	}
}
