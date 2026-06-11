package components;

import flixel.sound.FlxSound;
import game.SoundGroup;

class AudioComponent
{
	public var music:FlxSound;
	public var vocals:SoundGroup;
	public var playbackSpeed:Float = 1;

	public function new() {}

	public function load(instPath:String, ?voicePath:String)
	{
		music = new FlxSound().loadEmbedded(instPath);
		vocals = new SoundGroup(2);

		if (voicePath != null)
		{
			var v = new FlxSound().loadEmbedded(voicePath);
			vocals.add(v);
		}
	}

	public function play()
	{
		music.play();
		vocals.play();
	}

	public function pause()
	{
		music.pause();
		vocals.pause();
	}

	public function resume()
	{
		music.resume();
		vocals.resume();
		vocals.time = music.time;
	}

	public function setSpeed(v:Float)
	{
		playbackSpeed = v;
		#if FLX_PITCH
		music.pitch = v;
		vocals.pitch = v;
		#end
	}
}