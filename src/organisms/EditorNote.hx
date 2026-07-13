package organisms;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import game.Conductor;
import game.StrumNote;
import utilities.NoteVariables;
import utilities.Options;
import Paths;
import states.PlayState;
import openfl.Assets;

class EditorNote extends FlxSprite
{
	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var isSustainNote:Bool = false;
	public var sustainLength:Float = 0;
	public var speed:Float = 1;
	public var modAngle:Float = 0;
	public var isHoldEnd:Bool = false;
	public var character:Int = 0;
	public var characters:Array<Int> = [];

	var ui_settings:Array<String>;
	var mania_size:Array<String>;
	var localKeyCount:Int;

	public function new(strumTime:Float, noteData:Int, ?sustainNote:Bool = false, ?arrowType:String = "default",
			?mustPress:Bool = false, ?ui_settings:Array<String>, ?mania_size:Array<String>, ?keyCount:Int,
			?isHoldEnd:Bool = false, ?character:Int = 0, ?characters:Array<Int> = null)
	{
		super();

		this.strumTime = strumTime;
		this.noteData = noteData;
		this.isSustainNote = sustainNote;
		this.mustPress = mustPress;
		this.ui_settings = ui_settings;
		this.mania_size = mania_size;
		this.localKeyCount = keyCount;
		this.isHoldEnd = isHoldEnd;
		this.character = character;
		this.characters = (characters != null) ? characters : [];

		var song = PlayState.SONG;
		var uiSkin:String = song != null ? (song.ui_Skin != null ? song.ui_Skin : "default") : "default";
		speed = song != null ? song.speed : 1;

		x += 100;
		y = -2000;

		// Load spritesheet (same logic as Note.getFrames but without PlayState.instance.types)
		frames = loadFrames(arrowType, uiSkin);

		var animationName:String = NoteVariables.animationDirections[localKeyCount - 1][noteData];
		animation.addByPrefix("default", '${animationName}0', 24);
		animation.addByPrefix("hold", '${animationName} hold0', 24);
		animation.addByPrefix("holdend", '${animationName} hold end0', 24);

		var uiScale = Std.parseFloat(ui_settings[0]);
		var uiMult = Std.parseFloat(ui_settings[2]);
		var lmaoStuff:Float = uiScale * (uiMult - Std.parseFloat(mania_size[localKeyCount - 1]));

		if (isSustainNote)
		{
			var baseSustainScale:Float = uiScale * (uiMult - Std.parseFloat(mania_size[3]));
			var speedMult:Float = FlxMath.roundDecimal(speed, 2);
			var verticalScale:Float = baseSustainScale * (Conductor.stepCrochet / 100) * 1.5 * speedMult;
			scale.set(lmaoStuff, verticalScale);
		}
		else
		{
			scale.set(lmaoStuff, lmaoStuff);
		}

		if (isSustainNote)
		{
			alpha = 0.6;
			if (Options.getData("downscroll") == true)
			{
				flipY = true;
			}
		}

		antialiasing = ui_settings[3] == "true" && Options.getData("antialiasing");

		x += swagWidth * noteData;
		
		if (isSustainNote)
		{
			if (isHoldEnd)
				animation.play("holdend");
			else
				animation.play("hold");
		}
		else
		{
			animation.play("default");
		}

		updateHitbox();
		centerOffsets();
	}

	public function calculateY(myStrum:StrumNote):Void
	{
		var strumY:Float = myStrum.y;
		var downscroll = Options.getData("downscroll") == true;
		y = strumY;

		if (isSustainNote)
		{
			if (downscroll)
				y -= (frameHeight * scale.y) - swagWidth;
			else
				y += (frameHeight * scale.y) - swagWidth;
		}

		var posMath:Float = 0.45 * (Conductor.songPosition - strumTime) * FlxMath.roundDecimal(speed, 2);
		if (!downscroll)
			y -= posMath;
		else
			y += posMath;
	}

	public function calculateCanBeHit():Void
	{
		if (!mustPress)
		{
			canBeHit = strumTime <= Conductor.songPosition;
			return;
		}

		canBeHit = strumTime > Conductor.songPosition - Conductor.safeZoneOffset
			&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset;
	}

	static function loadFrames(arrowType:String, uiSkin:String):FlxAtlasFrames
	{
		var basePath = 'ui skins/$uiSkin/arrows/';

		if (Assets.exists(Paths.image('$basePath$arrowType', 'shared')))
			return Paths.getSparrowAtlas('$basePath$arrowType', 'shared');
		if (Assets.exists(Paths.image('${basePath}default', 'shared')))
			return Paths.getSparrowAtlas('${basePath}default', 'shared');

		return Paths.getSparrowAtlas('ui skins/default/arrows/default', 'shared');
	}

	public static var swagWidth(get, never):Float;
	static function get_swagWidth():Float return 160 * 0.7;
}
