package organisms;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import camera.ModchartData;

class ModifierBlock extends FlxTypedSpriteGroup<FlxSprite>
{
	public var data:TimelineModifierPlacement;
	public var bg:FlxSprite;
	public var label:FlxText;

	public var isSelected:Bool = false;
	public var stateKey:String = "";

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
}
