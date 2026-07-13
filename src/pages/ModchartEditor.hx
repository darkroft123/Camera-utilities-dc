package pages;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;

import game.Conductor;
import game.SoundGroup;
import states.PlayState;
import states.MusicBeatState;

import camera.ModifierRegistry;
import camera.CameraModifiers;
import camera.ModchartData.ModifierEntry;
import camera.ModchartData.TimelineModifierPlacement;
import camera.ModchartData.CameraEventsSaveData;

import atoms.ColorConstants;

import organisms.AudioController;
import organisms.SongInfoDisplay;
import organisms.PreviewCamera;
import organisms.MenuBar;
import organisms.ModifierTimeline;
import organisms.ModifierBlock;

import templates.EditorLayout;

import substates.MenuDropdownSubState;
import substates.ModifyModifierPopup;
import utilities.Options;

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

	// --- CNE 8-camera setup ---
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;
	public var camEditor:FlxCamera;
	public var camEditorTop:FlxCamera;
	public var camTimelineList:FlxCamera;
	public var camTimelineValues:FlxCamera;
	public var camTimelineEdit:FlxCamera;
	public var camTimeline:FlxCamera;

	public var uiCam(get, never):FlxCamera;
	function get_uiCam():FlxCamera return camEditorTop;

	public var modifierTimeline:ModifierTimeline;
	public var loadedModifiers:Array<ModifierEntry> = [];
	public var timelinePlacements:Array<TimelineModifierPlacement> = [];
	public var snapToGrid:Bool = true;
	public var isPreviewFullscreen:Bool = false;

	public var activeModifierType:String = "";
	public var selectedPlacement:TimelineModifierPlacement = null;
	public var editionPanelText:FlxText;

	public var editValueInput:flixel.addons.ui.FlxUIInputText;
	public var editDurationInput:flixel.addons.ui.FlxUIInputText;
	public var saveEditBtn:flixel.addons.ui.FlxUIButton;
	public var deleteEditBtn:flixel.addons.ui.FlxUIButton;
	public var editTypeDropdown:flixel.addons.ui.FlxUIDropDownMenu;
	public var editEaseDropdown:flixel.addons.ui.FlxUIDropDownMenu;

	var lastScreenWidth:Int = 0;
	var lastScreenHeight:Int = 0;

	// --- CNE visual elements ---
	var timelineWindowBg:FlxSprite;
	var timelineWindowTitle:FlxText;
	public var timelineHoverBox:FlxSprite;
	var timelineRowBgs:FlxTypedGroup<FlxSprite>;
	public var modifierNamesTexts:FlxTypedGroup<FlxText>;
	public var modifierValuesTexts:FlxTypedGroup<FlxText>;
	public var durationScrollbar:molecules.Scrollbar;
	public var verticalScrollbar:molecules.Scrollbar;

	override function create()
	{
		instance = this;
		super.create();
		FlxG.mouse.visible = true;

		ModifierRegistry.definitions.clear();
		CameraModifiers.init();

		// --- CNE 8-camera setup with proper ordering ---
		camGame = FlxG.camera;
		camGame.bgColor = FlxColor.TRANSPARENT;

		camHUD = new FlxCamera();
		camHUD.bgColor = 0;

		camOther = new FlxCamera();
		camOther.bgColor = 0;

		camEditor = new FlxCamera();
		camEditor.bgColor = 0xFF191524;

		camEditorTop = new FlxCamera();
		camEditorTop.bgColor = 0;

		var tY = Std.int(EditorLayout.timelineCamY);
		var tH = Std.int(EditorLayout.timelineCamH);
		var editCamX = EditorLayout.LIST_COL_W + EditorLayout.VALUES_COL_W + (EditorLayout.SEP_W * 2);

		camTimelineList = new FlxCamera(0, tY, EditorLayout.LIST_COL_W, tH);
		camTimelineList.bgColor = 0;

		camTimelineValues = new FlxCamera(EditorLayout.LIST_COL_W, tY, EditorLayout.VALUES_COL_W, tH);
		camTimelineValues.bgColor = 0;

		camTimelineEdit = new FlxCamera(editCamX, tY, EditorLayout.EDIT_COL_W + EditorLayout.SEP_W, tH);
		camTimelineEdit.bgColor = 0;

		camTimeline = new FlxCamera(EditorLayout.GRID_COL_X, tY, EditorLayout.GRID_COL_W, tH);
		camTimeline.bgColor = 0;

		// Add cameras bottom→top
		FlxG.cameras.add(camGame);      // gameplay (default)
		FlxG.cameras.add(camEditor);    // dark bg for editor area
		FlxG.cameras.add(camOther);     // transparent overlay

		// Preview camera renders above editor bg
		editorPreview = new PreviewCamera(this);
		editorPreview.create(); // adds previewCam to list

		// Timeline cameras render above preview
		FlxG.cameras.add(camTimelineList);
		FlxG.cameras.add(camTimelineValues);

		// camHUD renders above timeline list/values (strums, HUD elements)
		FlxG.cameras.add(camHUD);

		// camTimeline renders above camHUD (grid, cursor, modifier blocks visible on top)
		FlxG.cameras.add(camTimeline);

		// camEditorTop renders above timeline (top bar, menus, substates)
		FlxG.cameras.add(camEditorTop);

		// camTimelineEdit renders ON TOP OF EVERYTHING (edit panel inputs need mouse priority)
		FlxG.cameras.add(camTimelineEdit);
		FlxG.camera = camGame;

		// --- CNE Timeline Window (bottom panel) ---
		timelineWindowBg = new FlxSprite(0, EditorLayout.timelineWindowY);
		timelineWindowBg.makeGraphic(FlxG.width, EditorLayout.TIMELINE_HEIGHT, 0xFF1A1A2E);
		timelineWindowBg.scrollFactor.set(0, 1);
		timelineWindowBg.cameras = [camEditor];
		add(timelineWindowBg);

		timelineWindowTitle = new FlxText(8, EditorLayout.timelineWindowY + 5, 200, "TIMELINE", 16);
		timelineWindowTitle.setFormat(Paths.font("vcr.ttf"), 16, 0xFFCCCCCC);
		timelineWindowTitle.scrollFactor.set(0, 1);
		timelineWindowTitle.cameras = [camEditor];
		add(timelineWindowTitle);

		// --- CNE Value column background (dark blue-gray) ---
		var valueBg = new FlxSprite(0, 0);
		valueBg.makeGraphic(EditorLayout.VALUES_COL_W, Std.int(tH), 0xff302e32);
		valueBg.scrollFactor.set(0, 0);
		valueBg.cameras = [camTimelineValues];
		add(valueBg);

		// --- CNE Edition column background ---
		var editionBg = new FlxSprite(0, 0);
		editionBg.makeGraphic(EditorLayout.EDIT_COL_W, Std.int(tH), 0xff252329);
		editionBg.scrollFactor.set(0, 0);
		editionBg.cameras = [camTimelineEdit];
		add(editionBg);

		// --- CNE Separator lines between columns ---
		var sep1 = new FlxSprite(0, 0);
		sep1.makeGraphic(EditorLayout.SEP_W, Std.int(tH), 0xFFCCCCCC);
		sep1.scrollFactor.set(0, 0);
		sep1.cameras = [camTimelineList];
		add(sep1);

		var sep2 = new FlxSprite(0, 0);
		sep2.makeGraphic(EditorLayout.SEP_W, Std.int(tH), 0xFFCCCCCC);
		sep2.scrollFactor.set(0, 0);
		sep2.cameras = [camTimelineValues];
		add(sep2);

		var sep3 = new FlxSprite(0, 0);
		sep3.makeGraphic(EditorLayout.SEP_W, Std.int(tH), 0xFFCCCCCC);
		sep3.scrollFactor.set(0, 0);
		sep3.cameras = [camTimelineEdit];
		add(sep3);

		editionPanelText = new FlxText(10, 10, EditorLayout.EDIT_COL_W - 20, "No event selected.\n\nClick an event on the grid to edit it,\nor click a modifier on the left to place it.", 12);
		editionPanelText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFFFFFF, "left");
		editionPanelText.scrollFactor.set(0, 0);
		editionPanelText.cameras = [camTimelineEdit];
		add(editionPanelText);

		var ex = 10;
		var ey = 80;

		var durLabel = new FlxText(ex, ey, 60, "Duration:", 12);
		durLabel.scrollFactor.set();
		durLabel.cameras = [camTimelineEdit]; add(durLabel);
		editDurationInput = new flixel.addons.ui.FlxUIInputText(ex + 65, ey, 50, "4", 12, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		editDurationInput.scrollFactor.set();
		editDurationInput.cameras = [camTimelineEdit]; add(editDurationInput);

		var valLabel = new FlxText(ex, ey + 30, 60, "Value:", 12);
		valLabel.scrollFactor.set();
		valLabel.cameras = [camTimelineEdit]; add(valLabel);
		editValueInput = new flixel.addons.ui.FlxUIInputText(ex + 65, ey + 30, 50, "0", 12, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		editValueInput.scrollFactor.set();
		editValueInput.cameras = [camTimelineEdit]; add(editValueInput);

		var typeLabel = new FlxText(ex, ey + 60, 60, "Type:", 12);
		typeLabel.scrollFactor.set();
		typeLabel.cameras = [camTimelineEdit]; add(typeLabel);
		
		var easeLabel = new FlxText(ex, ey + 90, 60, "Ease:", 12);
		easeLabel.scrollFactor.set();
		easeLabel.cameras = [camTimelineEdit]; add(easeLabel);

		saveEditBtn = new flixel.addons.ui.FlxUIButton(ex, ey + 150, "Save", function() {
			if (selectedPlacement != null) {
				var parsedDur = Std.parseInt(editDurationInput.text);
				selectedPlacement.duration = (parsedDur != null) ? parsedDur : 1;
				selectedPlacement.value = Std.parseFloat(editValueInput.text);
				if (Math.isNaN(selectedPlacement.value)) selectedPlacement.value = 0;
				selectedPlacement.type = editTypeDropdown.selectedId;
				selectedPlacement.ease = editEaseDropdown.selectedId;
				if (modifierTimeline != null) modifierTimeline.loadPlacements();
			}
		});
		saveEditBtn.scrollFactor.set();
		saveEditBtn.cameras = [camTimelineEdit]; add(saveEditBtn);

		deleteEditBtn = new flixel.addons.ui.FlxUIButton(ex + 90, ey + 150, "Delete", function() {
			if (selectedPlacement != null) {
				timelinePlacements.remove(selectedPlacement);
				selectedPlacement = null;
				setEditionUIVisible(false);
				if (modifierTimeline != null) modifierTimeline.loadPlacements();
			}
		});
		deleteEditBtn.scrollFactor.set();
		deleteEditBtn.cameras = [camTimelineEdit]; add(deleteEditBtn);

		editEaseDropdown = new flixel.addons.ui.FlxUIDropDownMenu(ex + 65, ey + 90, flixel.addons.ui.FlxUIDropDownMenu.makeStrIdLabelArray(["linear", "sineIn", "sineOut", "sineInOut", "quadIn", "quadOut", "quadInOut", "cubeIn", "cubeOut", "cubeInOut"]), function(id:String) {});
		editEaseDropdown.scrollFactor.set();
		editEaseDropdown.cameras = [camTimelineEdit]; add(editEaseDropdown);

		editTypeDropdown = new flixel.addons.ui.FlxUIDropDownMenu(ex + 65, ey + 60, flixel.addons.ui.FlxUIDropDownMenu.makeStrIdLabelArray(["tween", "set"]), function(id:String) {});
		editTypeDropdown.scrollFactor.set();
		editTypeDropdown.cameras = [camTimelineEdit]; add(editTypeDropdown);

		setEditionUIVisible(false);

		// --- CNE Alternating row backgrounds ---
		timelineRowBgs = new FlxTypedGroup<FlxSprite>();
		add(timelineRowBgs);

		modifierNamesTexts = new FlxTypedGroup<FlxText>();
		add(modifierNamesTexts);

		modifierValuesTexts = new FlxTypedGroup<FlxText>();
		add(modifierValuesTexts);

		// --- CNE Hover box ---
		timelineHoverBox = new FlxSprite(-100, 0);
		timelineHoverBox.makeGraphic(Std.int(EditorLayout.ROW_SIZE_X), Std.int(EditorLayout.ROW_SIZE_Y), 0x44FFFF00);
		timelineHoverBox.scrollFactor.set(1, 1);
		timelineHoverBox.cameras = [camTimeline];
		timelineHoverBox.visible = false;
		add(timelineHoverBox);

		// --- Scrollbars ---
		var tY = Std.int(EditorLayout.timelineCamY);
		var tH = Std.int(EditorLayout.timelineCamH);
		var maxScrollY = Math.max(0, (loadedModifiers.length * EditorLayout.ROW_SIZE_Y) - tH);

		// Horizontal scrollbar (Duration)
		durationScrollbar = new molecules.Scrollbar(
			this,
			EditorLayout.GRID_COL_X,
			EditorLayout.timelineWindowY + 8,
			Std.int(EditorLayout.GRID_COL_W),
			15,
			0,
			100,
			true,
			camEditor
		);
		durationScrollbar.track.scrollFactor.set(0, 1);
		durationScrollbar.thumb.scrollFactor.set(0, 1);
		durationScrollbar.onValueChange = function(val)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.time = val;
				if (vocals != null) vocals.time = val;
				Conductor.songPosition = val;
				recalculateSteps();
			}
		};

		// Vertical scrollbar (Gap / Modifier List scroll)
		verticalScrollbar = new molecules.Scrollbar(
			this,
			FlxG.width - 15,
			tY,
			15,
			Std.int(tH - 18),
			0,
			maxScrollY,
			false,
			camEditor
		);
		verticalScrollbar.track.scrollFactor.set(0, 1);
		verticalScrollbar.thumb.scrollFactor.set(0, 1);
		verticalScrollbar.onValueChange = function(val)
		{
			camTimeline.scroll.y = val;
			camTimelineList.scroll.y = val;
			camTimelineValues.scroll.y = val;
		};

		// --- Top bar background (renders UNDER menu) ---
		var topBar = new FlxSprite(0, 0);
		topBar.makeGraphic(FlxG.width, EditorLayout.TOPBAR_HEIGHT, ColorConstants.TOPBAR);
		topBar.cameras = [camEditorTop];
		add(topBar);

		// --- Top menu bar ---
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

		// --- Song info (right-aligned at top-right) ---
		songInfo = new SongInfoDisplay();
		songInfo.create(this);
		songPosInfo.cameras = [camEditorTop];
		songedits.cameras = [camEditorTop];

		audio = new AudioController(this);
		audio.create(this);

		Conductor.changeBPM(PlayState.SONG.bpm);
		Conductor.songPosition = 0;

		// --- Timeline component ---
		modifierTimeline = new ModifierTimeline(this);
		add(modifierTimeline);

		loadCameraEvents();
		modifierTimeline.loadPlacements();
		buildTimelineRows();
	}

	public function buildTimelineRows():Void
	{
		timelineRowBgs.clear();
		if (modifierNamesTexts != null) modifierNamesTexts.clear();
		if (modifierValuesTexts != null) modifierValuesTexts.clear();

		var rowCount = Std.int(Math.max(loadedModifiers.length, 10));
		for (i in 0...rowCount)
		{
			var bg = new FlxSprite(0, i * Std.int(EditorLayout.ROW_SIZE_Y));
			bg.makeGraphic(Std.int(FlxG.width), Std.int(EditorLayout.ROW_SIZE_Y), FlxColor.TRANSPARENT, true);
			var pixels = bg.pixels;
			var fillRect = new openfl.geom.Rectangle(0, 0, bg.width, bg.height);
			var color = (i % 2 == 0) ? 0xFF545454 : 0xFF272727;
			pixels.fillRect(fillRect, color);
			bg.dirty = true;
			bg.scrollFactor.set(0, 1);
			bg.cameras = [camTimeline, camTimelineList, camTimelineValues];
			timelineRowBgs.add(bg);

			if (i < loadedModifiers.length && modifierNamesTexts != null && modifierValuesTexts != null)
			{
				var mod = loadedModifiers[i];

				var nameText = new FlxText(8, i * EditorLayout.ROW_SIZE_Y + 2, EditorLayout.LIST_COL_W - 16, mod.name, 12);
				nameText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE);
				nameText.scrollFactor.set(0, 1);
				nameText.cameras = [camTimelineList];
				modifierNamesTexts.add(nameText);

				var valText = new FlxText(4, i * EditorLayout.ROW_SIZE_Y + 2, EditorLayout.VALUES_COL_W - 8, Std.string(mod.value), 12);
				valText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, "center");
				valText.scrollFactor.set(0, 1);
				valText.cameras = [camTimelineValues];
				modifierValuesTexts.add(valText);
			}
		}
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
					case 1: toggleSwapScroll();
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

		// Fullscreen: timeline slides down, top bar stays
		if (isPreviewFullscreen)
		{
			camEditor.scroll.y += (-360 - camEditor.scroll.y) * 0.15;
			if (Math.abs(-360 - camEditor.scroll.y) < 0.1) camEditor.scroll.y = -360;
		}
		else
		{
			camEditor.scroll.y += (0 - camEditor.scroll.y) * 0.15;
			if (Math.abs(0 - camEditor.scroll.y) < 0.1) camEditor.scroll.y = 0;
		}
		camEditorTop.scroll.y = 0; // top bar always visible

		// Timeline cameras follow editor scroll to hide/reveal
		var timelineY = EditorLayout.timelineCamY - camEditor.scroll.y;
		camTimelineList.y = timelineY;
		camTimelineValues.y = timelineY;
		if (camTimelineEdit != null) camTimelineEdit.y = timelineY;
		camTimeline.y = timelineY;

		if (subState == null) menuBar.updateHover(this);

		if (FlxG.keys.justPressed.SPACE)
		{
			var isTyping = (editValueInput != null && editValueInput.hasFocus) || (editDurationInput != null && editDurationInput.hasFocus);
			if (!isTyping) {
				if (FlxG.sound.music.playing) pauseSong(); else resumeSong();
			}
		}

		// Keyboard Timeline Navigation (Left/Right)
		var isTyping = (editValueInput != null && editValueInput.hasFocus) || (editDurationInput != null && editDurationInput.hasFocus);
		if (!isTyping)
		{
			if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
			{
				var bpm = (Conductor.bpm > 0) ? Conductor.bpm : 120;
				var crochet = (60 / bpm) * 1000;
				var steps = FlxG.keys.pressed.SHIFT ? 16 : 1;
				var mult = FlxG.keys.justPressed.LEFT ? -1 : 1;
				var targetTime = Conductor.songPosition + (crochet * steps * mult);
				var songLen = (FlxG.sound.music != null) ? FlxG.sound.music.length : 60000;
				if (targetTime < 0) targetTime = 0;
				if (targetTime > songLen) targetTime = songLen;
				Conductor.songPosition = targetTime;
				if (FlxG.sound.music != null)
				{
					if (FlxG.sound.music.playing) pauseSong();
					FlxG.sound.music.time = targetTime;
					if (vocals != null) vocals.time = targetTime;
				}
				recalculateSteps();
			}
		}

		curStep = recalculateSteps();

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

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

		if (songStarted && FlxG.sound.music != null)
		{
			if (FlxG.sound.music.time >= FlxG.sound.music.length - 5)
			{
				resetSong();
				if (modifierTimeline != null) modifierTimeline.scrollX = 0;
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
			onResize(FlxG.width, FlxG.height);
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

		// --- Timeline Mouse Interaction (Zoom, Scroll, Seek, Hover Box) ---
		var mouseX = FlxG.mouse.x;
		var mouseY = FlxG.mouse.y;
		var timelineWindowY = EditorLayout.timelineWindowY;

		if (mouseY >= timelineWindowY && mouseY < FlxG.height && subState == null)
		{
			// 1. Mouse wheel zoom & vertical scroll
			if (FlxG.mouse.wheel != 0)
			{
				if (FlxG.keys.pressed.CONTROL)
				{
					// Zoom horizontally
					modifierTimeline.zoomX += FlxG.mouse.wheel * 2.0;
					if (modifierTimeline.zoomX < 5.0) modifierTimeline.zoomX = 5.0;
					if (modifierTimeline.zoomX > 50.0) modifierTimeline.zoomX = 50.0;
				}
				else
				{
					// Scroll vertically
					var targetScrollY = camTimeline.scroll.y + (-FlxG.mouse.wheel * EditorLayout.ROW_SIZE_Y);
					var maxScrollY = Math.max(0, (loadedModifiers.length * EditorLayout.ROW_SIZE_Y) - EditorLayout.timelineCamH);
					if (targetScrollY < 0) targetScrollY = 0;
					if (targetScrollY > maxScrollY) targetScrollY = maxScrollY;

					camTimeline.scroll.y = targetScrollY;
					camTimelineList.scroll.y = targetScrollY;
					camTimelineValues.scroll.y = targetScrollY;
				}
			}

			// 2. Click interactions
			var isDraggingScrollbar = (durationScrollbar != null && durationScrollbar.isDragging) || (verticalScrollbar != null && verticalScrollbar.isDragging);
			
			if (FlxG.mouse.justPressed && !isDraggingScrollbar)
			{
				var listTotalW = EditorLayout.LIST_COL_W + EditorLayout.VALUES_COL_W;
				
				// A. Clicking the Modifier List (Left Column)
				if (mouseX >= 0 && mouseX < listTotalW && mouseY > timelineWindowY + EditorLayout.TOPBAR_HEIGHT)
				{
					var listMouseY = mouseY - (timelineWindowY + EditorLayout.TOPBAR_HEIGHT) + camTimelineList.scroll.y;
					var rowIndex = Math.floor(listMouseY / EditorLayout.ROW_SIZE_Y);
					if (rowIndex >= 0 && rowIndex < loadedModifiers.length)
					{
						activeModifierType = loadedModifiers[rowIndex].modifier;
						selectedPlacement = null;
						editValueInput.text = "0";
						editDurationInput.text = "4";
						editTypeDropdown.selectedLabel = "tween";
						editEaseDropdown.selectedLabel = "linear";
						updateEditionUI();
					}
				}
				
				// B. Clicking the Grid Area (Right Column)
				if (mouseX >= EditorLayout.GRID_COL_X && mouseX < FlxG.width * 0.8)
				{
					// B1. Clicking the Ruler (Top Bar) -> Seek Song
					if (mouseY <= timelineWindowY + EditorLayout.TOPBAR_HEIGHT)
					{
						var bpm = (Conductor.bpm > 0) ? Conductor.bpm : 120;
						var crochet = (60 / bpm) * 1000;
						var clickBeat = (mouseX - EditorLayout.GRID_COL_X + modifierTimeline.scrollX) / modifierTimeline.zoomX;
						var targetTime = clickBeat * crochet;
						var songLen = (FlxG.sound.music != null) ? FlxG.sound.music.length : 60000;
						if (targetTime < 0) targetTime = 0;
						if (targetTime > songLen) targetTime = songLen;

						if (FlxG.sound.music != null) FlxG.sound.music.time = targetTime;
						if (vocals != null) vocals.time = targetTime;
						Conductor.songPosition = targetTime;
						recalculateSteps();
					}
					// B2. Clicking the Grid (Timeline) -> Select or Place Block
					else
					{
						var gridMouseX = mouseX - EditorLayout.GRID_COL_X + modifierTimeline.scrollX;
						var gridMouseY = mouseY - (timelineWindowY + EditorLayout.TOPBAR_HEIGHT) + camTimeline.scroll.y;

						var clickedBlock:organisms.ModifierBlock = null;
						if (modifierTimeline != null)
						{
							modifierTimeline.modifierBlocks.forEachAlive(function(block:organisms.ModifierBlock) {
								if (gridMouseX >= block.x && gridMouseX <= block.x + block.bg.width &&
									gridMouseY >= block.y && gridMouseY <= block.y + block.bg.height) {
									clickedBlock = block;
								}
							});
						}

						if (clickedBlock != null)
						{
							if (selectedPlacement != clickedBlock.data) {
								selectedPlacement = clickedBlock.data;
								updateEditionUI();
							}
						}
						else
						{
							if (activeModifierType == "") activeModifierType = "cameraZoom";
							var hoverBeat = Math.floor(gridMouseX / modifierTimeline.zoomX);
							var parsedVal = Std.parseFloat(editValueInput.text);
							if (Math.isNaN(parsedVal)) parsedVal = 0;
							var parsedDur = Std.parseInt(editDurationInput.text);
							if (parsedDur == null || parsedDur <= 0) parsedDur = 4;
							var newPlacement:camera.ModchartData.TimelineModifierPlacement = {
								beat: hoverBeat,
								duration: parsedDur,
								type: editTypeDropdown.selectedId,
								modifierRef: activeModifierType,
								ease: editEaseDropdown.selectedId,
								value: parsedVal
							};
							timelinePlacements.push(newPlacement);
							selectedPlacement = newPlacement;
							updateEditionUI();
							modifierTimeline.loadPlacements();
						}
					}
				}
			}

			// C. Hover box positioning & Song seek drag
			if (mouseX >= EditorLayout.GRID_COL_X && mouseX < FlxG.width)
			{
				if (FlxG.mouse.pressed && !isDraggingScrollbar && mouseY <= timelineWindowY + EditorLayout.TOPBAR_HEIGHT)
				{
					// Dragging on the ruler to seek continuously
					var bpm = (Conductor.bpm > 0) ? Conductor.bpm : 120;
					var crochet = (60 / bpm) * 1000;
					var clickBeat = (mouseX - EditorLayout.GRID_COL_X + modifierTimeline.scrollX) / modifierTimeline.zoomX;
					var targetTime = clickBeat * crochet;
					var songLen = (FlxG.sound.music != null) ? FlxG.sound.music.length : 60000;
					if (targetTime < 0) targetTime = 0;
					if (targetTime > songLen) targetTime = songLen;

					if (FlxG.sound.music != null) FlxG.sound.music.time = targetTime;
					if (vocals != null) vocals.time = targetTime;
					Conductor.songPosition = targetTime;
					recalculateSteps();
				}

				if (timelineHoverBox != null && modifierTimeline != null && mouseY > timelineWindowY + EditorLayout.TOPBAR_HEIGHT)
				{
					timelineHoverBox.visible = true;
					var gridMouseX = mouseX - EditorLayout.GRID_COL_X + modifierTimeline.scrollX;
					var gridMouseY = mouseY - (timelineWindowY + EditorLayout.TOPBAR_HEIGHT) + camTimeline.scroll.y;

					var hoverBeat = Math.floor(gridMouseX / modifierTimeline.zoomX);
					var hoverRow = Math.floor(gridMouseY / EditorLayout.ROW_SIZE_Y);

					timelineHoverBox.x = hoverBeat * modifierTimeline.zoomX - modifierTimeline.scrollX;
					timelineHoverBox.y = hoverRow * EditorLayout.ROW_SIZE_Y;
					
					timelineHoverBox.setGraphicSize(Std.int(modifierTimeline.zoomX), Std.int(EditorLayout.ROW_SIZE_Y));
					timelineHoverBox.updateHitbox();
				}
				else
				{
					if (timelineHoverBox != null) timelineHoverBox.visible = false;
				}
			}
			else
			{
				if (timelineHoverBox != null) timelineHoverBox.visible = false;
			}
		}
		else
		{
			if (timelineHoverBox != null) timelineHoverBox.visible = false;
		}

		if (modifierNamesTexts != null)
		{
			for (i in 0...loadedModifiers.length)
			{
				if (i < modifierNamesTexts.length)
				{
					var t = modifierNamesTexts.members[i];
					if (t != null)
					{
						if (activeModifierType == loadedModifiers[i].modifier)
							t.color = 0xFFFFFF00;
						else
							t.color = 0xFFFFFFFF;
					}
				}
			}
		}

		evaluateAllCameraData(curDecStep);
		if (editorPreview != null) editorPreview.update(elapsed);
		if (modifierTimeline != null) modifierTimeline.update(elapsed);

		// --- Update and Sync Scrollbars ---
		if (durationScrollbar != null)
		{
			var songLen = (FlxG.sound.music != null) ? FlxG.sound.music.length : 60000;
			durationScrollbar.setRange(0, songLen);
			if (!durationScrollbar.isDragging)
			{
				durationScrollbar.setValue(Conductor.songPosition);
			}
			durationScrollbar.update();
		}

		if (verticalScrollbar != null)
		{
			var maxScrollY = Math.max(0, (loadedModifiers.length * EditorLayout.ROW_SIZE_Y) - EditorLayout.timelineCamH);
			verticalScrollbar.setRange(0, maxScrollY);
			if (!verticalScrollbar.isDragging)
			{
				verticalScrollbar.setValue(camTimeline.scroll.y);
			}
			verticalScrollbar.update();
		}
	}

	function updateEditionUI() {
		if (selectedPlacement != null) {
			editionPanelText.text = "EDIT EVENT: " + selectedPlacement.modifierRef + "\n@ Beat " + selectedPlacement.beat;
			editDurationInput.text = Std.string(selectedPlacement.duration);
			editValueInput.text = Std.string(selectedPlacement.value);
			editTypeDropdown.selectedLabel = selectedPlacement.type;
			editEaseDropdown.selectedLabel = (selectedPlacement.ease != null) ? selectedPlacement.ease : "linear";
			setEditionUIVisible(true);
		} else if (activeModifierType != "") {
			editionPanelText.text = "Click the timeline grid to place:\n" + activeModifierType;
			setEditionUIVisible(true);
		} else {
			editionPanelText.text = "No event selected.\n\nClick a modifier on the left\nto select it, then click\nthe grid to place it.";
			setEditionUIVisible(false);
		}
	}

	function setEditionUIVisible(v:Bool) {
		if (editDurationInput != null) editDurationInput.visible = v;
		if (editValueInput != null) editValueInput.visible = v;
		if (editTypeDropdown != null) editTypeDropdown.visible = v;
		if (editEaseDropdown != null) editEaseDropdown.visible = v;
		if (saveEditBtn != null) saveEditBtn.visible = v && selectedPlacement != null;
		if (deleteEditBtn != null) deleteEditBtn.visible = v && selectedPlacement != null;
	}

	override function beatHit():Void
	{
		super.beatHit();
		if (editorPreview != null)
			editorPreview.beatHit();
	}

	override function onResize(Width:Int, Height:Int):Void
	{
		super.onResize(Width, Height);
		timelineWindowBg.setGraphicSize(FlxG.width, EditorLayout.TIMELINE_HEIGHT);
		timelineWindowBg.updateHitbox();
	}

	function recalculateSteps():Int
	{
		var lastChange = { stepTime: 0, songTime: 0.0, bpm: 0.0 };
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
		var rawStep = lastChange.stepTime + (sourceTime - lastChange.songTime) / Conductor.stepCrochet;
		curStep = Std.int(rawStep);
		curDecStep = rawStep;
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

	public function getModifierValue(modifierId:String, step:Float):Float
	{
		var defVal = ModifierRegistry.getDefaultValue(modifierId);
		var result = defVal;
		for (pl in timelinePlacements)
		{
			if (pl.modifierRef != modifierId) continue;
			var placementStep = pl.beat * 4;
			var dur:Float = (pl.duration != null && pl.duration > 0) ? pl.duration : 1;
			if (step < placementStep) continue;

			var offset:Float = pl.value;
			if (pl.type == "tween" && step < placementStep + dur)
			{
				var t = (step - placementStep) / dur;
				if (pl.ease != null && pl.ease != "linear") t = atoms.EaseUtils.fromName(pl.ease)(t);
				offset *= t;
			}
			result += offset;
		}
		return result;
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
			catch (e:Dynamic) { trace("Error loading cameraevents.json: " + e); }
		}
		#end
	}

	public function saveCameraEvents(forceDialog:Bool = false):Void
	{
		var data:CameraEventsSaveData = { modifiers: loadedModifiers, placements: timelinePlacements };
		var jsonStr = haxe.Json.stringify(data, "\t");
		if (forceDialog)
		{
			new openfl.net.FileReference().save(jsonStr, "cameraevents.json");
			return;
		}
		#if sys
		try
		{
			var path = getCameraEventsPath();
			var dir = haxe.io.Path.directory(path);
			if (!sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir);
			sys.io.File.saveContent(path, jsonStr);
		}
		catch (e:Dynamic)
		{
			new openfl.net.FileReference().save(jsonStr, "cameraevents.json");
		}
		#else
		new openfl.net.FileReference().save(jsonStr, "cameraevents.json");
		#end
	}

	public function toggleFullscreenPreview():Void
	{
		isPreviewFullscreen = !isPreviewFullscreen;
	}

	public function toggleSwapScroll():Void
	{
		var cur = Options.getData("downscroll") == true;
		Options.setData(!cur, "downscroll");
		if (editorPreview != null) editorPreview.repositionStrums();
	}

	override function destroy()
	{
		@:privateAccess FlxCamera._defaultCameras = null;
		super.destroy();
	}
}
