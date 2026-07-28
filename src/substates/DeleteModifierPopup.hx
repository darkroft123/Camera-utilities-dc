package substates;

import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import ui.FlxScrollableDropDownMenu;
import flixel.addons.ui.FlxUIButton;
using StringTools;
import pages.ModchartEditor;
import atoms.Styles;

class DeleteModifierPopup extends FlxSubState
{
	public var parentState:ModchartEditor;

	static final POPUP_W:Int = 320;
	static final POPUP_H:Int = 180;

	var popupBg:FlxSprite;
	var titleText:FlxText;

	var modifierDropdown:FlxScrollableDropDownMenu;

	var deleteBtn:FlxUIButton;
	var closeBtn:FlxUIButton;

	var selectedModifierName:String = "";

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

		titleText = Styles.makeLabel("Delete Modifier", px, py + 10, POPUP_W, 20);
		titleText.alignment = "center";
		titleText.color = FlxColor.RED;
		titleText.cameras = [cam];
		add(titleText);

		var modOptions:Array<String> = [];
		for (info in parentState.loadedModifiers) {
			if (info.name != "Song Start") modOptions.push(info.name);
		}
		
		if (modOptions.length == 0) {
			selectedModifierName = "";
			var emptyText = Styles.makeInfoLabel("No modifiers to delete.", px, py + 60, POPUP_W);
			emptyText.alignment = "center";
			emptyText.cameras = [cam];
			add(emptyText);
		} else {
			selectedModifierName = modOptions[0];

			var modLabel = Styles.makeInfoLabel("Modifier:", px + 20, py + 70, 90);
			modLabel.cameras = [cam];
			add(modLabel);

			var modLabels = FlxScrollableDropDownMenu.makeStrIdLabelArray(modOptions);
			modifierDropdown = new FlxScrollableDropDownMenu(px + 100, py + 68, modLabels, function(selectedId:String) {
				selectedModifierName = selectedId;
			});
			modifierDropdown.selectedLabel = selectedModifierName;
			modifierDropdown.scrollFactor.set(0, 0);
			modifierDropdown.cameras = [cam];
		}

		deleteBtn = new FlxUIButton(px + 30, py + POPUP_H - 40, "Delete", function() {
			if (selectedModifierName != "") {
				parentState.deleteLoadedModifier(selectedModifierName);
			}
			close();
		});
		deleteBtn.color = FlxColor.RED;
		deleteBtn.label.color = FlxColor.WHITE;
		deleteBtn.cameras = [cam];
		add(deleteBtn);

		closeBtn = new FlxUIButton(px + POPUP_W - 110, py + POPUP_H - 40, "Cancel", function() {
			close();
		});
		closeBtn.cameras = [cam];
		add(closeBtn);

		if (modifierDropdown != null) add(modifierDropdown); // Add dropdown last so it renders on top
	}
}
