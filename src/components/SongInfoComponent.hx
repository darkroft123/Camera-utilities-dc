package components;

import flixel.text.FlxText;

class SongInfoComponent
{
	public var songText:FlxText;
	public var posText:FlxText;

	public function new()
	{
		songText = new FlxText(0, 0, 400, "", 15);
		posText = new FlxText(0, 0, 400, "", 15);
	}

	public function updateInfo(song:String, diff:String, time:String, step:Int, beat:Int, section:Int, bpm:Float)
	{
		songText.text =
			"SongName: " + song +
			"\nDifficulty: " + diff;

		posText.text =
			time +
			"\nStep: " + step +
			"\nBeat: " + beat +
			"\nSection: " + section +
			"\nBPM: " + bpm;
	}
}