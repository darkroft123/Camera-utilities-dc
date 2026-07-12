package organisms;

import flixel.FlxG;
import flixel.sound.FlxSound;
import game.SoundGroup;
import states.PlayState;
import pages.ModchartEditor;

class AudioController
{
	public var instMuted:Bool = false;
	public var vocalsMuted:Bool = false;

	var state:ModchartEditor;

	public function new(state:ModchartEditor)
	{
		this.state = state;
	}

	public function create(owner:ModchartEditor):Void
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

		applyMuteInst();
		applyMuteVocals();
	}

	public function toggleMuteInst():Void
	{
		instMuted = !instMuted;
		applyMuteInst();
	}

	public function toggleMuteVocals():Void
	{
		vocalsMuted = !vocalsMuted;
		applyMuteVocals();
	}

	public function applyMuteInst():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.volume = instMuted ? 0.0 : 1.0;
	}

	public function applyMuteVocals():Void
	{
		if (state.vocals != null)
			state.vocals.volume = vocalsMuted ? 0.0 : 1.0;
	}
}
