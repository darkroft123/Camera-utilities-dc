package camera;

import flixel.FlxCamera;
import flixel.math.FlxMath;
import atoms.EaseUtils;

class CameraEventHandler
{
	var modifiers:Array<ModifierEntry>;
	var placements:Array<TimelineModifierPlacement>;
	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	public function new(data:CameraEventsSaveData, camGame:FlxCamera, camHUD:FlxCamera)
	{
		this.modifiers = data.modifiers != null ? data.modifiers : [];
		this.placements = data.placements != null ? data.placements : [];
		this.camGame = camGame;
		this.camHUD = camHUD;
	}

	function getModifierValue(modifierId:String, step:Float):Float
	{
		var defVal = ModifierRegistry.getDefaultValue(modifierId);
		var result = defVal;
		for (pl in placements)
		{
			if (pl.modifierRef != modifierId) continue;
			var placementStep = pl.beat * 4;
			var dur:Float = (pl.duration != null && pl.duration > 0) ? pl.duration : 1;
			if (step < placementStep) continue;

			var offset:Float = pl.value;
			if (pl.type == "tween" && step < placementStep + dur)
			{
				var t = (step - placementStep) / dur;
				if (pl.ease != null && pl.ease != "linear") t = EaseUtils.fromName(pl.ease)(t);
				offset *= t;
			}
			result += offset;
		}
		return result;
	}

	public function update(elapsed:Float, curDecStep:Float, defaultCamZoom:Float, defaultHudCamZoom:Float, cameraZoomSpeed:Float)
	{
		var step:Float = curDecStep;

		var camZoom = getModifierValue("cameraZoom", step);
		var camAngle = getModifierValue("cameraAngle", step);
		var camPosX = getModifierValue("cameraPosX", step);
		var camPosY = getModifierValue("cameraPosY", step);
		var camFollowX = getModifierValue("cameraFollowX", step);
		var camFollowY = getModifierValue("cameraFollowY", step);

		var zoomLerp:Float = (elapsed * 3) * cameraZoomSpeed;

		camGame.scroll.x += camPosX + camFollowX;
		camGame.scroll.y += camPosY + camFollowY;

		var targetZoom = defaultCamZoom * camZoom;
		camGame.zoom = FlxMath.lerp(camGame.zoom, targetZoom, zoomLerp);
		camGame.angle += camAngle;

		camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudCamZoom, zoomLerp);
	}
}
