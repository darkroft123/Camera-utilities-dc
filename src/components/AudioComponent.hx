package components;

import flixel.FlxG;
import flixel.sound.FlxSound;
import game.SoundGroup;
import states.PlayState;
import camera.ModchartFX;

class AudioComponent
{
	var state:ModchartFX;

	public function new(state:ModchartFX)
	{
		this.state = state;
	}

	public function create(owner:ModchartFX):Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}

		FlxG.sound.music = new FlxSound().loadEmbedded(
			Paths.inst(PlayState.SONG.song, PlayState.storyDifficultyStr)
		);
		FlxG.sound.list.add(FlxG.sound.music);
		FlxG.sound.music.pause();
		FlxG.sound.music.time = 0;

		owner.vocals = new SoundGroup(2);

		if (PlayState.SONG.needsVoices)
		{
			var v = new FlxSound().loadEmbedded(
				Paths.voices(PlayState.SONG.song, PlayState.storyDifficultyStr)
			);
			FlxG.sound.list.add(v);
			owner.vocals.add(v);
		}

		owner.vocals.pause();
		owner.vocals.time = 0;
	}
}
