package substates;

import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIButton;
using StringTools;
import pages.ModchartEditor;
import camera.ModchartData;
import camera.ModifierRegistry;
import atoms.Styles;

class ModifyModifierPopup extends FlxSubState
{
	public var parentState:ModchartEditor;

	static final POPUP_W:Int = 320;
	static final POPUP_H:Int = 200;

	var popupBg:FlxSprite;
	var titleText:FlxText;

	var nameInput:FlxUIInputText;
	var modifierDropdown:FlxUIDropDownMenu;
	var descText:FlxText;

	var createBtn:FlxUIButton;
	var closeBtn:FlxUIButton;

	var selectedModifier:String = "";

	public function new(parentState:ModchartEditor)
	{
		super();
		this.parentState = parentState;
	}

	override public function create():Void
	{
		super.create();

		var cam = parentState.uiCam;

		var overlay = new FlxSprite(0, 0);
		overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
		overlay.scrollFactor.set(0, 0);
		overlay.cameras = [cam];
		add(overlay);

		var px = Std.int((FlxG.width - POPUP_W) / 2);
		var py = Std.int((FlxG.height - POPUP_H) / 2);

		popupBg = new FlxSprite(px, py);
		popupBg.makeGraphic(POPUP_W, POPUP_H, FlxColor.fromRGB(24, 24, 36));
		popupBg.scrollFactor.set(0, 0);
		popupBg.cameras = [cam];
		add(popupBg);

		titleText = Styles.makeLabel("Create Modifier", px, py + 10, POPUP_W, 20);
		titleText.alignment = "center";
		titleText.cameras = [cam];
		add(titleText);

		var modOptions:Array<String> = [];
		for (key in ModifierRegistry.definitions.keys())
			modOptions.push(key);
		if (modOptions.length == 0) modOptions = ["cameraZoom"];
		selectedModifier = modOptions[0];

		var yOff = py + 50;
		var fieldW = POPUP_W - 40;
		var col1x = px + 20;
		var col2x = px + 130;

		var nameLabel = Styles.makeInfoLabel("Name:", col1x, yOff, 90);
		nameLabel.cameras = [cam];
		add(nameLabel);

		nameInput = new FlxUIInputText(col2x, yOff, fieldW - 110, "", 12, FlxColor.WHITE, FlxColor.fromRGB(30, 30, 40));
		nameInput.scrollFactor.set(0, 0);
		nameInput.cameras = [cam];
		add(nameInput);

		var modLabel = Styles.makeInfoLabel("Type:", col1x, yOff + 40, 90);
		modLabel.cameras = [cam];
		add(modLabel);

		var modLabels = FlxUIDropDownMenu.makeStrIdLabelArray(modOptions);
		modifierDropdown = new FlxUIDropDownMenu(col2x, yOff + 38, modLabels, function(selectedId:String) {
			selectedModifier = selectedId;
			if (descText != null) descText.text = getModifierDescription(selectedId);
		});
		modifierDropdown.selectedLabel = selectedModifier;
		modifierDropdown.scrollFactor.set(0, 0);
		modifierDropdown.cameras = [cam];
		add(modifierDropdown);

		descText = new FlxText(px + 20, yOff + 70, POPUP_W - 40, getModifierDescription(selectedModifier), 10);
		descText.alignment = "center";
		descText.color = FlxColor.WHITE;
		descText.scrollFactor.set(0, 0);
		descText.cameras = [cam];
		add(descText);

		createBtn = new FlxUIButton(px + 20, py + POPUP_H - 50, "Create", createModifier);
		createBtn.scrollFactor.set(0, 0);
		createBtn.cameras = [cam];
		add(createBtn);

		closeBtn = new FlxUIButton(px + POPUP_W - 100, py + POPUP_H - 50, "Close", function() { close(); });
		closeBtn.scrollFactor.set(0, 0);
		closeBtn.cameras = [cam];
		add(closeBtn);
	}

	function createModifier():Void
	{
		var rawName = StringTools.trim(nameInput.text);
		if (rawName == "") rawName = selectedModifier;

		var exists = false;
		for (i in 0...parentState.loadedModifiers.length)
		{
			if (parentState.loadedModifiers[i].name == rawName)
			{
				parentState.loadedModifiers[i].modifier = selectedModifier;
				exists = true;
				break;
			}
		}

		if (!exists)
		{
			var entry:ModifierEntry = {
				name: rawName,
				modifier: selectedModifier,
				value: ModifierRegistry.getDefaultValue(selectedModifier),
				duration: null,
				ease: null,
				type: "set"
			};
			parentState.loadedModifiers.push(entry);
		}

		parentState.buildTimelineRows();
		close();
	}

	function getModifierDescription(modId:String):String
	{
		return switch (modId)
		{
			case "cameraZoom": "Zooms the camera in or out (1.0 is normal).\nExample: 1.2 (extra zoom)";
			case "cameraBump": "Temporary zoom bump that returns to its original value.\nExample: 0.1 (light bump)";
			case "cameraBumpX": "Horizontal camera bump that bounces back.\nExample: 50 (moves right)";
			case "cameraBumpY": "Vertical camera bump that bounces back.\nExample: -50 (moves up)";
			case "cameraBumpAngle": "Rotation bump that returns to 0.\nExample: 15 (tilts right)";
			case "cameracenter": "Centers the camera between both characters.\nExample: 1 (enabled), 0 (disabled)";
			case "turnDad": "Forces the camera to focus on the opponent.\nExample: 1 (enabled), 0 (disabled)";
			case "turnBf": "Forces the camera to focus on the player.\nExample: 1 (enabled), 0 (disabled)";
			case "trackSingDirections_dad": "Camera pans slightly when the opponent sings.\nExample: 1 (enabled)";
			case "trackSingDirections_bf": "Camera pans slightly when the player sings.\nExample: 1 (enabled)";
			case "cameraFly": "Camera floats in an infinity loop shape.\nExample: 1 (normal intensity), 2 (fast)";
			case "cameraAngle": "Tilts the screen in degrees.\nExample: 15 (right), -15 (left)";
			case "cameraPosX": "Offsets the screen horizontally in pixels.\nExample: 100 (right)";
			case "cameraPosY": "Offsets the screen vertically in pixels.\nExample: -100 (up)";

			default: "No description available.\nExample: N/A";
		};
	}

	override public function close():Void
	{
		if (parentState != null)
			parentState.buildTimelineRows();
		super.close();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE) close();
	}
}
