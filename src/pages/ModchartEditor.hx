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
	public var hasUnsavedChanges:Bool = false;
	public var autoSaveEnabled:Bool = true;
	var autoSaveTimer:Float = 0;

	public static function getColorForModifier(modName:String):FlxColor
	{
		var hash = 0;
		for (i in 0...modName.length) {
			hash = modName.charCodeAt(i) + ((hash << 5) - hash);
		}
		var hue = Math.abs(hash % 360);
		return flixel.util.FlxColor.fromHSL(hue, 0.8, 0.5);
	}

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
	public var isDraggingBlock:Bool = false;
	public var lastGridClickTime:Int = 0;
	public var selectedPlacement:TimelineModifierPlacement = null;
	public var copiedPlacement:TimelineModifierPlacement = null;
	public var editionPanelText:FlxText;
	public var ghostBlock:FlxSprite;

	public var editValueInput:flixel.addons.ui.FlxUIInputText;
	public var editDurationInput:flixel.addons.ui.FlxUIInputText;
	public var saveEditBtn:flixel.addons.ui.FlxUIButton;
	public var deleteEditBtn:flixel.addons.ui.FlxUIButton;
	public var editTypeDropdown:flixel.addons.ui.FlxUIDropDownMenu;
	public var editEaseDropdown:flixel.addons.ui.FlxUIDropDownMenu;
	public var editSongModDropdown:flixel.addons.ui.FlxUIDropDownMenu;
	public var editSongModLabel:FlxText;
	public var editEventNameInput:flixel.addons.ui.FlxUIInputText;
	public var editEventNameLabel:FlxText;
	public var songStartPlacement:camera.ModchartData.SongStartData = null;
	public var editDurLabel:FlxText;
	public var editValLabel:FlxText;
	public var editTypeLabel:FlxText;
	public var editEaseLabel:FlxText;
	public var editRepeatCheckbox:flixel.addons.ui.FlxUICheckBox;
	public var editEaseTextLabel:FlxText;
	public var editEaseTextInput:flixel.addons.ui.FlxUIInputText;
	public var editRepeatCountInput:flixel.addons.ui.FlxUIInputText;
	public var editRepeatCountLabel:FlxText;
	public var editRepeatGapInput:flixel.addons.ui.FlxUIInputText;
	public var editRepeatGapLabel:FlxText;

	public var draggedRowIndex:Int = -1;
	public var draggedRowOriginalY:Float = 0;
	public var dragStartMouseY:Float = 0;

	public var unrolledPlacements:Array<camera.ModchartData.TimelineModifierPlacement> = [];

	public function refreshUnrolledPlacements():Void
	{
		unrolledPlacements = [];
		for (pl in timelinePlacements) {
			if (pl.repeat == null || pl.repeat[0] != true) {
				unrolledPlacements.push(pl);
			} else {
				var rCount:Int = Std.int(pl.repeat[1]);
				var rGap:Float = pl.repeat[2];
				unrolledPlacements.push(pl);
				for (j in 1...(rCount + 1)) {
					var duplicated:camera.ModchartData.TimelineModifierPlacement = {
						modifierRef: pl.modifierRef,
						value: pl.value,
						type: pl.type,
						duration: pl.duration,
						ease: pl.ease,
						beat: pl.beat + (j * rGap),
						repeat: (pl.repeat != null) ? [pl.repeat[0], pl.repeat[1], pl.repeat[2]] : null
					};
					unrolledPlacements.push(duplicated);
				}
			}
		}
		unrolledPlacements.sort(function(a, b) return (a.beat < b.beat) ? -1 : ((a.beat > b.beat) ? 1 : 0));
	}

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
		var editCamX = EditorLayout.LIST_COL_W + (EditorLayout.SEP_W * 2);

		camTimelineList = new FlxCamera(0, tY, EditorLayout.LIST_COL_W, tH);
		camTimelineList.bgColor = 0;

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
		FlxG.cameras.add(camTimelineEdit);
		FlxG.cameras.add(camTimeline);

		// camHUD renders above timeline list/values (strums, HUD elements)
		FlxG.cameras.add(camHUD);

		// camEditorTop renders ABOVE EVERYTHING (top bar, menus, substates, edit panel)
		// Full-screen viewport: clicks on areas w/o objects fall through to camTimelineEdit
		FlxG.cameras.add(camEditorTop);
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

		// --- CNE Edition column background ---
		// Deleted per user request - using the global timelineWindowBg instead

		// --- CNE Separator lines between columns ---
		var sep1 = new FlxSprite(0, 0);
		sep1.makeGraphic(EditorLayout.SEP_W, Std.int(tH), 0xFFCCCCCC);
		sep1.scrollFactor.set(0, 0);
		sep1.cameras = [camTimelineList];
		add(sep1);

		var sep3 = new FlxSprite(0, 0);
		sep3.makeGraphic(EditorLayout.SEP_W, Std.int(tH), 0xFFCCCCCC);
		sep3.scrollFactor.set(0, 0);
		sep3.cameras = [camTimelineEdit];
		add(sep3);

		var eCam = camEditorTop;
		var eScreenX = Std.int(EditorLayout.LIST_COL_W + (EditorLayout.SEP_W * 2));
		var editPanelOffsetX = eScreenX + 10;
		var editPanelOffsetY_Base = 80;
		var eScreenY = tY;

		editionPanelText = new FlxText(editPanelOffsetX, eScreenY + 10, EditorLayout.EDIT_COL_W - 20, "No event selected.\n\nClick an event on the grid to edit it,\nor click a modifier on the left to place it.", 12);
		editionPanelText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFFFFFFF, "left");
		editionPanelText.scrollFactor.set(0, 0);
		editionPanelText.cameras = [eCam];
		add(editionPanelText);

		editDurLabel = new FlxText(editPanelOffsetX, eScreenY + editPanelOffsetY_Base, 100, "Duration:", 12);
		editDurLabel.scrollFactor.set();
		editDurLabel.cameras = [eCam]; add(editDurLabel);
		editDurationInput = new flixel.addons.ui.FlxUIInputText(editPanelOffsetX + 65, eScreenY + editPanelOffsetY_Base, 50, "1", 12, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		editDurationInput.scrollFactor.set();
		editDurationInput.cameras = [eCam]; add(editDurationInput);
		editDurationInput.callback = function(text:String, action:String) {
			if (selectedPlacement != null) {
				var parsed = Std.parseFloat(text);
				if (!Math.isNaN(parsed) && parsed > 0) {
					selectedPlacement.duration = parsed;
					hasUnsavedChanges = true;
					if (modifierTimeline != null) modifierTimeline.loadPlacements();
				}
			} else if (activeModifierType == "songStart" && songStartPlacement != null) {
				var parsed = Std.parseFloat(text);
				if (!Math.isNaN(parsed) && parsed > 0) {
					songStartPlacement.duration = parsed;
					hasUnsavedChanges = true;
				}
			}
		};

		editValLabel = new FlxText(editPanelOffsetX, eScreenY + editPanelOffsetY_Base + 30, 60, "Value:", 12);
		editValLabel.scrollFactor.set();
		editValLabel.cameras = [eCam]; add(editValLabel);
		editValueInput = new flixel.addons.ui.FlxUIInputText(editPanelOffsetX + 65, eScreenY + editPanelOffsetY_Base + 30, 50, "0", 12, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		editValueInput.scrollFactor.set();
		editValueInput.cameras = [eCam]; add(editValueInput);
		editValueInput.callback = function(text:String, action:String) {
			if (selectedPlacement != null) {
				var parsed = Std.parseFloat(text);
				if (!Math.isNaN(parsed)) {
					selectedPlacement.value = parsed;
					hasUnsavedChanges = true;
					if (modifierTimeline != null) modifierTimeline.loadPlacements();
				}
			} else if (activeModifierType == "songStart" && songStartPlacement != null) {
				var parsed = Std.parseFloat(text);
				if (!Math.isNaN(parsed)) {
					songStartPlacement.value = parsed;
					hasUnsavedChanges = true;
				}
			}
		};

		editTypeLabel = new FlxText(editPanelOffsetX, eScreenY + editPanelOffsetY_Base + 60, 60, "Type:", 12);
		editTypeLabel.scrollFactor.set();
		editTypeLabel.cameras = [eCam]; add(editTypeLabel);
		
		editEaseLabel = new FlxText(editPanelOffsetX, eScreenY + editPanelOffsetY_Base + 90, 60, "Ease:", 12);
		editEaseLabel.scrollFactor.set();
		editEaseLabel.cameras = [eCam]; add(editEaseLabel);
		editEventNameLabel = new FlxText(editPanelOffsetX, eScreenY + editPanelOffsetY_Base + 150, 60, "Event:", 12);
		editEventNameLabel.scrollFactor.set(0, 0);
		editEventNameLabel.cameras = [camTimelineEdit];
		add(editEventNameLabel);

		editEventNameInput = new flixel.addons.ui.FlxUIInputText(editPanelOffsetX + 65, eScreenY + editPanelOffsetY_Base + 150, 80, "cameracenter", 12, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		editEventNameInput.scrollFactor.set(0, 0);
		editEventNameInput.cameras = [camTimelineEdit];
		add(editEventNameInput);

		var eCam = camEditor;

		var rx1 = editPanelOffsetX + 220;
		editRepeatCheckbox = new flixel.addons.ui.FlxUICheckBox(rx1, eScreenY + editPanelOffsetY_Base, null, null, "Repeat", 60);
		editRepeatCheckbox.scrollFactor.set();
		editRepeatCheckbox.cameras = [eCam];
		add(editRepeatCheckbox);
		editRepeatCheckbox.callback = function() {
			if (selectedPlacement == null) return;
			if (editRepeatCheckbox.checked) {
				var rc = Std.parseInt(editRepeatCountInput.text);
				if (rc == null || Math.isNaN(rc)) rc = 1;
				var rg = Std.parseFloat(editRepeatGapInput.text);
				if (Math.isNaN(rg)) rg = 1.0;
				selectedPlacement.repeat = [true, rc, rg];
			} else {
				selectedPlacement.repeat = null;
			}
			hasUnsavedChanges = true;
			if (modifierTimeline != null) modifierTimeline.loadPlacements();
			refreshUnrolledPlacements();
		};

		var rx3 = editPanelOffsetX + 220;
		editRepeatCountLabel = new FlxText(rx3, eScreenY + editPanelOffsetY_Base + 27, 150, "Repeat count:", 10);
		editRepeatCountLabel.scrollFactor.set();
		editRepeatCountLabel.cameras = [eCam];
		editRepeatCountLabel.color = 0xFFAAAAAA;
		add(editRepeatCountLabel);
		editRepeatCountInput = new flixel.addons.ui.FlxUIInputText(rx3, eScreenY + editPanelOffsetY_Base + 40, 40, "1", 12, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		editRepeatCountInput.scrollFactor.set();
		editRepeatCountInput.cameras = [eCam];
		add(editRepeatCountInput);
		editRepeatCountInput.callback = function(text:String, action:String) {
			if (selectedPlacement == null || !editRepeatCheckbox.checked) return;
			var rc = Std.parseInt(text);
			if (rc == null || Math.isNaN(rc)) rc = 1;
			selectedPlacement.repeat[1] = rc;
			hasUnsavedChanges = true;
			if (modifierTimeline != null) modifierTimeline.loadPlacements();
			refreshUnrolledPlacements();
		};

		var rx5 = editPanelOffsetX + 220;
		editRepeatGapLabel = new FlxText(rx5, eScreenY + editPanelOffsetY_Base + 67, 150, "Beats between repeats:", 10);
		editRepeatGapLabel.scrollFactor.set();
		editRepeatGapLabel.cameras = [eCam];
		editRepeatGapLabel.color = 0xFFAAAAAA;
		add(editRepeatGapLabel);
		editRepeatGapInput = new flixel.addons.ui.FlxUIInputText(rx5, eScreenY + editPanelOffsetY_Base + 80, 40, "1.0", 12, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		editRepeatGapInput.scrollFactor.set();
		editRepeatGapInput.cameras = [eCam];
		add(editRepeatGapInput);
		editRepeatGapInput.callback = function(text:String, action:String) {
			if (selectedPlacement == null || !editRepeatCheckbox.checked) return;
			var rg = Std.parseFloat(text);
			if (Math.isNaN(rg)) rg = 1.0;
			selectedPlacement.repeat[2] = rg;
			hasUnsavedChanges = true;
			if (modifierTimeline != null) modifierTimeline.loadPlacements();
			refreshUnrolledPlacements();
		};

		saveEditBtn = new flixel.addons.ui.FlxUIButton(editPanelOffsetX, eScreenY + editPanelOffsetY_Base + 180, "Save", function() {
			if (selectedPlacement != null) {
				var parsedDur = Std.parseFloat(editDurationInput.text);
				selectedPlacement.duration = (Math.isNaN(parsedDur) ? 1 : parsedDur);
				selectedPlacement.value = Std.parseFloat(editValueInput.text);
				if (Math.isNaN(selectedPlacement.value)) selectedPlacement.value = 0;
				selectedPlacement.type = editTypeDropdown.selectedId;
				selectedPlacement.ease = StringTools.trim(editEaseTextInput.text);
				
			if (editRepeatCheckbox.checked) {
				var rCount = Std.parseInt(editRepeatCountInput.text);
				if (rCount == null || Math.isNaN(rCount)) rCount = 1;
				var rGap = Std.parseFloat(editRepeatGapInput.text);
				if (Math.isNaN(rGap)) rGap = 1.0;
				selectedPlacement.repeat = [true, rCount, rGap];
				} else {
					selectedPlacement.repeat = null;
				}

				hasUnsavedChanges = true;
				if (modifierTimeline != null) modifierTimeline.loadPlacements();
				refreshUnrolledPlacements();
			} else if (activeModifierType == "songStart") {
				var parsedDur = Std.parseFloat(editDurationInput.text);
				songStartPlacement = {
					eventName: editEventNameInput.text,
					modifierRef: editSongModDropdown.selectedId,
					value: Std.parseFloat(editValueInput.text),
					duration: (Math.isNaN(parsedDur) ? 1 : parsedDur),
					ease: editEaseDropdown.selectedId,
					type: "tween"
				};
				if (Math.isNaN(songStartPlacement.value)) songStartPlacement.value = 0;
				if (songStartPlacement.eventName == null || songStartPlacement.eventName == "") songStartPlacement.eventName = "cameracenter";
				updateEditionUI();
			}
		});
		saveEditBtn.scrollFactor.set();
		saveEditBtn.cameras = [eCam]; add(saveEditBtn);

		deleteEditBtn = new flixel.addons.ui.FlxUIButton(editPanelOffsetX + 90, eScreenY + editPanelOffsetY_Base + 210, "Delete", function() {
			if (selectedPlacement != null) {
				timelinePlacements.remove(selectedPlacement);
				selectedPlacement = null;
				activeModifierType = "";
				setEditionUIVisible(false);
				hasUnsavedChanges = true;
				if (modifierTimeline != null) modifierTimeline.loadPlacements();
				updateEditionUI();
			}
		});
		deleteEditBtn.scrollFactor.set();
		deleteEditBtn.cameras = [eCam]; add(deleteEditBtn);

		var songModOptions = [];
		for (key in ModifierRegistry.definitions.keys()) songModOptions.push(key);
		if (songModOptions.length == 0) songModOptions = ["cameraZoom"];
		editSongModDropdown = new flixel.addons.ui.FlxUIDropDownMenu(editPanelOffsetX + 65, eScreenY + editPanelOffsetY_Base + 120, flixel.addons.ui.FlxUIDropDownMenu.makeStrIdLabelArray(songModOptions), function(id:String) {});
		editSongModDropdown.selectedLabel = "cameracenter";
		editSongModDropdown.scrollFactor.set();
		editSongModDropdown.cameras = [eCam]; add(editSongModDropdown);

		editEaseDropdown = new flixel.addons.ui.FlxUIDropDownMenu(editPanelOffsetX + 65, eScreenY + editPanelOffsetY_Base + 90, flixel.addons.ui.FlxUIDropDownMenu.makeStrIdLabelArray(atoms.EaseUtils.list), function(id:String) {
			if (editEaseTextInput != null) editEaseTextInput.text = id;
			if (selectedPlacement != null) {
				selectedPlacement.ease = id;
				hasUnsavedChanges = true;
				if (modifierTimeline != null) modifierTimeline.loadPlacements();
			} else if (activeModifierType == "songStart" && songStartPlacement != null) {
				songStartPlacement.ease = id;
				hasUnsavedChanges = true;
			}
		});
		editEaseDropdown.scrollFactor.set();
		

		editTypeDropdown = new flixel.addons.ui.FlxUIDropDownMenu(editPanelOffsetX + 65, eScreenY + editPanelOffsetY_Base + 60, flixel.addons.ui.FlxUIDropDownMenu.makeStrIdLabelArray(["tween", "set"]), function(id:String) {
			if (selectedPlacement != null) {
				selectedPlacement.type = id;
				hasUnsavedChanges = true;
				if (modifierTimeline != null) modifierTimeline.loadPlacements();
			}
			setEditionUIVisible(true);
		});
		editTypeDropdown.scrollFactor.set();
		editTypeDropdown.cameras = [eCam]; add(editTypeDropdown);

		editSongModLabel = new FlxText(editPanelOffsetX, eScreenY + editPanelOffsetY_Base + 120, 60, "Modifier:", 12);
		editSongModLabel.scrollFactor.set();
		editSongModLabel.cameras = [eCam]; add(editSongModLabel);

		editEaseTextInput = new flixel.addons.ui.FlxUIInputText(editPanelOffsetX + 65, eScreenY + editPanelOffsetY_Base + 120, 80, "linear", 12, FlxColor.WHITE, FlxColor.BLACK);
		editEaseTextInput.scrollFactor.set();
		editEaseTextInput.cameras = [eCam]; add(editEaseTextInput);

		editEaseDropdown.cameras = [eCam]; add(editEaseDropdown);

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

		ghostBlock = new FlxSprite(-100, 0);
		ghostBlock.makeGraphic(1, Std.int(EditorLayout.ROW_SIZE_Y) - 2, 0x88FFFFFF);
		ghostBlock.scrollFactor.set(1, 1);
		ghostBlock.cameras = [camTimeline];
		ghostBlock.visible = false;
		add(ghostBlock);

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
		};

		// --- Top bar background (renders UNDER menu) ---
		var topBar = new FlxSprite(0, 0);
		topBar.makeGraphic(FlxG.width, EditorLayout.TOPBAR_HEIGHT, ColorConstants.TOPBAR);
		topBar.cameras = [camEditorTop];
		add(topBar);

		// --- Top menu bar ---
		menus = [
			{name:"File", items:["Save","Save As","Import Events","Auto Save (ON)","Exit"]},
			{name:"Edit", items:["Copy","Paste","Cut","Delete","Shift Selection Left","Shift Selection Right"]},
			{name:"Modchart", items:["Create Modifier"]},
			{name:"View", items:["Fullscreen","Swap Scroll"]},
			{name:"Playback", items:["Play/Pause","+ speed 25%","reset speed","- speed 25%"]},
			{name:"Song", items:["Go back to the start","Go to the end","Mute Inst","Mute Vocals"]},
			{name:"Snap >", items:["4","8","12","16","20","24","32"]}
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
		// Insert "Song Start" at index 0 (always first in the list)
		loadedModifiers.insert(0, {
			name: "Song Start",
			modifier: "songStart",
			value: 0,
			type: "set"
		});
		modifierTimeline.loadPlacements();
		refreshUnrolledPlacements();
		buildTimelineRows();

		// Ensure dropdowns are rendered on top of other UI elements
		if (editSongModDropdown != null) {
			remove(editSongModDropdown);
			add(editSongModDropdown);
		}
		if (editTypeDropdown != null) {
			remove(editTypeDropdown);
			add(editTypeDropdown);
		}
		if (editEaseDropdown != null) {
			remove(editEaseDropdown);
			add(editEaseDropdown);
		}
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
			
			// Base alternating grey for the whole row
			var fillRect = new openfl.geom.Rectangle(0, 0, bg.width, bg.height);
			var color = (i % 2 == 0) ? 0xFF545454 : 0xFF272727;
			pixels.fillRect(fillRect, color);
			
			if (i < loadedModifiers.length)
			{
				var mod = loadedModifiers[i];
				var modColor = getColorForModifier(mod.modifier);
				
				// Draw a solid color block for the namelist column (left side)
				var nameRect = new openfl.geom.Rectangle(0, 0, EditorLayout.LIST_COL_W, EditorLayout.ROW_SIZE_Y);
				// Make it slightly darker/transparent by mixing with black
				var darkColor = flixel.util.FlxColor.interpolate(modColor, flixel.util.FlxColor.BLACK, 0.4);
				pixels.fillRect(nameRect, darkColor);

				// Draw a brighter left border for emphasis
				var borderRect = new openfl.geom.Rectangle(0, 0, 4, EditorLayout.ROW_SIZE_Y);
				pixels.fillRect(borderRect, modColor);

				if (modifierNamesTexts != null) {
					var nameText = new FlxText(8, i * EditorLayout.ROW_SIZE_Y + 2, EditorLayout.LIST_COL_W - 16, mod.name, 12);
					nameText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE);
					nameText.scrollFactor.set(0, 1);
					nameText.cameras = [camTimelineList];
					
					// Drag offset property for visual dragging later
					nameText.offset.y = 0; 
					modifierNamesTexts.add(nameText);
				}
			}

			bg.dirty = true;
			bg.scrollFactor.set(0, 1);
			bg.cameras = [camTimeline, camTimelineList];
			timelineRowBgs.add(bg);
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
					case 2: importCameraEvents();
					case 3:
						autoSaveEnabled = !autoSaveEnabled;
						menus[0].items[3] = "Auto Save (" + (autoSaveEnabled ? "ON" : "OFF") + ")";
						if (songInfo != null) songInfo.updateDisplay(this);
					case 4:
						if (hasUnsavedChanges) {
							openSubState(new substates.UnsavedChangesSubState(this));
						} else {
							if (FlxG.sound.music != null) FlxG.sound.music.stop();
							FlxG.switchState(() -> new PlayState());
						}
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

	function getPlacementAt(modRef:String, beat:Float):camera.ModchartData.TimelineModifierPlacement
	{
		for (pl in timelinePlacements) {
			if (pl.modifierRef != modRef) continue;
			var plEnd = pl.beat + ((pl.duration != null && pl.duration > 0) ? pl.duration : 1);
			if (beat >= pl.beat && beat < plEnd) return pl;
		}
		return null;
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

	function updateEditPanelPositions():Void
	{
		if (editDurationInput == null) return;
		var panelY = EditorLayout.timelineCamY - camEditor.scroll.y;
		var baseY = panelY + 80;
		editionPanelText.y = panelY + 10;
		editDurLabel.y = baseY;
		editDurationInput.y = baseY;
		editValLabel.y = baseY + 30;
		editValueInput.y = baseY + 30;
		var isSongStart = (activeModifierType == "songStart");
		
		if (isSongStart) {
			editSongModLabel.y = baseY + 60;
			editSongModDropdown.y = baseY + 60;
			
			editEaseLabel.y = baseY + 90;
			editEaseDropdown.y = baseY + 90;
			
			if (editEaseTextLabel != null) editEaseTextLabel.y = baseY + 120;
			if (editEaseTextInput != null) editEaseTextInput.y = baseY + 120;
			
			editEventNameLabel.y = baseY + 150;
			editEventNameInput.y = baseY + 150;
		} else {
			editTypeLabel.y = baseY + 60;
			editTypeDropdown.y = baseY + 60;
			
			editEaseLabel.y = baseY + 90;
			editEaseDropdown.y = baseY + 90;
			
			if (editEaseTextLabel != null) editEaseTextLabel.y = baseY + 120;
			if (editEaseTextInput != null) editEaseTextInput.y = baseY + 120;
		}
		
		saveEditBtn.y = baseY + 210;
		deleteEditBtn.y = baseY + 210;
		
		if (editRepeatCheckbox != null) editRepeatCheckbox.y = baseY;
		if (editRepeatCountLabel != null) editRepeatCountLabel.y = baseY + 27;
		if (editRepeatCountInput != null) editRepeatCountInput.y = baseY + 40;
		if (editRepeatGapLabel != null) editRepeatGapLabel.y = baseY + 67;
		if (editRepeatGapInput != null) editRepeatGapInput.y = baseY + 80;
	}

	override function update(elapsed:Float)
	{
		updateEditPanelPositions();
		super.update(elapsed);

		if (autoSaveEnabled && hasUnsavedChanges) {
			autoSaveTimer += elapsed;
			if (autoSaveTimer >= 180) { // 3 minutes
				saveCameraEvents(false);
				showAutoSaveNotification();
				autoSaveTimer = 0;
			}
		} else {
			autoSaveTimer = 0;
		}

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

		var inputHasFocus = (editValueInput != null && editValueInput.hasFocus) ||
							(editDurationInput != null && editDurationInput.hasFocus) ||
							(editEventNameInput != null && editEventNameInput.hasFocus) ||
							(editEaseTextInput != null && editEaseTextInput.hasFocus) ||
							(editRepeatCountInput != null && editRepeatCountInput.hasFocus) ||
							(editRepeatGapInput != null && editRepeatGapInput.hasFocus);

		if ((FlxG.keys.justPressed.DELETE || FlxG.keys.justPressed.BACKSPACE) && !inputHasFocus)
		{
			if (selectedPlacement != null)
			{
				timelinePlacements.remove(selectedPlacement);
				selectedPlacement = null;
				activeModifierType = "";
				setEditionUIVisible(false);
				if (modifierTimeline != null) modifierTimeline.loadPlacements();
				refreshUnrolledPlacements();
				updateEditionUI();
			}
		}

		if ((FlxG.keys.justPressed.C && FlxG.keys.pressed.CONTROL) || (FlxG.keys.justPressed.CONTROL && FlxG.keys.justPressed.C))
		{
			if (selectedPlacement != null && !(editValueInput != null && editValueInput.hasFocus))
			{
			copiedPlacement = {
				beat: selectedPlacement.beat,
				modifierRef: selectedPlacement.modifierRef,
				value: selectedPlacement.value,
				type: selectedPlacement.type,
				duration: selectedPlacement.duration,
				ease: selectedPlacement.ease,
				repeat: selectedPlacement.repeat
			};
			}
		}
		if ((FlxG.keys.justPressed.V && FlxG.keys.pressed.CONTROL) || (FlxG.keys.justPressed.CONTROL && FlxG.keys.justPressed.V))
		{
			if (copiedPlacement != null && !(editValueInput != null && editValueInput.hasFocus))
			{
				var pasteBeat = if (FlxG.mouse.y >= EditorLayout.timelineWindowY && FlxG.mouse.x >= EditorLayout.GRID_COL_X) {
					var gridX = FlxG.mouse.x - EditorLayout.GRID_COL_X + modifierTimeline.scrollX;
					gridX / modifierTimeline.zoomX;
				} else {
					curDecStep / 4;
				}
				if (pasteBeat < 0) pasteBeat = 0;
				pasteBeat = Math.floor(pasteBeat);
				if (getPlacementAt(copiedPlacement.modifierRef, pasteBeat) == null)
				{
				var newP:TimelineModifierPlacement = {
					beat: pasteBeat,
					modifierRef: copiedPlacement.modifierRef,
					value: copiedPlacement.value,
					type: copiedPlacement.type,
					duration: copiedPlacement.duration,
					ease: copiedPlacement.ease,
					repeat: copiedPlacement.repeat
				};
					timelinePlacements.push(newP);
					timelinePlacements.sort(function(a, b) return (a.beat < b.beat) ? -1 : ((a.beat > b.beat) ? 1 : 0));
					refreshUnrolledPlacements();
					selectedPlacement = newP;
					updateEditionUI();
					if (modifierTimeline != null) modifierTimeline.loadPlacements();
				}
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
					if (modifierTimeline.zoomX > 300.0) modifierTimeline.zoomX = 300.0;
				}
				else
				{
					// Scroll vertically
					var targetScrollY = camTimeline.scroll.y + (-FlxG.mouse.wheel * EditorLayout.ROW_SIZE_Y);
					var maxScrollY = Math.max(0, ((loadedModifiers.length + 10) * EditorLayout.ROW_SIZE_Y) - EditorLayout.timelineCamH);
					if (targetScrollY < 0) targetScrollY = 0;
					if (targetScrollY > maxScrollY) targetScrollY = maxScrollY;

					camTimeline.scroll.y = targetScrollY;
					camTimelineList.scroll.y = targetScrollY;
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
						draggedRowIndex = rowIndex;
						dragStartMouseY = FlxG.mouse.screenY;
						if (modifierNamesTexts != null && rowIndex < modifierNamesTexts.length) {
							draggedRowOriginalY = modifierNamesTexts.members[rowIndex].y;
						}

						activeModifierType = loadedModifiers[rowIndex].modifier;
						selectedPlacement = null;
						if (activeModifierType == "songStart") {
							updateEditionUI();
						} else {
							editValueInput.text = "0";
							editDurationInput.text = "1";
							editTypeDropdown.selectedLabel = "tween";
							editEaseDropdown.selectedLabel = "linear";
							updateEditionUI();
						}
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
						var gridHitX = mouseX - EditorLayout.GRID_COL_X;
						var gridMouseX = mouseX - EditorLayout.GRID_COL_X + modifierTimeline.scrollX;
						var gridMouseY = mouseY - (timelineWindowY + EditorLayout.TOPBAR_HEIGHT) + camTimeline.scroll.y;

						var clickedBlock:organisms.ModifierBlock = null;
						if (modifierTimeline != null)
						{
							modifierTimeline.modifierBlocks.forEachAlive(function(block:organisms.ModifierBlock) {
								if (gridHitX >= block.x && gridHitX <= block.x + block.bg.width &&
									gridMouseY >= block.y && gridMouseY <= block.y + block.bg.height) {
									clickedBlock = block;
								}
							});
						}

						if (clickedBlock != null)
						{
							if (timelinePlacements.indexOf(clickedBlock.data) == -1) {
								// Do nothing, it's a ghost repeat block
							} else {
								if (selectedPlacement != clickedBlock.data) {
									activeModifierType = clickedBlock.data.modifierRef;
									selectedPlacement = clickedBlock.data;
									updateEditionUI();
								}
								isDraggingBlock = true;
							}
						}
						else
						{
							var isDoubleClick = (openfl.Lib.getTimer() - lastGridClickTime < 300);
							lastGridClickTime = openfl.Lib.getTimer();

							if (isDoubleClick)
							{
								var rowIndex = Math.floor(gridMouseY / EditorLayout.ROW_SIZE_Y);
								if (rowIndex >= loadedModifiers.length)
								{
									var newModRef = activeModifierType;
									if (newModRef == "" || newModRef == "songStart")
									{
										var availTypes = [];
										for (key in ModifierRegistry.definitions.keys()) availTypes.push(key);
										if (availTypes.length > 0) newModRef = availTypes[0];
										else newModRef = "cameraZoom";
									}
									
									loadedModifiers.push({
										name: newModRef,
										modifier: newModRef,
										value: ModifierRegistry.getDefaultValue(newModRef),
										type: "tween"
									});
									buildTimelineRows();
									rowIndex = loadedModifiers.length - 1;
								}

								if (rowIndex >= 0 && rowIndex < loadedModifiers.length)
								{
									var modRef = loadedModifiers[rowIndex].modifier;
									if (modRef == "songStart") {} // songStart is not grid-placeable
									else
									{
										var rawBeat = gridMouseX / modifierTimeline.zoomX;
										var snapsPerBeat = 16.0 / beatSnap;
										var hoverBeat = (!FlxG.keys.pressed.SHIFT) ? (Math.ffloor(rawBeat * snapsPerBeat) / snapsPerBeat) : (Math.ffloor(rawBeat * 1000) / 1000);
										if (hoverBeat < 0) hoverBeat = 0;
										var existing = getPlacementAt(modRef, hoverBeat);
										if (existing != null) {
											activeModifierType = modRef;
											selectedPlacement = existing;
											updateEditionUI();
										} else {
											activeModifierType = modRef;
											var parsedVal = Std.parseFloat(editValueInput.text);
											if (Math.isNaN(parsedVal)) parsedVal = 0;
											var parsedDur = Std.parseFloat(editDurationInput.text);
											if (Math.isNaN(parsedDur) || parsedDur <= 0) parsedDur = 1;
										var newRepeat:Array<Dynamic> = null;
										if (editRepeatCheckbox.checked)
										{
											var rc = Std.parseInt(editRepeatCountInput.text);
											if (rc == null || Math.isNaN(rc)) rc = 1;
											var rg = Std.parseFloat(editRepeatGapInput.text);
											if (Math.isNaN(rg)) rg = 1.0;
											newRepeat = [true, rc, rg];
										}
										var newPlacement:camera.ModchartData.TimelineModifierPlacement = {
											beat: hoverBeat,
											duration: parsedDur,
											type: editTypeDropdown.selectedId,
											modifierRef: modRef,
											ease: editEaseDropdown.selectedId,
											value: parsedVal,
											repeat: newRepeat
										};
											timelinePlacements.push(newPlacement);
											hasUnsavedChanges = true;
											timelinePlacements.sort(function(a, b) return (a.beat < b.beat) ? -1 : ((a.beat > b.beat) ? 1 : 0));
											
											refreshUnrolledPlacements();
											selectedPlacement = newPlacement;
											updateEditionUI();
											modifierTimeline.loadPlacements();
										}
									}
								}
							}
							else
							{
								selectedPlacement = null;
								updateEditionUI();
							}
						}
					}
				}
			}

			if (FlxG.mouse.pressed && isDraggingBlock && selectedPlacement != null)
			{
				if (mouseX >= EditorLayout.GRID_COL_X && mouseX < FlxG.width * 0.8)
				{
					var gridMouseX = mouseX - EditorLayout.GRID_COL_X + modifierTimeline.scrollX;
					var rawBeat = gridMouseX / modifierTimeline.zoomX;
					var snapsPerBeat = 16.0 / beatSnap;
					var hoverBeat = (!FlxG.keys.pressed.SHIFT) ? (Math.ffloor(rawBeat * snapsPerBeat) / snapsPerBeat) : (Math.ffloor(rawBeat * 1000) / 1000);
					if (hoverBeat < 0) hoverBeat = 0;
					
					var gridMouseY = mouseY - (timelineWindowY + EditorLayout.TOPBAR_HEIGHT) + camTimeline.scroll.y;
					var rowIndex = Math.floor(gridMouseY / EditorLayout.ROW_SIZE_Y);
					var newModRef = selectedPlacement.modifierRef;
					
					if (rowIndex >= 0 && rowIndex < loadedModifiers.length) {
						var targetMod = loadedModifiers[rowIndex].modifier;
						if (targetMod != "songStart") {
							newModRef = targetMod;
						}
					}
					
					if (selectedPlacement.beat != hoverBeat || selectedPlacement.modifierRef != newModRef) {
						var existing = getPlacementAt(newModRef, hoverBeat);
						if (existing == null || existing == selectedPlacement) {
							selectedPlacement.beat = hoverBeat;
							selectedPlacement.modifierRef = newModRef;
							if (modifierTimeline != null) modifierTimeline.loadPlacements();
							refreshUnrolledPlacements();
							updateEditionUI();
						}
					}
				}
			}

			if (FlxG.mouse.justReleased)
			{
				if (isDraggingBlock) {
					isDraggingBlock = false;
					timelinePlacements.sort(function(a, b) return (a.beat < b.beat) ? -1 : ((a.beat > b.beat) ? 1 : 0));
					hasUnsavedChanges = true;
					refreshUnrolledPlacements();
				}
			}

			if (ghostBlock != null) {
				var isHoveringGrid = (mouseY >= timelineWindowY + EditorLayout.TOPBAR_HEIGHT && mouseY < FlxG.height && mouseX >= EditorLayout.GRID_COL_X && mouseX < FlxG.width * 0.8 && subState == null);
				if (isHoveringGrid && activeModifierType != "" && activeModifierType != "songStart") {
					var gridMouseX = mouseX - EditorLayout.GRID_COL_X + modifierTimeline.scrollX;
					var rawBeat = gridMouseX / modifierTimeline.zoomX;
					var snapsPerBeat = 16.0 / beatSnap;
					var hoverBeat = (!FlxG.keys.pressed.SHIFT) ? (Math.ffloor(rawBeat * snapsPerBeat) / snapsPerBeat) : (Math.ffloor(rawBeat * 1000) / 1000);
					if (hoverBeat < 0) hoverBeat = 0;
					
					var gridMouseY = mouseY - (timelineWindowY + EditorLayout.TOPBAR_HEIGHT) + camTimeline.scroll.y;
					var rowIndex = Math.floor(gridMouseY / EditorLayout.ROW_SIZE_Y);
					
					ghostBlock.visible = true;
					ghostBlock.x = hoverBeat * modifierTimeline.zoomX;
					ghostBlock.y = rowIndex * EditorLayout.ROW_SIZE_Y + 1;
					var bW = Std.int(Math.max(10, modifierTimeline.zoomX));
					if (ghostBlock.width != bW) {
						ghostBlock.makeGraphic(bW, Std.int(EditorLayout.ROW_SIZE_Y) - 2, 0x88FFFFFF);
					}
				} else {
					ghostBlock.visible = false;
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

					var snapsPerBeat = 16.0 / beatSnap;
					var hoverBeat = (!FlxG.keys.pressed.SHIFT) ? (Math.ffloor((gridMouseX / modifierTimeline.zoomX) * snapsPerBeat) / snapsPerBeat) : (Math.ffloor((gridMouseX / modifierTimeline.zoomX) * 1000) / 1000);
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
		// --- Handle Drag and Drop for Namelist ---
		if (draggedRowIndex != -1)
		{
			if (FlxG.mouse.pressed && modifierNamesTexts != null && draggedRowIndex < modifierNamesTexts.length) {
				var dragDeltaY = FlxG.mouse.screenY - dragStartMouseY;
				var targetY = draggedRowOriginalY + dragDeltaY;
				var draggedText = modifierNamesTexts.members[draggedRowIndex];
				draggedText.y += (targetY - draggedText.y) * 0.3; // LERP
			}
			
			if (FlxG.mouse.justReleased) {
				var listMouseY = FlxG.mouse.y - (EditorLayout.timelineWindowY + EditorLayout.TOPBAR_HEIGHT) + camTimelineList.scroll.y;
				var dropRowIndex = Math.floor(listMouseY / EditorLayout.ROW_SIZE_Y);
				if (dropRowIndex < 0) dropRowIndex = 0;
				if (dropRowIndex >= loadedModifiers.length) dropRowIndex = loadedModifiers.length - 1;
				
				if (dropRowIndex != draggedRowIndex) {
					var item = loadedModifiers[draggedRowIndex];
					loadedModifiers.remove(item);
					loadedModifiers.insert(dropRowIndex, item);
					hasUnsavedChanges = true;
				}
				
				draggedRowIndex = -1;
				buildTimelineRows();
				if (modifierTimeline != null) modifierTimeline.loadPlacements();
			}
		}

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
			var maxScrollY = Math.max(0, ((loadedModifiers.length + 10) * EditorLayout.ROW_SIZE_Y) - EditorLayout.timelineCamH);
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
			var easeVal = (selectedPlacement.ease != null && selectedPlacement.ease != "") ? selectedPlacement.ease : "linear";
			editEaseDropdown.selectedLabel = easeVal;
			editEaseTextInput.text = easeVal;
			
			if (selectedPlacement.repeat != null && selectedPlacement.repeat[0] == true) {
				editRepeatCheckbox.checked = true;
				editRepeatCountInput.text = Std.string(selectedPlacement.repeat[1]);
				editRepeatGapInput.text = Std.string(selectedPlacement.repeat[2]);
			} else {
				editRepeatCheckbox.checked = false;
				editRepeatCountInput.text = "1";
				editRepeatGapInput.text = "1.0";
			}
			
			setEditionUIVisible(true);
		} else if (activeModifierType == "songStart") {
			if (songStartPlacement != null) {
				editionPanelText.text = "SONG START\n(active during countdown)";
				editDurationInput.text = (songStartPlacement.duration != null) ? Std.string(songStartPlacement.duration) : "1";
				editValueInput.text = Std.string(songStartPlacement.value);
				editSongModDropdown.selectedLabel = songStartPlacement.modifierRef;
				var easeVal = (songStartPlacement.ease != null && songStartPlacement.ease != "") ? songStartPlacement.ease : "linear";
				editEaseDropdown.selectedLabel = easeVal;
				editEaseTextInput.text = easeVal;
				editEventNameInput.text = (songStartPlacement.eventName != null && songStartPlacement.eventName != "") ? songStartPlacement.eventName : "cameracenter";
			} else {
				editionPanelText.text = "SONG START\n(active during countdown)\nSet a modifier to apply:";
				editDurationInput.text = "1";
				editValueInput.text = "1";
				editSongModDropdown.selectedLabel = "cameracenter";
				editEaseDropdown.selectedLabel = "linear";
				editEaseTextInput.text = "linear";
				editEventNameInput.text = "cameracenter";
			}
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
		var isSongStart = (selectedPlacement == null && activeModifierType == "songStart");
		var isSet = false;
		if (editTypeDropdown != null && editTypeDropdown.selectedId == "set") isSet = true;
		if (isSongStart && songStartPlacement != null && songStartPlacement.type == "set") isSet = true;
		
		if (editDurationInput != null) editDurationInput.visible = v && !isSet;
		if (editDurLabel != null) editDurLabel.visible = v && !isSet;
		if (editValueInput != null) editValueInput.visible = v;
		if (editValLabel != null) editValLabel.visible = v;
		if (editTypeLabel != null) editTypeLabel.visible = v && !isSongStart;
		if (editTypeDropdown != null) editTypeDropdown.visible = v && !isSongStart;
		if (editEaseDropdown != null) editEaseDropdown.visible = v && !isSet;
		if (editEaseLabel != null) editEaseLabel.visible = v && !isSet;
		if (editEaseTextInput != null) editEaseTextInput.visible = v && !isSet;
		if (editEaseTextLabel != null) editEaseTextLabel.visible = v && !isSet;
		
		if (editRepeatCheckbox != null) editRepeatCheckbox.visible = v && !isSongStart;
		if (editRepeatCountInput != null) editRepeatCountInput.visible = v && !isSongStart;
		if (editRepeatCountLabel != null) editRepeatCountLabel.visible = v && !isSongStart;
		if (editRepeatGapInput != null) editRepeatGapInput.visible = v && !isSongStart;
		if (editRepeatGapLabel != null) editRepeatGapLabel.visible = v && !isSongStart;

		if (editSongModLabel != null) editSongModLabel.visible = v && isSongStart;
		if (editSongModDropdown != null) editSongModDropdown.visible = v && isSongStart;
		if (editEventNameLabel != null) editEventNameLabel.visible = v && isSongStart;
		if (editEventNameInput != null) editEventNameInput.visible = v && isSongStart;
		if (saveEditBtn != null) saveEditBtn.visible = v && (selectedPlacement != null || isSongStart);
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
		if (editorPreview != null) editorPreview.hasTween = isTweenActive(step);
	}

	function isTweenActive(step:Float):Bool
	{
		if (songStartPlacement != null)
		{
			var startStep = -16.0;
			var durSteps = ((songStartPlacement.duration != null && songStartPlacement.duration > 0) ? songStartPlacement.duration : 1) * 4;
			if (step >= startStep && step <= startStep + durSteps) return true;
		}
		for (pl in unrolledPlacements)
		{
			var placementStep = pl.beat * 4;
			var durSteps:Float = ((pl.duration != null && pl.duration > 0) ? pl.duration : 1) * 4;
			if (step >= placementStep && step <= placementStep + durSteps) return true;
		}
		return false;
	}

	public function getModifierValue(modifierId:String, step:Float):Float
	{
		var defVal = ModifierRegistry.getDefaultValue(modifierId);
		var result = defVal;
		var lastVal = defVal;

		if (songStartPlacement != null && songStartPlacement.modifierRef == modifierId)
		{
			var durBeats:Float = (songStartPlacement.duration != null && songStartPlacement.duration > 0) ? songStartPlacement.duration : 1;
			var durSteps = durBeats * 4;
			var startStep = -16.0;

			if (step >= startStep + durSteps) {
				result = songStartPlacement.value;
				lastVal = result;
			} else if (step >= startStep && step < startStep + durSteps) {
				if (songStartPlacement.type == "tween") {
					var t = (step - startStep) / durSteps;
					if (songStartPlacement.ease != null && songStartPlacement.ease != "linear") t = atoms.EaseUtils.fromName(songStartPlacement.ease)(t);
					return lastVal + (songStartPlacement.value - lastVal) * t;
				} else {
					result = songStartPlacement.value;
					lastVal = result;
				}
			}
		}

		for (pl in unrolledPlacements)
		{
			if (pl.modifierRef != modifierId) continue;
			var placementStep = pl.beat * 4;
			var durSteps:Float = ((pl.duration != null && pl.duration > 0) ? pl.duration : 1) * 4;
			
			if (step < placementStep) {
				if (pl.beat <= 0 && pl.type == "set") {
					result = pl.value;
				}
				break;
			}

			if (step >= placementStep + durSteps || pl.type == "set") {
				result = pl.value;
				lastVal = result;
			} else {
				var t = (step - placementStep) / durSteps;
				if (pl.ease != null && pl.ease != "linear") t = atoms.EaseUtils.fromName(pl.ease)(t);
				return lastVal + (pl.value - lastVal) * t;
			}
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
		var curMod:String = utilities.Options.getData("curMod");
		var folder:String = 'mods/$curMod/data/song data/$songFolder/';
		
		if (!sys.FileSystem.exists(folder))
		{
			sys.FileSystem.createDirectory(folder);
		}
		
		return folder + "cameraevents.json";
		#else
		return "cameraevents.json";
		#end
	}

	public function loadCameraEvents():Void
	{
		loadedModifiers = [];
		timelinePlacements = [];
		songStartPlacement = null;
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
				if (data.songStart != null) songStartPlacement = data.songStart;
				
				refreshUnrolledPlacements();
				buildTimelineRows();
			}
			catch (e:Dynamic) { trace("Error loading cameraevents.json: " + e); }
		}
		#end
	}

	var _file:openfl.net.FileReference;

	public function importCameraEvents():Void
	{
		_file = new openfl.net.FileReference();
		_file.addEventListener(openfl.events.Event.SELECT, onImportSelect);
		_file.addEventListener(openfl.events.Event.CANCEL, onImportCancel);
		_file.browse([new openfl.net.FileFilter("JSON Files", "*.json")]);
	}

	function onImportSelect(e:openfl.events.Event):Void
	{
		_file.addEventListener(openfl.events.Event.COMPLETE, onImportComplete);
		_file.load();
	}

	function onImportComplete(e:openfl.events.Event):Void
	{
		_file.removeEventListener(openfl.events.Event.SELECT, onImportSelect);
		_file.removeEventListener(openfl.events.Event.CANCEL, onImportCancel);
		_file.removeEventListener(openfl.events.Event.COMPLETE, onImportComplete);
		
		try {
			var content = _file.data.toString();
			var data:camera.ModchartData.CameraEventsSaveData = haxe.Json.parse(content);
			
			loadedModifiers = [];
			timelinePlacements = [];
			songStartPlacement = null;
			
			if (data.modifiers != null) loadedModifiers = data.modifiers;
			if (data.placements != null) timelinePlacements = data.placements;
			if (data.songStart != null) songStartPlacement = data.songStart;
			
			var hasSongStartMod = false;
			for(m in loadedModifiers) {
				if(m.modifier == "songStart") { hasSongStartMod = true; break; }
			}
			if(!hasSongStartMod) {
				loadedModifiers.insert(0, {
					name: "Song Start",
					modifier: "songStart",
					value: 0,
					type: "set"
				});
			}
			
			if (modifierTimeline != null) modifierTimeline.loadPlacements();
			buildTimelineRows();
			selectedPlacement = null;
			activeModifierType = "";
			updateEditionUI();
		} catch (e:Dynamic) {
			trace("Error parsing imported JSON: " + e);
		}
		
		_file = null;
	}

	function onImportCancel(e:openfl.events.Event):Void
	{
		_file.removeEventListener(openfl.events.Event.SELECT, onImportSelect);
		_file.removeEventListener(openfl.events.Event.CANCEL, onImportCancel);
		_file = null;
	}

	public function saveCameraEvents(forceDialog:Bool = false):Void
	{
		hasUnsavedChanges = false;
		var cleanModifiers = [];
		for (m in loadedModifiers) {
			if (m.modifier == "songStart") continue;
			var cleanM:Dynamic = { name: m.name, modifier: m.modifier, value: m.value, type: m.type };
			if (m.duration != null) Reflect.setField(cleanM, "duration", m.duration);
			if (m.ease != null) Reflect.setField(cleanM, "ease", m.ease);
			cleanModifiers.push(cleanM);
		}

		var cleanPlacements = [];
		for (p in timelinePlacements) {
			var cleanP:Dynamic = { modifierRef: p.modifierRef, value: p.value, type: p.type, beat: p.beat };
			if (p.duration != null) Reflect.setField(cleanP, "duration", p.duration);
			if (p.ease != null) Reflect.setField(cleanP, "ease", p.ease);
			if (p.repeat != null) Reflect.setField(cleanP, "repeat", p.repeat);
			cleanPlacements.push(cleanP);
		}
		
		var finalSongStart = songStartPlacement;
		if (finalSongStart == null) {
			finalSongStart = {
				eventName: "cameracenter",
				modifierRef: "cameracenter",
				value: 1,
				duration: 1,
				ease: "linear",
				type: "set"
			};
		}
		
		var cleanSongStart:Dynamic = { modifierRef: finalSongStart.modifierRef, value: finalSongStart.value, type: finalSongStart.type };
		if (finalSongStart.eventName != null) Reflect.setField(cleanSongStart, "eventName", finalSongStart.eventName);
		if (finalSongStart.duration != null) Reflect.setField(cleanSongStart, "duration", finalSongStart.duration);
		if (finalSongStart.ease != null) Reflect.setField(cleanSongStart, "ease", finalSongStart.ease);
		
		var data:Dynamic = { modifiers: cleanModifiers, placements: cleanPlacements, songStart: cleanSongStart };
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
		if (PlayState.SONG != null) saveCameraEvents(false);
		@:privateAccess FlxCamera._defaultCameras = null;
		super.destroy();
	}

	public function showAutoSaveNotification():Void {
		var txt = new FlxText(FlxG.width - 250, FlxG.height - 40, 250, "Modchart Auto-Saved!", 16);
		txt.setFormat(Paths.font("vcr.ttf"), 16, flixel.util.FlxColor.GREEN, "right", OUTLINE, flixel.util.FlxColor.BLACK);
		txt.scrollFactor.set();
		txt.cameras = [camEditorTop];
		add(txt);
		flixel.tweens.FlxTween.tween(txt, {alpha: 0}, 2, {startDelay: 1, onComplete: function(twn) { remove(txt); txt.destroy(); }});
	}
}
