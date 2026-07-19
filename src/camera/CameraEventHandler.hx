package camera;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;
import atoms.EaseUtils;
import camera.ModchartData.ModifierEntry;
import camera.ModchartData.TimelineModifierPlacement;
import camera.ModchartData.CameraEventsSaveData;
import camera.CameraEventData;
import camera.CameraModifiers;
using StringTools;

class CameraEventHandler
{
	public var modifiers:Array<ModifierEntry>;
	public var placements:Array<TimelineModifierPlacement>;
	public var songStart:camera.ModchartData.SongStartData;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;

	public var dad:Dynamic;
	public var boyfriend:Dynamic;
	public var stage:Dynamic;

	public var lerpSpeed:Float = 0.04;
	var lastBumpValue:Float = 0.0;
	var followDisabled:Bool = false;
	var currentSingOffsetX:Float = 0.0;
	var currentSingOffsetY:Float = 0.0;
	
	var lastTracedValues:Map<String, Float> = new Map();

	public function new(data:CameraEventsSaveData, camGame:FlxCamera, camHUD:FlxCamera)
	{
		CameraModifiers.init();
		this.modifiers = data.modifiers != null ? data.modifiers : [];

		var rawPlacements = data.placements != null ? data.placements : [];
		var finalPlacements:Array<TimelineModifierPlacement> = [];

		for (pl in rawPlacements) {
			if (pl.repeat == null) {
				finalPlacements.push(pl);
			} else if (pl.repeat[0] == true) { // EVENT_REPEATBOOL
				var rCount:Int = Std.int(pl.repeat[1]);
				var rGap:Float = pl.repeat[2];
				finalPlacements.push(pl);
				for (j in 1...(rCount + 1)) {
					var duplicated:TimelineModifierPlacement = {
						modifierRef: pl.modifierRef,
						value: pl.value,
						type: pl.type,
						duration: pl.duration,
						ease: pl.ease,
						beat: pl.beat + (j * rGap),
						repeat: (pl.repeat != null) ? [pl.repeat[0], pl.repeat[1], pl.repeat[2]] : null
					};
					finalPlacements.push(duplicated);
				}
			} else {
				finalPlacements.push(pl);
			}
		}
		
		this.placements = finalPlacements;
		this.placements.sort(function(a, b) return (a.beat < b.beat) ? -1 : ((a.beat > b.beat) ? 1 : 0));
		
		this.songStart = data.songStart;
		this.camGame = camGame;
		this.camHUD = camHUD;
	}

	function getModifierValue(modifierId:String, step:Float):Float
	{
		var defVal = ModifierRegistry.getDefaultValue(modifierId);
		if (modifiers != null) {
			for (m in modifiers) {
				if (m.modifier == modifierId) {
					defVal = m.value;
					break;
				}
			}
		}
		var result = defVal;
		var lastVal = defVal;

		if (this.songStart != null && this.songStart.modifierRef == modifierId)
		{
			var durBeats:Float = (this.songStart.duration != null && this.songStart.duration > 0) ? this.songStart.duration : 1;
			var durSteps = durBeats * 4;
			var startStep = -16.0;

			if (step >= startStep + durSteps) {
				result = this.songStart.value;
				lastVal = result;
				if (modifierId == "cameracenter") trace("songStart cameracenter finished! Value: " + result);
			} else if (step >= startStep && step < startStep + durSteps) {
				if (this.songStart.type == "tween") {
					var t = (step - startStep) / durSteps;
					if (this.songStart.ease != null && this.songStart.ease != "linear") t = EaseUtils.fromName(this.songStart.ease)(t);
					var ret = lastVal + (this.songStart.value - lastVal) * t;
					if (modifierId == "cameracenter") trace("songStart cameracenter tweening: " + ret + " (step: " + step + ")");
					return ret;
				} else {
					result = this.songStart.value;
					lastVal = result;
					if (modifierId == "cameracenter") trace("songStart cameracenter set active! Value: " + result);
				}
			}
		}

		for (pl in placements)
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

			if (pl.type == "set" || step >= placementStep + durSteps) {
				result = pl.value;
				lastVal = result;
			} else {
				var t = (step - placementStep) / durSteps;
				if (pl.ease != null && pl.ease != "linear") t = EaseUtils.fromName(pl.ease)(t);
				result = lastVal + (pl.value - lastVal) * t;
				break;
			}
		}

		if (modifierId.indexOf("trackSing") != -1 || modifierId == "cameracenter") {
			if (!lastTracedValues.exists(modifierId) || lastTracedValues.get(modifierId) != result) {
				lastTracedValues.set(modifierId, result);
				trace("[EVENT READ] " + modifierId + " changed to: " + result + " at step: " + step);
			}
		}

		return result;
	}

	public function isTweenActive(step:Float, modifierIds:Array<String>):Bool
	{
		if (songStart != null && modifierIds.indexOf(songStart.modifierRef) != -1)
		{
			var startStep = -16.0;
			var durSteps = ((songStart.duration != null && songStart.duration > 0) ? songStart.duration : 1) * 4;
			if (step >= startStep && step <= startStep + durSteps && songStart.type != "set") return true;
		}
		for (pl in placements)
		{
			if (modifierIds.indexOf(pl.modifierRef) == -1) continue;
			var placementStep = pl.beat * 4;
			var durSteps:Float = ((pl.duration != null && pl.duration > 0) ? pl.duration : 1) * 4;
			if (step >= placementStep && step <= placementStep + durSteps && pl.type != "set") return true;
		}
		return false;
	}

	public function getCameraData(step:Float):CameraEventData
	{
		var data = new CameraEventData();
		data.camZoom = getModifierValue("cameraZoom", step);
		data.cameraBump = getModifierValue("cameraBump", step);
		data.camAngle = getModifierValue("cameraAngle", step);
		data.camPosX = getModifierValue("cameraPosX", step);
		data.camPosY = getModifierValue("cameraPosY", step);
		data.camFollowX = getModifierValue("cameraFollowX", step);
		data.camFollowY = getModifierValue("cameraFollowY", step);
		data.turnDad = getModifierValue("turnDad", step) + getModifierValue("turn", step);
		data.turnBf = getModifierValue("turnBf", step) + getModifierValue("turn", step);
		data.camCenter = getModifierValue("cameracenter", step);
		data.trackDad = Math.max(getModifierValue("trackSingDirections_dad", step), getModifierValue("trackSingDirections", step));
		data.trackBf = Math.max(getModifierValue("trackSingDirections_bf", step), getModifierValue("trackSingDirections", step));
		data.cameraFly = getModifierValue("cameraFly", step);
		data.hasPosTween = isTweenActive(step, ["cameraPosX", "cameraPosY", "cameraFollowX", "cameraFollowY", "cameracenter", "turnDad", "turnBf", "turn"]);
		data.hasZoomTween = isTweenActive(step, ["cameraZoom"]);
		return data;
	}

	public function computeTarget(data:CameraEventData):Void
	{
		var targetX:Float = 0;
		var targetY:Float = 0;
		var targetSingOffsetX:Float = 0.0;
		var targetSingOffsetY:Float = 0.0;

		if (dad != null && boyfriend != null) {
			try {
				var mainBf:Dynamic = boyfriend;
				try { mainBf = boyfriend.getCameraCharacter(); } catch(e:Dynamic) {}
				var mainDad:Dynamic = dad;
				try { mainDad = dad.getCameraCharacter(); } catch(e:Dynamic) {}
				
				var bfMid = Reflect.callMethod(mainBf, Reflect.field(mainBf, "getMidpoint"), []);
				var dadMid = Reflect.callMethod(mainDad, Reflect.field(mainDad, "getMidpoint"), []);
				
				var bfOffset:Array<Dynamic> = Reflect.getProperty(mainBf, "cameraOffset");
				if (bfOffset == null) bfOffset = Reflect.getProperty(mainBf, "cameraPosition");
				var dadOffset:Array<Dynamic> = Reflect.getProperty(mainDad, "cameraOffset");
				if (dadOffset == null) dadOffset = Reflect.getProperty(mainDad, "cameraPosition");

				var p1X = bfMid.x;
				var p1Y = bfMid.y;
				var p2X = dadMid.x;
				var p2Y = dadMid.y;

				if (stage != null) {
					var p1CamOff = Reflect.getProperty(stage, "p1_Cam_Offset");
					if (p1CamOff != null) { p1X += p1CamOff.x; p1Y += p1CamOff.y; }
					var p2CamOff = Reflect.getProperty(stage, "p2_Cam_Offset");
					if (p2CamOff != null) { p2X += p2CamOff.x; p2Y += p2CamOff.y; }
				}

				var bfTargetX = p1X - 100 + (bfOffset != null ? bfOffset[0] : 0);
				var bfTargetY = p1Y - 100 + (bfOffset != null ? bfOffset[1] : 0);
				
				var dadTargetX = p2X + 150 + (dadOffset != null ? dadOffset[0] : 0);
				var dadTargetY = p2Y - 100 + (dadOffset != null ? dadOffset[1] : 0);

				var centerTargetX = (bfTargetX + dadTargetX) * 0.5;
				var centerTargetY = (bfTargetY + dadTargetY) * 0.5;

				var defaultTargetX = bfTargetX;
				var defaultTargetY = bfTargetY;

				try {
					var state:Dynamic = flixel.FlxG.state;
					if (state != null) {
						var song = Reflect.field(state, "SONG");
						var curSec = Reflect.field(state, "curSection");
						if (song != null && curSec != null) {
							var notes:Array<Dynamic> = Reflect.field(song, "notes");
							if (notes != null && curSec >= 0 && curSec < notes.length) {
								if (notes[curSec].mustHitSection == true) {
									defaultTargetX = bfTargetX;
									defaultTargetY = bfTargetY;
								} else {
									defaultTargetX = dadTargetX;
									defaultTargetY = dadTargetY;
								}
							}
						}
					}
				} catch(e:Dynamic) {}

				targetX = defaultTargetX;
				targetY = defaultTargetY;

				targetX = flixel.math.FlxMath.lerp(targetX, centerTargetX, data.camCenter);
				targetY = flixel.math.FlxMath.lerp(targetY, centerTargetY, data.camCenter);

				targetX = flixel.math.FlxMath.lerp(targetX, dadTargetX, data.turnDad);
				targetY = flixel.math.FlxMath.lerp(targetY, dadTargetY, data.turnDad);

				targetX = flixel.math.FlxMath.lerp(targetX, bfTargetX, data.turnBf);
				targetY = flixel.math.FlxMath.lerp(targetY, bfTargetY, data.turnBf);

				var singOffset = 50.0;
				function getTrackChar(char:Dynamic):Dynamic {
					var camChar:Dynamic = null;
					try { camChar = char.getCameraCharacter(); } catch(e:Dynamic) {}
					return (camChar != null) ? camChar : char;
				}
				function applyDirOffset(char:Dynamic, isDad:Bool):Void {
					var animName = '';
					try { animName = char.curAnimName().toLowerCase(); } catch(e:Dynamic) {
						try { animName = char.animation.curAnim.name.toLowerCase(); } catch(e2:Dynamic) {}
					}
					trace("TrackSing -> " + (isDad ? "Dad" : "BF") + " Animation detected: '" + animName + "'");
					if (animName.indexOf('singleft') != -1) targetSingOffsetX -= singOffset;
					else if (animName.indexOf('singright') != -1) targetSingOffsetX += singOffset;
					else if (animName.indexOf('singup') != -1) targetSingOffsetY -= singOffset;
					else if (animName.indexOf('singdown') != -1) targetSingOffsetY += singOffset;
				}
				if (data.trackDad >= 0.5) {
					trace("trackDad modifier is ACTIVE! Applying offset...");
					applyDirOffset(getTrackChar(dad), true);
				}
				if (data.trackBf >= 0.5) {
					trace("trackBf modifier is ACTIVE! Applying offset...");
					applyDirOffset(getTrackChar(boyfriend), false);
				}
			} catch(e:Dynamic) {
				targetX = FlxG.width * 0.5;
				targetY = FlxG.height * 0.5;
			}
		} else {
			targetX = FlxG.width * 0.5;
			targetY = FlxG.height * 0.5;
		}

		if (data.camPosX != 0 || data.camPosY != 0) {
			targetX += data.camPosX;
			targetY += data.camPosY;
		}

		if (data.cameraFly > 0) {
			var time = (FlxG.sound.music != null) ? FlxG.sound.music.time / 1000.0 : 0.0;
			targetX += Math.sin(time * 2) * 50 * data.cameraFly;
			targetY += Math.sin(time * 4) * 25 * data.cameraFly;
		}

		targetX += data.camFollowX;
		targetY += data.camFollowY;

		data.targetX = targetX;
		data.targetY = targetY;
		data.singOffsetX = targetSingOffsetX;
		data.singOffsetY = targetSingOffsetY;
	}

	public function applyCameraData(data:CameraEventData, elapsed:Float, defaultCamZoom:Float, defaultHudCamZoom:Float, cameraZoomSpeed:Float):Void
	{
		if (!followDisabled) {
			camGame.follow(null);
			followDisabled = true;
		}

		var singLerpVal = 0.15 * FlxG.elapsed * 60;
		if (singLerpVal > 1) singLerpVal = 1;
		currentSingOffsetX = FlxMath.lerp(currentSingOffsetX, data.singOffsetX, singLerpVal);
		currentSingOffsetY = FlxMath.lerp(currentSingOffsetY, data.singOffsetY, singLerpVal);
		
		var desiredScrollX = (data.targetX - FlxG.width * 0.5) + currentSingOffsetX;
		var desiredScrollY = (data.targetY - FlxG.height * 0.5) + currentSingOffsetY;

		if (data.hasPosTween) {
			camGame.scroll.x = desiredScrollX;
			camGame.scroll.y = desiredScrollY;
		} else {
			var lerpVal:Float = lerpSpeed * FlxG.elapsed * 60;
			if (lerpVal > 1) lerpVal = 1;
			camGame.scroll.x = FlxMath.lerp(camGame.scroll.x, desiredScrollX, lerpVal);
			camGame.scroll.y = FlxMath.lerp(camGame.scroll.y, desiredScrollY, lerpVal);
		}
		
		var targetZoom = defaultCamZoom * data.camZoom;
		
		if (data.cameraBump != lastBumpValue) {
			if (data.cameraBump > lastBumpValue) {
				camGame.zoom += (data.cameraBump - lastBumpValue);
			}
			lastBumpValue = data.cameraBump;
		}

		if (data.hasZoomTween) {
			camGame.zoom = targetZoom;
		} else {
			var zoomLerp:Float = (elapsed * 3) * cameraZoomSpeed;
			camGame.zoom = FlxMath.lerp(camGame.zoom, targetZoom, zoomLerp);
		}

		camGame.angle = data.camAngle;

		var hudLerp:Float = (elapsed * 3) * cameraZoomSpeed;
		camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudCamZoom, hudLerp);
	}

	public function update(elapsed:Float, curDecStep:Float, defaultCamZoom:Float, defaultHudCamZoom:Float, cameraZoomSpeed:Float):Void
	{
		if (dad == null || boyfriend == null) {
			var state:Dynamic = FlxG.state;
			if (state != null) {
				try {
					if (dad == null) {
						dad = Reflect.field(state, "dad");
						if (dad == null) dad = Reflect.field(state, "dadCharacter");
						if (dad == null) dad = Reflect.field(state, "player2");
					}
					if (boyfriend == null) {
						boyfriend = Reflect.field(state, "boyfriend");
						if (boyfriend == null) boyfriend = Reflect.field(state, "bf");
						if (boyfriend == null) boyfriend = Reflect.field(state, "player1");
					}
					if (stage == null) {
						stage = Reflect.field(state, "stage");
						if (stage == null) stage = Reflect.field(state, "stageGroup");
					}
				} catch(e:Dynamic) {}
			}
		}

		var data = getCameraData(curDecStep);
		computeTarget(data);
		applyCameraData(data, elapsed, defaultCamZoom, defaultHudCamZoom, cameraZoomSpeed);
	}}
