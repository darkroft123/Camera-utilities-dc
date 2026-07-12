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

		ModifierRegistry.register("cameraAngle", "Camera Angle", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modAngle = value;
		});

		ModifierRegistry.register("cameraPosX", "Camera Position X", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modPosX = value;
		});

		ModifierRegistry.register("cameraPosY", "Camera Position Y", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modPosY = value;
		});

		ModifierRegistry.register("cameraFollowX", "Camera Follow X", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modFollowX = value;
		});

		ModifierRegistry.register("cameraFollowY", "Camera Follow Y", 0.0, function(value:Float, state:ModchartEditor) {
			if (state.editorPreview != null) state.editorPreview.modFollowY = value;
		});
	}
}
