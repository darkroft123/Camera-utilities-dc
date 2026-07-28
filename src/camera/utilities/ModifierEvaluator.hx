package camera.utilities;

import atoms.EaseUtils;
import camera.ModchartData.TimelineModifierPlacement;
import camera.ModchartData.ModifierEntry;
import camera.ModchartData.SongStartData;
import camera.ModifierRegistry;
import StringTools;

typedef EvaluatedPlacement = {
	var value:Float;
	var type:String;
	var startStep:Float;
	var durSteps:Float;
	var easeFunc:(t:Float)->Float;
}

class ModifierEvaluator
{
	public var baseModifiers:Map<String, Float> = new Map();
	public var placementsByMod:Map<String, Array<EvaluatedPlacement>> = new Map();
	public var songStartByMod:Map<String, EvaluatedPlacement> = new Map();
	public var activeTweenMods:Map<String, Bool> = new Map();

	public function new(modifiers:Array<ModifierEntry>, placements:Array<TimelineModifierPlacement>, songStart:SongStartData)
	{
		refresh(modifiers, placements, songStart);
	}

	public function refresh(modifiers:Array<ModifierEntry>, placements:Array<TimelineModifierPlacement>, songStart:SongStartData)
	{
		baseModifiers.clear();
		for (key in placementsByMod.keys()) {
			var arr = placementsByMod.get(key);
			arr.splice(0, arr.length);
		}
		songStartByMod.clear();

		if (modifiers != null) {
			for (m in modifiers) {
				baseModifiers.set(m.modifier, m.value);
			}
		}

		if (placements != null) {
			for (pl in placements) {
				var ref = pl.modifierRef;
				if (!placementsByMod.exists(ref)) {
					placementsByMod.set(ref, []);
				}
				
				var durSteps:Float = ((pl.duration != null && pl.duration > 0) ? pl.duration : 1) * 4;
				var eFunc = (pl.ease != null && pl.ease != "linear") ? EaseUtils.fromName(pl.ease) : null;

				placementsByMod.get(ref).push({
					value: pl.value,
					type: pl.type,
					startStep: pl.beat * 4,
					durSteps: durSteps,
					easeFunc: eFunc
				});
			}

			// Sort sub-arrays chronologically so the evaluation loop works correctly
			for (arr in placementsByMod) {
				arr.sort(function(a, b) return (a.startStep < b.startStep) ? -1 : ((a.startStep > b.startStep) ? 1 : 0));
			}
		}

		if (songStart != null) {
			var ref = songStart.modifierRef;
			var durSteps:Float = ((songStart.duration != null && songStart.duration > 0) ? songStart.duration : 1) * 4;
			var eFunc = (songStart.ease != null && songStart.ease != "linear") ? EaseUtils.fromName(songStart.ease) : null;
			songStartByMod.set(ref, {
				value: songStart.value,
				type: songStart.type,
				startStep: -16.0,
				durSteps: durSteps,
				easeFunc: eFunc
			});
		}
	}

	public function getModifierValue(modifierId:String, step:Float):Float
	{
		var defVal = baseModifiers.exists(modifierId) ? baseModifiers.get(modifierId) : ModifierRegistry.getDefaultValue(modifierId);
		
		if (StringTools.startsWith(modifierId, "cameraBump")) {
			var currentBump = 0.0;
			
			if (songStartByMod.exists(modifierId)) {
				var st = songStartByMod.get(modifierId);
				if (step >= st.startStep && step < st.startStep + st.durSteps) {
					var t = (step - st.startStep) / st.durSteps;
					if (st.easeFunc != null) t = st.easeFunc(t);
					currentBump += st.value * (1.0 - t);
				}
			}

			if (placementsByMod.exists(modifierId)) {
				for (pl in placementsByMod.get(modifierId)) {
					if (step >= pl.startStep && step < pl.startStep + pl.durSteps) {
						var t = (step - pl.startStep) / pl.durSteps;
						if (pl.easeFunc != null) t = pl.easeFunc(t);
						currentBump += pl.value * (1.0 - t);
					}
				}
			}
			return currentBump;
		}

		var result = defVal;
		var lastVal = defVal;

		if (songStartByMod.exists(modifierId)) {
			var st = songStartByMod.get(modifierId);
			if (step >= st.startStep + st.durSteps) {
				result = st.value;
				lastVal = result;
			} else if (step >= st.startStep && step < st.startStep + st.durSteps) {
				if (st.type == "tween") {
					activeTweenMods.set(modifierId, true);
					var t = (step - st.startStep) / st.durSteps;
					if (st.easeFunc != null) t = st.easeFunc(t);
					return lastVal + (st.value - lastVal) * t;
				} else {
					result = st.value;
					lastVal = result;
				}
			}
		}

		if (placementsByMod.exists(modifierId)) {
			for (pl in placementsByMod.get(modifierId)) {
				if (step < pl.startStep) {
					if (pl.startStep <= 0 && pl.type == "set") {
						result = pl.value;
					}
					break;
				}

				if (pl.type == "set" || step >= pl.startStep + pl.durSteps) {
					result = pl.value;
					lastVal = result;
				} else {
					activeTweenMods.set(modifierId, true);
					var t = (step - pl.startStep) / pl.durSteps;
					if (pl.easeFunc != null) t = pl.easeFunc(t);
					result = lastVal + (pl.value - lastVal) * t;
					break;
				}
			}
		}

		return result;
	}

	public function evaluateAllCameraData(step:Float):camera.CameraEventData
	{
		activeTweenMods.clear();
		
		var data = new camera.CameraEventData();
		data.camZoom = getModifierValue("cameraZoom", step);
		data.cameraBump = getModifierValue("cameraBump", step);
		data.cameraBumpX = getModifierValue("cameraBumpX", step);
		data.cameraBumpY = getModifierValue("cameraBumpY", step);
		data.cameraBumpAngle = getModifierValue("cameraBumpAngle", step);
		data.camAngle = getModifierValue("cameraAngle", step);
		data.camPosX = getModifierValue("cameraPosX", step);
		data.camPosY = getModifierValue("cameraPosY", step);
		data.turnDad = getModifierValue("turnDad", step) + getModifierValue("turn", step);
		data.turnBf = getModifierValue("turnBf", step) + getModifierValue("turn", step);
		data.camCenter = getModifierValue("cameracenter", step);
		data.trackDad = Math.max(getModifierValue("trackSingDirections_dad", step), getModifierValue("trackSingDirections", step));
		data.trackBf = Math.max(getModifierValue("trackSingDirections_bf", step), getModifierValue("trackSingDirections", step));
		data.cameraFly = getModifierValue("cameraFly", step);
		
		data.hasTween = isTweenActiveFor(["cameraPosX", "cameraPosY", "cameracenter", "turnDad", "turnBf", "cameraZoom", "cameraAngle"]);
		return data;
	}

	public function isTweenActiveFor(modifierIds:Array<String>):Bool
	{
		for (id in modifierIds) {
			if (activeTweenMods.exists(id) && activeTweenMods.get(id) == true) return true;
		}
		return false;
	}
}
