package camera;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;

import game.Conductor;
import game.SoundGroup;
import game.SongLoader;
import states.PlayState;
import states.MusicBeatState;
import states.MainMenuState;
import components.MenuBarComponent;
import components.AudioComponent;
import components.SongInfoComponent;
import camera.utilities.CameraUtilities;
class ModchartFX extends MusicBeatState
{
	var songStarted:Bool = false;

	#if FLX_PITCH
	var playbackSpeed:Float = 1;
	#end

	var beatSnap:Int = 16;
	var curSection:Int = 0;

	var audio:AudioComponent;
	var menuBar:MenuBarComponent;
	var songInfo:SongInfoComponent;
	var menus:Array<MenuData>;

	var activeMenuIndex:Int = -1;
	var selectedItemIndex:Int = -1;
	var ignoreNextClick:Bool = false;

	var menuBg:FlxSprite;
	var menuItems:Array<FlxText> = [];
	var menuItemBGs:Array<FlxSprite> = [];

	var songPosInfo:FlxText;
	var songedits:FlxText;

	var cubogris:FlxSprite;
	var cubonegro:FlxSprite;
	var lineablanca:FlxSprite;


	override function create()
	{
		super.create();
		FlxG.mouse.visible = true;

		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.fromRGB(25,21,36));
		bg.screenCenter();
		add(bg);

		
		var barrita = new FlxSprite();
		barrita.makeGraphic(FlxG.width * 2, 30, FlxColor.BLACK);
		barrita.screenCenter(X);
		add(barrita);

		menus = [
			{name:"File", items:["Save","Exit"]},
			{name:"Edit", items:["Copy","Paste","Cut","Delete","Shift Left","Shift Right"]},
			{name:"Modchart", items:["Edit Modifiers"]},
			{name:"View", items:["Fullscreen","Swap Scroll"]},
			{name:"Playback", items:["Play/Pause","+ speed 25%","reset speed","- speed 25%"]},
			{name:"Song", items:["Start","End","Mute Inst","Mute Vocals"]},
			{name:"Snap >", items:["16","20","24"]}
		];

		

		audio = new AudioComponent();

		menuBar = new MenuBarComponent(menus, openMenu);

		songInfo = new SongInfoComponent();

		

		songPosInfo = songInfo.posText;
		songedits = songInfo.songText;

		add(songPosInfo);
		add(songedits);


		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}

		audio.load(
			Paths.inst(PlayState.SONG.song, PlayState.storyDifficultyStr),
			PlayState.SONG.needsVoices
				? Paths.voices(PlayState.SONG.song, PlayState.storyDifficultyStr)
				: null
		);

		FlxG.sound.music = audio.music;
		FlxG.sound.list.add(FlxG.sound.music);

		audio.pause();

		Conductor.changeBPM(PlayState.SONG.bpm);
		Conductor.songPosition = 0;

		songStarted = false;
	}


	function handleMenuAction(menuName:String, itemIndex:Int):Void
	{
		switch (menuName)
		{
			case "Snap >":
				beatSnap = Std.parseInt(menus[activeMenuIndex].items[itemIndex]);

			case "Playback":
				switch (itemIndex)
				{
					case 0:
						if (FlxG.sound.music.playing)
							pauseSong();
						else
							resumeSong();

					case 1:
						audio.setSpeed(audio.playbackSpeed + 0.25);

					case 2:
						audio.setSpeed(1);

					case 3:
						audio.setSpeed(audio.playbackSpeed - 0.25);
				}
		}
	}

	// ================= MENU =================
	function openMenu(index:Int)
	{
		if (activeMenuIndex == index)
		{
			closeMenu();
			return;
		}

		closeMenu();
		activeMenuIndex = index;

		menuBar.buttonBGs[index].color = FlxColor.WHITE;

		var btnBg = menuBar.buttonBGs[index];
		var items = menus[index].items;

		menuBg = new FlxSprite(btnBg.x, btnBg.y + btnBg.height);
		menuBg.makeGraphic(200, items.length * 32 + 16, FlxColor.WHITE);
		add(menuBg);

		menuItems = [];
		menuItemBGs = [];

		for (i in 0...items.length)
		{
			var bg = new FlxSprite(menuBg.x, menuBg.y + 8 + i * 32);
			bg.makeGraphic(200, 32, FlxColor.WHITE);
			add(bg);

			var txt = new FlxText(bg.x, bg.y, 200, items[i], 20);
			add(txt);

			menuItemBGs.push(bg);
			menuItems.push(txt);
		}
	}

	function closeMenu()
	{
		if (menuBg != null) menuBg.kill();
		menuBg = null;

		for (t in menuItems) t.kill();
		for (b in menuItemBGs) b.kill();

		menuItems = [];
		menuItemBGs = [];

		activeMenuIndex = -1;
		selectedItemIndex = -1;
		ignoreNextClick = false;
	}

	// ================= AUDIO =================
	function startSong()
	{
		audio.play();
		Conductor.songPosition = 0;
		curSection = 0;
		songStarted = true;
	}

	function pauseSong()
	{
		audio.pause();
	}

	function resumeSong()
	{
		if (!songStarted)
		{
			startSong();
			return;
		}

		audio.resume();
		Conductor.songPosition = FlxG.sound.music.time;
	}

	function resetSong()
	{
		pauseSong();
		FlxG.sound.music.time = 0;
		Conductor.songPosition = 0;
		curSection = 0;
		songStarted = false;
	}

	// ================= UPDATE =================
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// MENU BAR
		menuBar.update();

		// MENU CLICK LOGIC
		for (i in 0...menuBar.buttonBGs.length)
		{
			if (FlxG.mouse.overlaps(menuBar.buttonBGs[i]) && FlxG.mouse.justPressed)
				openMenu(i);
		}

		// MENU ITEMS CLICK
		if (menuBg != null)
		{
			for (i in 0...menuItems.length)
			{
				if (FlxG.mouse.overlaps(menuItems[i]) && FlxG.mouse.justPressed)
					selectedItemIndex = i;
			}
		}

		if (selectedItemIndex != -1 && activeMenuIndex != -1)
		{
			handleMenuAction(menus[activeMenuIndex].name, selectedItemIndex);
			closeMenu();
		}

		// SPACE PLAY/PAUSE
		if (FlxG.keys.justPressed.SPACE)
		{
			if (FlxG.sound.music.playing) pauseSong();
			else resumeSong();
		}

		// SONG INFO VIA COMPONENT
		songInfo.updateInfo(
			PlayState.SONG.song,
			PlayState.storyDifficultyStr,
			CameraUtilities.timeToStr(Conductor.songPosition),
			curStep,
			curBeat,
			curSection,
			Conductor.bpm
		);

		// BACK
		if (controls.BACK)
		{
			if (menuBg != null) closeMenu();
			else FlxG.switchState(() -> new MainMenuState());
		}
	}
}