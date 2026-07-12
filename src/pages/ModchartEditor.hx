package pages;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxCamera;

import game.Conductor;
import game.SoundGroup;
import game.Conductor.BPMChangeEvent;
import states.PlayState;
import states.MusicBeatState;

import camera.ModifierRegistry;
import camera.CameraModifiers;
import camera.ModchartData;

import atoms.ColorConstants;
import atoms.EaseUtils;

import organisms.Background;
import organisms.AudioController;
import organisms.SongInfoDisplay;
import organisms.PreviewCamera;
import organisms.MenuBar;
import organisms.ModifierTimeline;
import organisms.ModifierList;
import organisms.ModifierEditor;

import templates.EditorLayout;

import substates.MenuDropdownSubState;
import substates.ModifyModifierPopup;

typedef MenuData =
{
	var name:String;
	var items:Array<String>;
}

class ModchartEditor extends MusicBeatState
{
	public static var instance:ModchartEditor;

	#if FLX_PITCH
	var playbackSpeed:Float = 1;
	#end
	public var vocals:SoundGroup;

	public var menus:Array<MenuData>;
	public var menuButtons:Array<FlxText> = [];
	public var menuButtonBGs:Array<FlxSprite> = [];

	var menuBg:FlxSprite;
	var menuItems:Array<FlxText> = [];
	var menuItemBGs:Array<FlxSprite> = [];

	public var activeMenuIndex:Int = -1;
	var selectedItemIndex:Int = -1;
	var ignoreNextClick:Bool = false;

	public var songPosInfo:FlxText;
	public var songedits:FlxText;

	public var beatSnap:Int = 16;
	public var curSection:Int = 0;

	var menuBar:MenuBar;
	public var audio:AudioController;
	var songInfo:SongInfoDisplay;
	public var editorPreview:PreviewCamera;
	public var uiCam:FlxCamera;
	public var previewCam:FlxCamera;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camEditor:FlxCamera;
	public var camEditorTop:FlxCamera;
	public var camBG:FlxCamera;

	public var modifierTimeline:ModifierTimeline;
	public var modifierList:ModifierList;
	public var modifierEditor:ModifierEditor;
	public var loadedModifiers:Array<ModifierEntry> = [];
	public var timelinePlacements:Array<TimelineModifierPlacement> = [];
	public var snapToGrid:Bool = true;
	public var isPreviewFullscreen:Bool = false;
	var camTween:FlxTween;

	var lastScreenWidth:Int = 0;
	var lastScreenHeight:Int = 0;

	override function create()
	{
		instance = this;
		super.create();
		FlxG.mouse.visible = true;

		ModifierRegistry.definitions.clear();
		CameraModifiers.init();

		camBG = new FlxCamera();
		FlxG.cameras.add(camBG, false);

		camGame = FlxG.camera;
		camGame.bgColor = FlxColor.TRANSPARENT;
		previewCam = camGame;

		camEditor = new FlxCamera();
		camEditor.bgColor = 0;
		FlxG.cameras.add(camEditor, false);

		camEditorTop = new FlxCamera();
		camEditorTop.bgColor = 0;
		FlxG.cameras.add(camEditorTop, false);

		// Reorder FlxG.cameras.list to put camBG at index 0 so it renders first (under the gameplay)
		FlxG.cameras.list.remove(camBG);
		FlxG.cameras.list.remove(camGame);
		FlxG.cameras.list.remove(camEditor);
		FlxG.cameras.list.remove(camEditorTop);

		FlxG.cameras.list.push(camBG);
		FlxG.cameras.list.push(camGame);
		FlxG.cameras.list.push(camEditor);
		FlxG.cameras.list.push(camEditorTop);

		FlxG.camera = camGame;
		@:privateAccess FlxCamera._defaultCameras = [camGame];

		uiCam = camEditor;

		var background = new Background(this);
		background.bg.cameras = [camBG];

		// CNE-style: single editor background panel covering bottom half
		var editorBg = new FlxSprite(0, EditorLayout.editorDefaultY - 30);
		editorBg.makeGraphic(FlxG.width, Std.int(FlxG.height - EditorLayout.editorDefaultY + 30), ColorConstants.PANEL_DARK);
		editorBg.scrollFactor.set(0, 0);
		editorBg.cameras = [camEditor];
		add(editorBg);

		var barrita = new FlxSprite(0, 0);
		barrita.makeGraphic(FlxG.width * 2, EditorLayout.TOPBAR_HEIGHT, ColorConstants.TOPBAR);
		barrita.screenCenter(X);
		barrita.cameras = [camEditorTop];
		add(barrita);

		songInfo = new SongInfoDisplay();
		songInfo.create(this);
		songPosInfo.cameras = [camEditorTop];
		songedits.cameras = [camEditorTop];

		menus = [
			{name:"File", items:["Save","Save As","Exit"]},
			{name:"Edit", items:["Copy","Paste","Cut","Delete","Shift Selection Left","Shift Selection Right"]},
			{name:"Modchart", items:["Create Modifier"]},
			{name:"View", items:["Fullscreen","Swap Scroll"]},
			{name:"Playback", items:["Play/Pause","+ speed 25%","reset speed","- speed 25%"]},
			{name:"Song", items:["Go back to the start","Go to the end","Mute Inst","Mute Vocals"]},
			{name:"Snap >", items:["16","20","24"]}
		];

		menuBar = new MenuBar(camEditorTop);
		menuBar.create(this);

		audio = new AudioController(this);
		audio.create(this);

		Conductor.changeBPM(PlayState.SONG.bpm);
		Conductor.songPosition = 0;

		editorPreview = new PreviewCamera(this);
		editorPreview.create(this);
		camHUD = editorPreview.camHUD;

		var editorY = EditorLayout.editorDefaultY;

		modifierList = new ModifierList(this, camEditor);
		modifierList.setY(editorY);
		modifierList.onModifierSelected = function(index:Int) {
			if (index >= 0 && index < loadedModifiers.length)
				modifierEditor.loadEntry(loadedModifiers[index]);
			else
				modifierEditor.clearEditor();
		};
		add(modifierList);

		modifierEditor = new ModifierEditor(this, camEditor);
		add(modifierEditor);

		var rightPanelX = EditorLayout.rightPanelX;
		var rightW = EditorLayout.rightPanelDefaultW;
		var rightH = EditorLayout.rightPanelDefaultH;
		modifierTimeline = new ModifierTimeline(this, camEditor, rightPanelX, editorY, rightW, rightH);
		add(modifierTimeline);

		loadCameraEvents();
		modifierTimeline.loadPlacements();
		modifierList.rebuildList();
	}

	public function handleMenuAction(menuName:String, itemIndex:Int):Void
	{
		switch (menuName)
		{
			case "File":
				switch (itemIndex)
				{
					case 0: saveCameraEvents(false);
					case 1: saveCameraEvents(true);
					case 2:
						if (FlxG.sound.music != null) FlxG.sound.music.stop();
						FlxG.switchState(() -> new PlayState());
				}

			case "Modchart":
				switch (itemIndex)
				{
					case 0: openModifierEditor();
				}

			case "View":
				switch (itemIndex)
				{
					case 0: toggleFullscreenPreview();
					case 1: trace("Swap Scroll Mode");
				}

			case "Snap >":
				beatSnap = Std.parseInt(menus[activeMenuIndex].items[itemIndex]);

			case "Playback":
				switch (itemIndex)
				{
					case 0:
						if (FlxG.sound.music.playing) pauseSong(); else resumeSong();
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

			case "Song":
				switch (itemIndex)
				{
					case 0: resetSong();
					case 1:
						if (FlxG.sound.music != null)
						{
							var targetTime = Math.max(0, FlxG.sound.music.length - 100);
							FlxG.sound.music.time = targetTime;
							if (vocals != null) vocals.time = targetTime;
							Conductor.songPosition = targetTime;
						}
					case 2:
						audio.toggleMuteInst();
						menus[5].items[2] = audio.instMuted ? "Unmute Inst" : "Mute Inst";
					case 3:
						audio.toggleMuteVocals();
						menus[5].items[3] = audio.vocalsMuted ? "Unmute Vocals" : "Mute Vocals";
				}
		}
	}

	public function openMenu(index:Int):Void
	{
		activeMenuIndex = index;
		menuBar.setActiveColors(this, index);
		openSubState(new MenuDropdownSubState(this, index));
	}

	public function closeMenu():Void
	{
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

	var songStarted:Bool = false;

	function pauseSong():Void
	{
		if (FlxG.sound.music != null)
		{
			Conductor.songPosition = FlxG.sound.music.time;
			FlxG.sound.music.pause();
		}
		if (vocals != null) vocals.pause();
		recalculateSteps();
	}

	function resumeSong():Void
	{
		if (!songStarted) { startSong(); return; }

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.resume();
			vocals.resume();
			vocals.time = FlxG.sound.music.time;
			Conductor.songPosition = FlxG.sound.music.time;
			recalculateSteps();
		}
	}

	function resetSong():Void
	{
		pauseSong();
		FlxG.sound.music.time = 0;
		vocals.time = 0;
		Conductor.songPosition = 0;
		curStep = 0;
		curBeat = 0;
		curSection = 0;
		songStarted = false;
		Conductor.changeBPM(PlayState.SONG.bpm);
		recalculateSteps();
	}

	function applyPlaybackSpeed():Void
	{
		#if FLX_PITCH
		if (FlxG.sound.music != null) FlxG.sound.music.pitch = playbackSpeed;
		if (vocals != null) vocals.pitch = playbackSpeed;
		#end
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// CNE-style: Lerp editor UI scrolls to slide off-screen when fullscreen
		var targetScrollY = isPreviewFullscreen ? -360.0 : 0.0;
		camEditor.scroll.y += (targetScrollY - camEditor.scroll.y) * 0.15;
		if (Math.abs(targetScrollY - camEditor.scroll.y) < 0.1) camEditor.scroll.y = targetScrollY;

		var targetTopScrollY = isPreviewFullscreen ? 100.0 : 0.0;
		camEditorTop.scroll.y += (targetTopScrollY - camEditorTop.scroll.y) * 0.15;
		if (Math.abs(targetTopScrollY - camEditorTop.scroll.y) < 0.1) camEditorTop.scroll.y = targetTopScrollY;

		if (subState == null) menuBar.updateHover(this);

		if (FlxG.keys.justPressed.SPACE)
		{
			if (FlxG.sound.music.playing) pauseSong(); else resumeSong();
		}

		curStep = recalculateSteps();

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}

		if (songStarted && FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			var nextSection = curSection;
			while (nextSection + 1 < PlayState.SONG.notes.length
				&& FlxG.sound.music.time >= sectionStartTime(nextSection + 1))
			{
				nextSection++;
			}
			if (nextSection != curSection) changeSection(nextSection, false);
		}

		if (controls.RIGHT_P || controls.LEFT_P)
		{
			var totalSteps = (FlxG.sound.music != null && Conductor.stepCrochet > 0) ? (FlxG.sound.music.length / Conductor.stepCrochet) : 1000.0;
			var visibleSteps = modifierTimeline.gridW / modifierTimeline.zoomX;
			var maxScroll = Math.max(0, totalSteps - visibleSteps);
			var shiftThing:Int = FlxG.keys.pressed.SHIFT ? 4 : 1;
			var stepMove = shiftThing * 16;
			if (controls.RIGHT_P) modifierTimeline.scrollX += stepMove;
			if (controls.LEFT_P) modifierTimeline.scrollX -= stepMove;
			modifierTimeline.scrollX = FlxMath.bound(modifierTimeline.scrollX, 0, maxScroll);
			modifierTimeline.timelineScroll.setValue(modifierTimeline.scrollX);
			modifierTimeline.drawGrid();
		}

		if (songStarted && FlxG.sound.music != null)
		{
			if (FlxG.sound.music.time >= FlxG.sound.music.length - 5)
			{
				resetSong();
				if (modifierTimeline != null) modifierTimeline.scrollX = 0;
				if (modifierList != null) modifierList.rebuildList();
				if (editorPreview != null)
				{
					editorPreview.resetModifiers();
					editorPreview.resetNotes();
				}
				resumeSong();
			}
		}

		songInfo.updateDisplay(this);

		if (lastScreenWidth != FlxG.width || lastScreenHeight != FlxG.height)
		{
			lastScreenWidth = FlxG.width;
			lastScreenHeight = FlxG.height;

			if (modifierTimeline != null)
			{
				modifierTimeline.resize(EditorLayout.rightPanelX, EditorLayout.editorDefaultY, EditorLayout.rightPanelDefaultW, EditorLayout.rightPanelDefaultH);
			}
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			if (menuBg != null) closeMenu();
			else
			{
				if (FlxG.sound.music != null) FlxG.sound.music.stop();
				FlxG.switchState(() -> new PlayState());
			}
		}

		evaluateAllCameraData(curDecStep);
		if (editorPreview != null) editorPreview.update(elapsed);
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = { stepTime: 0, songTime: 0, bpm: 0 };

		var sourceTime = Conductor.songPosition;
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			sourceTime = FlxG.sound.music.time;
			Conductor.songPosition = sourceTime;
		}

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (sourceTime > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((sourceTime - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();
		return curStep;
	}

	function sectionStartTime(?section:Int):Float
	{
		if (section == null) section = curSection;

		var time:Float = 0;
		var bpm:Float = PlayState.SONG.bpm;

		for (i in 0...section)
		{
			var sec = PlayState.SONG.notes[i];
			if (sec.changeBPM) bpm = sec.bpm;
			time += Conductor.timeScale[0] * (60 / bpm) * 1000;
		}

		return time;
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (PlayState.SONG.notes[sec] != null)
		{
			curSection = sec;
			if (updateMusic)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition = FlxG.sound.music.time = vocals.time = sectionStartTime(sec);
				updateCurStep();
			}
		}
	}

	public function getModifierValue(modifierId:String, step:Float):Float
	{
		var defVal = ModifierRegistry.getDefaultValue(modifierId);
		var result = defVal;

		for (entry in loadedModifiers)
		{
			if (entry.modifier != modifierId) continue;

			if (entry.type == "set")
			{
				result = entry.value;
			}
			else if (entry.type == "tween")
			{
				var dur:Float = (entry.duration != null && entry.duration > 0) ? entry.duration : 1;
				if (step >= dur)
				{
					result = entry.value;
				}
				else
				{
					var t = step / dur;
					if (entry.ease != null && entry.ease != "linear")
						t = EaseUtils.fromName(entry.ease)(t);
					result = FlxMath.lerp(defVal, entry.value, t);
				}
			}
		}

		for (pl in timelinePlacements)
		{
			if (pl.modifierRef != modifierId) continue;

			var placementStep = pl.beat * 4;
			var dur:Float = (pl.duration != null && pl.duration > 0) ? pl.duration : 1;

			if (pl.type == "set")
			{
				if (step >= placementStep) result = pl.value;
			}
			else if (pl.type == "tween")
			{
				if (step >= placementStep && step < placementStep + dur)
				{
					var t = (step - placementStep) / dur;
					if (pl.ease != null && pl.ease != "linear") t = EaseUtils.fromName(pl.ease)(t);
					result = FlxMath.lerp(defVal, pl.value, t);
				}
				else if (step >= placementStep + dur)
				{
					result = pl.value;
				}
			}
		}

		return result;
	}

	public function evaluateAllCameraData(step:Float):Void
	{
		if (editorPreview != null) editorPreview.resetModifiers();

		for (defId in ModifierRegistry.definitions.keys())
		{
			var def = ModifierRegistry.definitions.get(defId);
			ModifierRegistry.applyModifier(defId, def.defaultValue, this);
		}

		for (defId in ModifierRegistry.definitions.keys())
		{
			var val = getModifierValue(defId, step);
			ModifierRegistry.applyModifier(defId, val, this);
		}
	}

	public function openModifierEditor():Void
	{
		openSubState(new ModifyModifierPopup(this));
	}

	public function getCameraEventsPath():String
	{
		var songFolder = PlayState.SONG.song.toLowerCase();
		#if sys
		var paths = [
			"mods/data/" + songFolder + "/cameraevents.json",
			"assets/data/" + songFolder + "/cameraevents.json"
		];
		for (path in paths)
		{
			if (sys.FileSystem.exists(path) || sys.FileSystem.exists(haxe.io.Path.directory(path)))
				return path;
		}
		return "assets/data/" + songFolder + "/cameraevents.json";
		#else
		return "cameraevents.json";
		#end
	}

	public function loadCameraEvents():Void
	{
		loadedModifiers = [];
		timelinePlacements = [];

		#if sys
		var path = getCameraEventsPath();
		if (sys.FileSystem.exists(path))
		{
			try
			{
				var content = sys.io.File.getContent(path);
				var data:CameraEventsSaveData = haxe.Json.parse(content);
				if (data.modifiers != null) loadedModifiers = data.modifiers;
				if (data.placements != null) timelinePlacements = data.placements;
			}
			catch (e:Dynamic)
			{
				trace("Error loading cameraevents.json: " + e);
			}
		}
		#end
	}

	public function saveCameraEvents(forceDialog:Bool = false):Void
	{
		var data:CameraEventsSaveData = {
			modifiers: loadedModifiers,
			placements: timelinePlacements
		};

		var jsonStr = haxe.Json.stringify(data, "\t");

		if (forceDialog)
		{
			var fileRef = new openfl.net.FileReference();
			fileRef.save(jsonStr, "cameraevents.json");
			return;
		}

		#if sys
		try
		{
			var path = getCameraEventsPath();
			var dir = haxe.io.Path.directory(path);
			if (!sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir);
			sys.io.File.saveContent(path, jsonStr);
			trace("Saved camera events to " + path);
		}
		catch (e:Dynamic)
		{
			trace("Error saving camera events directly: " + e);
			var fileRef = new openfl.net.FileReference();
			fileRef.save(jsonStr, "cameraevents.json");
		}
		#else
		var fileRef = new openfl.net.FileReference();
		fileRef.save(jsonStr, "cameraevents.json");
		#end
	}

	public function toggleFullscreenPreview():Void
	{
		isPreviewFullscreen = !isPreviewFullscreen;
	}

	override function destroy()
	{
		@:privateAccess FlxCamera._defaultCameras = null;
		super.destroy();
	}
}
