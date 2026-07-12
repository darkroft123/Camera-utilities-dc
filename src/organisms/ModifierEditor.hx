package organisms;

import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import pages.ModchartEditor;
import camera.ModchartData;
import camera.ModifierRegistry;
import atoms.ColorConstants;
import atoms.Styles;
import atoms.EaseUtils;
import templates.EditorLayout;

class ModifierEditor extends FlxGroup
{
	public var panelX:Int = 185;
	public var panelW:Int = 175;

	var panelBg:FlxSprite;
	var headerText:FlxText;
	var infoText:FlxText;

	var typeDropdown:FlxUIDropDownMenu;
	var valueInput:FlxUIInputText;
	var valLabel:FlxText;
	var durationInput:FlxUIInputText;
	var easeDropdown:FlxUIDropDownMenu;
	var durationLabel:FlxText;
	var easeLabel:FlxText;

	public var currentType(get, never):String;
	function get_currentType():String return typeDropdown.selectedLabel;
	public var currentValue(get, never):Float;
	function get_currentValue():Float {
		var v = Std.parseFloat(valueInput.text);
		return Math.isNaN(v) ? 0.0 : v;
	}
	public var currentDuration(get, never):Int;
	function get_currentDuration():Int {
		var v = Std.parseInt(durationInput.text);
		return (v != null && v > 0) ? v : 16;
	}
	public var currentEase(get, never):String;
	function get_currentEase():String return easeDropdown.selectedLabel;

	var activeEntry:ModifierEntry;

	public function new(state:ModchartEditor, cam:FlxCamera)
	{
		super();
		var panelY:Float = EditorLayout.editorDefaultY;

		panelBg = new FlxSprite(panelX, panelY);
		panelBg.makeGraphic(panelW, 200, ColorConstants.PANEL_DARK);
		panelBg.scrollFactor.set(0, 0);
		panelBg.cameras = [cam];
		add(panelBg);

		headerText = Styles.makeHeaderLabel("EDITOR", panelX + 5, panelY + 3, panelW - 10, 12);
		headerText.cameras = [cam];
		add(headerText);

		var separator = new FlxSprite(panelX + 2, panelY + 20);
		separator.makeGraphic(panelW - 4, 1, ColorConstants.GRID_LINE);
		separator.scrollFactor.set(0, 0);
		separator.cameras = [cam];
		add(separator);

		var editY = panelY + 28;

		infoText = Styles.makeInfoLabel("Select a modifier", panelX + 7, editY, panelW - 14, 11);
		infoText.cameras = [cam];
		add(infoText);

		var typeLabels = FlxUIDropDownMenu.makeStrIdLabelArray(["tween", "set"]);
		typeDropdown = new FlxUIDropDownMenu(panelX + 7, editY + 18, typeLabels, function(id:String) {
			updateVisibility(id);
		});
		typeDropdown.selectedLabel = "tween";
		typeDropdown.scrollFactor.set(0, 0);
		typeDropdown.cameras = [cam];
		add(typeDropdown);

		valLabel = Styles.makeInfoLabel("Value:", panelX + 7, editY + 46, panelW - 14, 11);
		valLabel.cameras = [cam];
		add(valLabel);

		valueInput = new FlxUIInputText(panelX + 7, editY + 58, panelW - 18, "", 10, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		valueInput.scrollFactor.set(0, 0);
		valueInput.cameras = [cam];
		add(valueInput);

		durationLabel = Styles.makeInfoLabel("Duration:", panelX + 7, editY + 84, panelW - 18, 11);
		durationLabel.cameras = [cam];
		add(durationLabel);

		durationInput = new FlxUIInputText(panelX + 7, editY + 96, Std.int((panelW - 24) / 2), "16", 10, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		durationInput.scrollFactor.set(0, 0);
		durationInput.cameras = [cam];
		add(durationInput);

		easeLabel = Styles.makeInfoLabel("Ease:", panelX + Std.int((panelW - 24) / 2) + 14, editY + 84, Std.int((panelW - 24) / 2), 11);
		easeLabel.cameras = [cam];
		add(easeLabel);

		var easeLabels = FlxUIDropDownMenu.makeStrIdLabelArray(EaseUtils.list);
		easeDropdown = new FlxUIDropDownMenu(panelX + Std.int((panelW - 24) / 2) + 14, editY + 96, easeLabels, function(id:String) {});
		easeDropdown.selectedLabel = "linear";
		easeDropdown.scrollFactor.set(0, 0);
		easeDropdown.cameras = [cam];
		add(easeDropdown);

		updateVisibility("tween");
		clearEditor();
	}

	public function loadEntry(entry:ModifierEntry):Void
	{
		activeEntry = entry;
		infoText.text = "Editing: " + entry.name;
		infoText.color = FlxColor.WHITE;

		typeDropdown.selectedLabel = entry.type;
		valueInput.text = Std.string(entry.value);
		durationInput.text = (entry.duration != null) ? Std.string(entry.duration) : "16";
		easeDropdown.selectedLabel = (entry.ease != null) ? entry.ease : "linear";

		updateVisibility(entry.type);

		panelBg.visible = true;
		headerText.visible = true;
		valLabel.visible = true;
		typeDropdown.visible = true;
		valueInput.visible = true;
	}

	public function loadPlacement(placement:TimelineModifierPlacement):Void
	{
		activeEntry = null;
		var def = ModifierRegistry.definitions.get(placement.modifierRef);
		var displayName = (def != null) ? def.displayName : placement.modifierRef;
		var startStep = placement.beat * 4;
		var endStep = startStep + (placement.duration != null ? placement.duration : 0);
		infoText.text = "Placement: " + displayName + " (step " + startStep + " - " + endStep + ")";
		infoText.color = FlxColor.WHITE;

		typeDropdown.selectedLabel = placement.type;
		valueInput.text = Std.string(placement.value);
		durationInput.text = (placement.duration != null) ? Std.string(placement.duration) : "16";
		easeDropdown.selectedLabel = (placement.ease != null) ? placement.ease : "linear";

		updateVisibility(placement.type);

		panelBg.visible = true;
		headerText.visible = true;
		valLabel.visible = true;
		typeDropdown.visible = true;
		valueInput.visible = true;
	}

	public function clearEditor():Void
	{
		activeEntry = null;
		infoText.text = "Select a modifier";
		infoText.color = FlxColor.WHITE;
		typeDropdown.visible = false;
		valLabel.visible = false;
		valueInput.visible = false;
		durationLabel.visible = false;
		durationInput.visible = false;
		easeLabel.visible = false;
		easeDropdown.visible = false;
	}

	function updateVisibility(type:String):Void
	{
		var showTween = (type == "tween");
		durationLabel.visible = showTween;
		durationInput.visible = showTween;
		easeLabel.visible = showTween;
		easeDropdown.visible = showTween;
	}

	public function getActiveModifierRef():String
	{
		return (activeEntry != null) ? activeEntry.modifier : null;
	}

	public function hasSelection():Bool
	{
		return activeEntry != null;
	}

	public function hasFocusedInput():Bool
	{
		return valueInput.hasFocus || durationInput.hasFocus;
	}

	public function setY(newY:Float):Void
	{
		panelBg.y = newY;
		headerText.y = newY + 3;
		var editY = newY + 28;
		infoText.y = editY;
		typeDropdown.y = editY + 18;
		valLabel.y = editY + 46;
		valueInput.y = editY + 58;
		durationLabel.y = editY + 84;
		durationInput.y = editY + 96;
		easeLabel.y = editY + 84;
		easeDropdown.y = editY + 96;
	}
}
