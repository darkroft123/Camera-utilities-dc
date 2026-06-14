package camera;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import game.Conductor;
import game.SoundGroup;
import states.PlayState;
import game.SongLoader;
import flixel.math.FlxMath;
import game.SongLoader.Section as SwagSection;
import flixel.sound.FlxSound;
import game.Conductor.BPMChangeEvent;
import states.MusicBeatState;
import states.MainMenuState;
import components.MenuBarComponent;
import components.MenuDropdownComponent;
import components.AudioComponent;
import components.SongInfoComponent;
import components.SongBackgroundComponent;

@:publicFields
typedef MenuData =
{
	var name:String;
	var items:Array<String>;
}

@:publicFields
class ModchartFX extends MusicBeatState
{
	var songStarted:Bool = false;
	#if FLX_PITCH
		var playbackSpeed:Float = 1;
		#end
	var vocals:SoundGroup;
	//colores del si
	public static inline var COL_TOPBAR = FlxColor.BLACK;
	public static inline var COL_BTN_NORMAL = FlxColor.BLACK;
	public static inline var COL_BTN_ACTIVE = FlxColor.WHITE;
	public static inline var COL_TXT_NORMAL = FlxColor.WHITE;
	public static inline var COL_TXT_ACTIVE = FlxColor.BLACK;
	public static inline var COL_MENU_BG = FlxColor.WHITE;
	public static inline var COL_MENU_TXT = FlxColor.BLACK;

	var menus:Array<MenuData>;
	var menuButtons:Array<FlxText> = [];
	var menuButtonBGs:Array<FlxSprite> = [];

	var menuBg:FlxSprite;
	var menuItems:Array<FlxText> = [];
	var menuItemBGs:Array<FlxSprite> = [];

	var activeMenuIndex:Int = -1;
	var selectedItemIndex:Int = -1;
	var ignoreNextClick:Bool = false;

	var songPosInfo:FlxText;
	var songedits:FlxText;
	var cubogris:FlxSprite;
	var cubonegro:FlxSprite;
	var lineablanca:FlxSprite;

	var beatSnap:Int = 16;
	var curSection:Int = 0;

	var menuBar:MenuBarComponent;
	var menuDropdown:MenuDropdownComponent;
	var audio:AudioComponent;
	var songInfo:SongInfoComponent;

	override function create()
	{
		super.create();
		FlxG.mouse.visible = true;

		var bg = new FlxSprite(0, 0);
		bg.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.fromRGB(25,21,36));
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		var barrita = new FlxSprite(0, 0);
		barrita.makeGraphic(FlxG.width * 2, 30, COL_TOPBAR);
		barrita.screenCenter(X);
		barrita.y += 1;
		add(barrita);

		songInfo = new SongInfoComponent(this);
		songInfo.create(this);

		new SongBackgroundComponent(this);

		menus = [
			{name:"File", items:["Save","Exit"]},
			{name:"Edit", items:["Copy","Paste","Cut","Delete","Shift Selection Left","Shift Selection Right"]},
			{name:"Modchart", items:["Edit Modifiers"]},
			{name:"View", items:["Fullscreen","Swap Scroll"]},
			{name:"Playback", items:["Play/Pause","+ speed 25%","reset speed","- speed 25%"]},
			{name:"Song", items:["Go back to the start","Go to the end","Mute instrumental","Mute voices"]},
			{name:"Snap >", items:["16","20","24"]}
		];

		menuBar = new MenuBarComponent(this);
		menuBar.create(this);

		menuDropdown = new MenuDropdownComponent(this);

		audio = new AudioComponent(this);
		audio.create(this);

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
					playbackSpeed += 0.25;
					if (playbackSpeed > 3.0) playbackSpeed = 3.0;
					applyPlaybackSpeed();

				case 2:
					playbackSpeed = 1.0;
					applyPlaybackSpeed();

				case 3:
					playbackSpeed -= 0.25;
					if (playbackSpeed < 0.5) playbackSpeed = 0.5;
					applyPlaybackSpeed();

			}
	}
}

	function openMenu(index:Int)
{
    if (activeMenuIndex == index)
    {
        closeMenu();
        return;
    }

    closeMenu();
    activeMenuIndex = index;
    ignoreNextClick = true;

    menuBar.setActiveColors(this, index);
    menuDropdown.build(this, index);
}


	function closeMenu()
{
    if (menuBg == null) return;

    menuDropdown.close(this);

    activeMenuIndex = -1;
    selectedItemIndex = -1;
    ignoreNextClick = false;

    menuBar.resetColors(this);
}


	function startSong():Void
	{
		FlxG.sound.music.time = 0;
		vocals.time = 0;

		FlxG.sound.music.play(false);
		vocals.play(false);

		Conductor.songPosition = 0;
		curStep = 0;
		curBeat = 0;

		songStarted = true;
	}


	function pauseSong():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();

		if (vocals != null)
			vocals.pause();
	}

	function resumeSong():Void
	{
		if (!songStarted)
		{
			startSong();
			return;
		}

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.resume();
			vocals.resume();

			vocals.time = FlxG.sound.music.time;
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}


	function resetSong():Void {
		pauseSong();
		FlxG.sound.music.time = 0;
		vocals.time = 0;
		Conductor.songPosition = 0;
		curStep = 0;
		curBeat = 0;
		curSection = 0; 
		songStarted = false;
	}


	function applyPlaybackSpeed():Void
	{
		#if FLX_PITCH
		if (FlxG.sound.music != null)
			FlxG.sound.music.pitch = playbackSpeed;

		if (vocals != null)
			vocals.pitch = playbackSpeed;
		#end
	}



	override function update(elapsed:Float)
{
	super.update(elapsed);
	menuBar.updateHover(this);
	menuDropdown.updateItems(this);

	if (selectedItemIndex != -1 && activeMenuIndex != -1)
	{
		handleMenuAction(menus[activeMenuIndex].name, selectedItemIndex);
		closeMenu();
	}

	menuDropdown.updateOutsideClick(this);
	if (FlxG.keys.justPressed.SPACE)
	{
		if (FlxG.sound.music.playing)
			pauseSong();
		else
			resumeSong();
	}
	
	curStep = recalculateSteps();
	if (FlxG.sound.music != null)
	{
		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	

	if (songStarted && FlxG.sound.music != null && FlxG.sound.music.playing) {
		var nextSection = curSection;

		while (nextSection + 1 < PlayState.SONG.notes.length &&
			FlxG.sound.music.time >= sectionStartTime(nextSection + 1)) {
			nextSection++;
		}

		if (nextSection != curSection) {
			changeSection(nextSection, false); 
		}
	}

				var shiftThing:Int = 1;

			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;
			if ((controls.RIGHT_P)) {
				if (sectionStartTime(curSection + shiftThing) >= (!PlayState.SONG.needsVoices ? FlxG.sound.music.length : Math.min(FlxG.sound.music.length,
					vocals.maxLength))) {
					changeSection(0);
				} else {
					changeSection(curSection + shiftThing);
				}
			}
			if ((controls.LEFT_P)) {
				changeSection(curSection - shiftThing);
			}

			/*if (controls.RIGHT_P && control) {   cart editor
				if (NoteVariables.beats.indexOf(beatSnap) + 1 <= NoteVariables.beats.length - 1)
					beatSnap = NoteVariables.beats[NoteVariables.beats.indexOf(beatSnap) + 1];
			}

			if (controls.LEFT_P && control) {
				if (NoteVariables.beats.indexOf(beatSnap) - 1 >= 0)
					beatSnap = NoteVariables.beats[NoteVariables.beats.indexOf(beatSnap) - 1];
			}*/


	if (songStarted && FlxG.sound.music != null)
	{
		if (FlxG.sound.music.time >= FlxG.sound.music.length - 5)
		{
			resetSong();
		}
	}

	songInfo.updateDisplay(this);

	if (controls.BACK)
	{
		if (menuBg != null) closeMenu();
		else
		{
			if (FlxG.sound.music != null)

			FlxG.switchState(() -> new MainMenuState());
		}
	}
}
function recalculateSteps():Int {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}

		for (i in 0...Conductor.bpmChangeMap.length) {
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}
function resetSection(songBeginning:Bool = false):Void {
		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning) {
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();
	}

	function sectionStartTime(?section:Int):Float {
		if (section == null)
			section = curSection;

		var time:Float = 0;
		var bpm:Float = PlayState.SONG.bpm;

		for (i in 0...section) {
			var sec = PlayState.SONG.notes[i];
			if (sec.changeBPM) bpm = sec.bpm;

			// coso del section
			time += Conductor.timeScale[0] * (60 / bpm) * 1000;
		}

		return time;
	}



	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void {
		if ( PlayState.SONG.notes[sec] != null) {
			curSection = sec;

			if (updateMusic) {
				FlxG.sound.music.pause();
				vocals.pause();

				Conductor.songPosition = FlxG.sound.music.time = vocals.time = sectionStartTime(sec);
				updateCurStep();
			}

		}
	}
}
