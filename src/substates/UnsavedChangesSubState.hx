package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSubState;
import pages.ModchartEditor;
import states.PlayState;
import atoms.ColorConstants;
import flixel.addons.ui.FlxUIButton;

class UnsavedChangesSubState extends FlxSubState
{
	var editor:ModchartEditor;

	public function new(editor:ModchartEditor)
	{
		super();
		this.editor = editor;
	}

	override function create()
	{
		super.create();

		FlxG.mouse.visible = true;

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x88000000);
		bg.scrollFactor.set();
		bg.cameras = [editor.camEditorTop];
		add(bg);

		var panel = new FlxSprite(0, 0).makeGraphic(400, 200, 0xFF1A1A2E);
		panel.screenCenter();
		panel.scrollFactor.set();
		panel.cameras = [editor.camEditorTop];
		add(panel);

		var text = new FlxText(0, panel.y + 30, FlxG.width, "You have unsaved changes!\nAre you sure you want to exit?", 24);
		text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, "center");
		text.scrollFactor.set();
		text.cameras = [editor.camEditorTop];
		add(text);

		var btnYes = new FlxUIButton(panel.x + 50, panel.y + 130, "Yes", function() {
			editor.saveCameraEvents(false);
			FlxG.sound.music.stop();
			FlxG.switchState(() -> new PlayState());
		});
		btnYes.cameras = [editor.camEditorTop];
		add(btnYes);

		var btnNo = new FlxUIButton(panel.x + 150, panel.y + 130, "No", function() {
			FlxG.sound.music.stop();
			FlxG.switchState(() -> new PlayState());
		});
		btnNo.cameras = [editor.camEditorTop];
		add(btnNo);

		var btnCancel = new FlxUIButton(panel.x + 250, panel.y + 130, "Cancel", function() {
			close();
		});
		btnCancel.cameras = [editor.camEditorTop];
		add(btnCancel);
	}
}
