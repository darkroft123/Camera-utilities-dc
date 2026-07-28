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
	public var evaluator:camera.utilities.ModifierEvaluator;
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;

	public var dad:Dynamic;
	public var boyfriend:Dynamic;
	public var stage:Dynamic;

	public var lerpSpeed:Float = 0.04;
	var lastBumpValue:Float = 0.0;
	var lastBumpXValue:Float = 0.0;
	var lastBumpYValue:Float = 0.0;
	var lastBumpAngleValue:Float = 0.0;
	public var followDisabled:Bool = false;
	
	// Variables to recover base camera state and apply un-lerped offsets
	var turnAngleOffset:Float = 0;
	var lastP1X:Float = -9999;
	var lastP1Y:Float = -9999;
	var lastP2X:Float = -9999;
	var lastP2Y:Float = -9999;
	var lastOffsetX:Float = 0;
	var lastOffsetY:Float = 0;
	var lastExtraZoom:Float = 0;
	var lastExtraAngle:Float = 0;
	var currentSingOffsetX:Float = 0.0;
	var currentSingOffsetY:Float = 0.0;

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
		
		this.songStart = data.songStart;
		this.camGame = camGame;
		this.camHUD = camHUD;

		evaluator = new camera.utilities.ModifierEvaluator(modifiers, finalPlacements, songStart);
	}

	public function getCameraData(step:Float):CameraEventData
	{
		return evaluator.evaluateAllCameraData(step);
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

				var bfValid = true;
				var dadValid = true;
				
				try {
					if (mainBf.cameras != null && mainBf.cameras.indexOf(camGame) == -1) bfValid = false;
					if (mainBf.scrollFactor != null && mainBf.scrollFactor.x == 0 && mainBf.scrollFactor.y == 0) bfValid = false;
				} catch(e:Dynamic) {}
				
				if (bfValid || lastP1X == -9999) {
					lastP1X = p1X;
					lastP1Y = p1Y;
				} else {
					p1X = lastP1X;
					p1Y = lastP1Y;
				}
				
				try {
					if (mainDad.cameras != null && mainDad.cameras.indexOf(camGame) == -1) dadValid = false;
					if (mainDad.scrollFactor != null && mainDad.scrollFactor.x == 0 && mainDad.scrollFactor.y == 0) dadValid = false;
				} catch(e:Dynamic) {}
				
				if (dadValid || lastP2X == -9999) {
					lastP2X = p2X;
					lastP2Y = p2Y;
				} else {
					p2X = lastP2X;
					p2Y = lastP2Y;
				}

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
						try { animName = char.animation.curAnim.name.toLowerCase(); } catch(e2:Dynamic) {
							try { animName = char.animation.name.toLowerCase(); } catch(e3:Dynamic) {}
						}
					}
					if (animName.indexOf('singleft') != -1) targetSingOffsetX -= singOffset;
					else if (animName.indexOf('singright') != -1) targetSingOffsetX += singOffset;
					else if (animName.indexOf('singup') != -1) targetSingOffsetY -= singOffset;
					else if (animName.indexOf('singdown') != -1) targetSingOffsetY += singOffset;
				}
				if (data.trackDad >= 0.5) {
					applyDirOffset(dad, true);
				}
				if (data.trackBf >= 0.5) {
					applyDirOffset(boyfriend, false);
				}
			} catch(e:Dynamic) {
				targetX = FlxG.width * 0.5;
				targetY = FlxG.height * 0.5;
			}
		} else {
			targetX = FlxG.width * 0.5;
			targetY = FlxG.height * 0.5;
		}

		// Removed camPosX and camPosY from targetX/Y, they will be applied as direct offsets later

		if (data.cameraFly > 0) {
			var time = (FlxG.sound.music != null) ? FlxG.sound.music.time / 1000.0 : 0.0;
			targetX += Math.sin(time * 2) * 50 * data.cameraFly;
			targetY += Math.sin(time * 4) * 25 * data.cameraFly;
		}

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

		// Recover base scroll by subtracting last frame's offsets
		var baseScrollX = camGame.scroll.x - lastOffsetX;
		var baseScrollY = camGame.scroll.y - lastOffsetY;

		var lerpVal:Float = lerpSpeed * FlxG.elapsed * 60;
		if (lerpVal > 1) lerpVal = 1;
		
		// Calculate current offsets
		var currentOffsetX = data.camPosX + data.cameraBumpX;
		var currentOffsetY = data.camPosY + data.cameraBumpY;

		camGame.scroll.x = flixel.math.FlxMath.lerp(baseScrollX, desiredScrollX, lerpVal) + currentOffsetX;
		camGame.scroll.y = flixel.math.FlxMath.lerp(baseScrollY, desiredScrollY, lerpVal) + currentOffsetY;
		
		lastOffsetX = currentOffsetX;
		lastOffsetY = currentOffsetY;

		var zoomLerp:Float = (elapsed * 3) * cameraZoomSpeed;
		var targetZoomBase = defaultCamZoom;
		var currentExtraZoom = (data.camZoom - 1.0) * defaultCamZoom + data.cameraBump;
		var baseZoom = camGame.zoom - lastExtraZoom;
		
		camGame.zoom = flixel.math.FlxMath.lerp(baseZoom, targetZoomBase, zoomLerp) + currentExtraZoom;
		lastExtraZoom = currentExtraZoom;

		var currentExtraAngle = data.camAngle + data.cameraBumpAngle;
		var baseAngle = camGame.angle - lastExtraAngle;
		
		camGame.angle = flixel.math.FlxMath.lerp(baseAngle, 0, zoomLerp) + currentExtraAngle;
		lastExtraAngle = currentExtraAngle;

		var hudLerp:Float = (elapsed * 3) * cameraZoomSpeed;
		camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudCamZoom, hudLerp);
	}

	function getFieldSafe(obj:Dynamic, fields:Array<String>):Dynamic {
		for (f in fields) {
			var val = Reflect.field(obj, f);
			if (val == null) {
				var cls = Type.getClass(obj);
				if (cls != null) val = Reflect.field(cls, f);
			}
			if (val != null) return val;
		}
		return null;
	}

	public function update(elapsed:Float, curDecStep:Float, defaultCamZoom:Float, defaultHudCamZoom:Float, cameraZoomSpeed:Float):Void
	{
		var state:Dynamic = FlxG.state;
		if (state != null) {
			try {
				var newDad = getFieldSafe(state, ["dad", "dadCharacter", "player2"]);
				if (newDad != null) dad = newDad;
				
				var newBf = getFieldSafe(state, ["boyfriend", "bf", "player1"]);
				if (newBf != null) boyfriend = newBf;
				
				var newStage = getFieldSafe(state, ["stage", "stageGroup"]);
				if (newStage != null) stage = newStage;
			} catch(e:Dynamic) {}
		}

		var data = getCameraData(curDecStep);
		computeTarget(data);
		applyCameraData(data, elapsed, defaultCamZoom, defaultHudCamZoom, cameraZoomSpeed);
	}}
