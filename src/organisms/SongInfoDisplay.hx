package organisms;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import game.Conductor;
import states.PlayState;
import pages.ModchartEditor;
import atoms.TimeUtils;

class SongInfoDisplay
{
	public function new() {}

	public function create(owner:ModchartEditor):Void
	{
		owner.songPosInfo = new FlxText(FlxG.width - 600, 35, 580,
			"00:00\nCurStep: 0\nCurDecStep: 0\nCurBeat: 0\nCurDecBeat: 0\nSnap: 16\nSection: 0\nBPM: 0", 38);
		owner.songPosInfo.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, "right", OUTLINE_FAST, FlxColor.fromInt(0x88000000));
		owner.songPosInfo.scrollFactor.set(0, 0);
		owner.add(owner.songPosInfo);

		owner.songedits = new FlxText(FlxG.width - 600, owner.songPosInfo.y + 200, 580, "SongName: N/A\nDificulty: NONE", 38);
		owner.songedits.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, "right", OUTLINE_FAST, FlxColor.fromInt(0x88000000));
		owner.songedits.scrollFactor.set(0, 0);
		owner.add(owner.songedits);
	}

	public function updateDisplay(owner:ModchartEditor):Void
	{
		var songLength = FlxG.sound.music != null ? FlxG.sound.music.length : 0;

		owner.songedits.text =
			'SongName: ' + PlayState.SONG.song
			+ '\nDificulty: ' + PlayState.storyDifficultyStr;

		owner.songPosInfo.text =
			TimeUtils.timeToStr(Conductor.songPosition) + '/' + TimeUtils.timeToStr(songLength)
			+ '\nCurStep: ' + owner.curStep
			+ '\nCurDecStep: ' + FlxMath.roundDecimal(owner.curDecStep, 2)
			+ '\nCurBeat: ' + owner.curBeat
			+ '\nCurDecBeat: ' + FlxMath.roundDecimal(owner.curDecBeat, 2)
			+ '\nSnap: ' + owner.beatSnap
			+ '\nSection: ' + owner.curSection
			+ '\nBPM: ' + Conductor.bpm;
	}
}
