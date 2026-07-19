package camera;

import flixel.FlxG;
import pages.ModchartEditor;
import camera.ModifierRegistry;

class CameraModifiers
{
	public static function init():Void
	{
		ModifierRegistry.register("cameraZoom", "Camera Zoom", 1.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modZoom = value;
		});

		ModifierRegistry.register("cameraBump", "Camera Bump", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modBump = value;
		});
		ModifierRegistry.register("cameraBumpX", "Camera Bump X", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modBumpX = value;
		});
		ModifierRegistry.register("cameraBumpY", "Camera Bump Y", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modBumpY = value;
		});
		ModifierRegistry.register("cameraBumpAngle", "Camera Bump Angle", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modBumpAngle = value;
		});
		ModifierRegistry.register("cameracenter", "Camera Center", 1.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.centerCamera = (value >= 0.5);
		});

		ModifierRegistry.register("turnDad", "Turn Dad", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.turnDad = value;
		});

		ModifierRegistry.register("turnBf", "Turn BF", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.turnBf = value;
		});

		ModifierRegistry.register("trackSingDirections", "Track Both Singing", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null && value >= 0.5) {
				state.editorPreview.trackDad = true;
				state.editorPreview.trackBf = true;
			}
		});

		ModifierRegistry.register("trackSingDirections_dad", "Track Dad Singing", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null && value >= 0.5) state.editorPreview.trackDad = true;
		});

		ModifierRegistry.register("trackSingDirections_bf", "Track BF Singing", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null && value >= 0.5) state.editorPreview.trackBf = true;
		});

		ModifierRegistry.register("cameraFly", "Camera Fly (Infinity)", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.cameraFly = value;
		});

		ModifierRegistry.register("cameraAngle", "Camera Angle", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modAngle = value;
		});

		ModifierRegistry.register("cameraPosX", "Camera Position X", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modPosX = value;
		});

		ModifierRegistry.register("cameraPosY", "Camera Position Y", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modPosY = value;
		});
	}
}
