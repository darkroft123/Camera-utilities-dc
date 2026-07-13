package components;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import game.Conductor;
import states.PlayState;
import camera.ModchartFX;
import camera.utilities.CameraUtilities;
class SongInfoComponent
{
	var state:ModchartFX;

	public function new(state:ModchartFX)
	{
		this.state = state;
	}

	public function create(owner:ModchartFX):Void
	{
		// X, Y, W, TEXT, SIZE
		owner.songPosInfo = new FlxText(FlxG.width - 430, 35, 400, "00:00\nCurBeat: 0\nCurStep: 0\nSection: 0\nBPM: 0\nTime Signature: 4/4", 15);
		owner.songPosInfo.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, "right", OUTLINE_FAST, FlxColor.fromInt(0x88000000));
		owner.songPosInfo.scrollFactor.set(0,0);
		owner.add(owner.songPosInfo);

		owner.songedits = new FlxText(FlxG.width - 430, owner.songPosInfo.y + 200, 400, "SongName: N/A\nDificulty: NONE", 15);
		owner.songedits.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, "right", OUTLINE_FAST, FlxColor.fromInt(0x88000000));
		owner.songedits.scrollFactor.set(0,0);
		owner.add(owner.songedits);
	}

	public function updateDisplay(owner:ModchartFX):Void
	{
		var songLength = FlxG.sound.music != null ? FlxG.sound.music.length : 0;

		owner.songedits.text =
			'SongName: ' + PlayState.SONG.song +
			'\nDificulty: ' + PlayState.storyDifficultyStr;

		owner.songPosInfo.text =
			CameraUtilities.timeToStr(Conductor.songPosition) + '/' + CameraUtilities.timeToStr(songLength) +
			'\nCurStep: ' + owner.curStep +
			'\nCurDecStep: '+ FlxMath.roundDecimal(owner.curDecStep, 2) +
			'\nCurBeat: ' + owner.curBeat +
			'\nCurDecBeat: ' + FlxMath.roundDecimal(owner.curDecBeat, 2) +
			'\nSnap: ' + owner.beatSnap +
			'\nSection: ' + owner.curSection +
			'\nBPM: ' + Conductor.bpm;
	}
}
