package organisms;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
using StringTools;

import game.Boyfriend;
import game.Character;
import game.StageGroup;
import game.Conductor;
import game.StrumNote;
import utilities.NoteVariables;
import Paths;
import pages.ModchartEditor;
import states.PlayState;
import templates.EditorLayout;
import utilities.Options;
import utilities.CoolUtil;
import openfl.Assets;

class PreviewCamera
{
	public var gameplayContainer:FlxGroup;
	public var stage:StageGroup;
	public var dad:Character;
	public var boyfriend:Boyfriend;
	public var gf:Character;

	public var modZoom:Float = 1.0;
	public var modAngle:Float = 0.0;
	public var modPosX:Float = 0.0;
	public var modPosY:Float = 0.0;
	public var modFollowX:Float = 0.0;
	public var modFollowY:Float = 0.0;

	public var trackDad:Bool = false;
	public var trackBf:Bool = false;
	public var turnDad:Float = 0.0;
	public var turnBf:Float = 0.0;
	public var cameraFly:Float = 0.0;

	public var hasTween:Bool = false;
	public var lerpSpeed:Float = 0.04;

	public var strumLines:Array<Array<FlxSprite>> = [];

	public var notes:FlxTypedGroup<EditorNote>;
	public var unspawnNotes:Array<EditorNote>;
	public var centerCamera:Bool = true;
	public var curScale:Float = 0.5;
	public var lastSongPos:Float = 0.0;
	public var firstFrame:Bool = true;
	public var lastWasDragging:Bool = false;
	public var loadedNotes:Array<EditorNote> = [];

	var previewCam:FlxCamera;
	var state:ModchartEditor;
	var prevFullscreen:Bool = false;
	public var targetCrosshair:FlxSprite;
	var ui_settings:Array<String>;
	var mania_size:Array<String>;
	var originalScrollY:Float = 0.0;

	var currentSingOffsetX:Float = 0.0;
	var currentSingOffsetY:Float = 0.0;

	public function new(parent:ModchartEditor)
	{
		this.state = parent;
		previewCam = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
		previewCam.bgColor = 0;
	}

	public function playCharAnim(char:game.Character, anim:String)
	{
		if (char == null) return;
		if (char.animation != null && char.animation.curAnim != null && char.animation.curAnim.name.startsWith(anim)) {
			// do nothing, already playing
		} else {
			char.playAnim(anim, true);
		}
		char.holdTimer = 0;
	}

	public function danceChar(char:game.Character)
	{
		if (char == null) return;
		char.dance();
	}

	public function create(?owner:ModchartEditor):Void
	{
		if (PlayState.SONG == null) return;

		FlxG.cameras.add(previewCam);

		gameplayContainer = new FlxGroup();
		gameplayContainer.cameras = [previewCam];

		stage = new StageGroup(PlayState.SONG.stage);
		stage.cameras = [previewCam];
		gameplayContainer.add(stage);

		function addCharacter(char:game.Character):Void
		{
			if (char == null) return;
			if (char.isCharacterGroup && char.otherCharacters != null)
			{
				for (c in char.otherCharacters) addCharacter(c);
			}
			if (char.frames != null)
			{
				char.cameras = [previewCam];
				gameplayContainer.add(char);
			}
		}

		gf = new Character(400, 130, PlayState.SONG.gf != null ? PlayState.SONG.gf : "gf");
		addCharacter(gf);

		dad = new Character(100, 100, PlayState.SONG.player2);
		addCharacter(dad);

		boyfriend = new Boyfriend(770, 450, PlayState.SONG.player1);
		addCharacter(boyfriend);

		stage.setCharOffsets(boyfriend, gf, dad);

		// Load UI skin configs
		var uiSkin:String = PlayState.SONG.ui_Skin != null ? PlayState.SONG.ui_Skin : "default";
		ui_settings = [];
		mania_size = [];
		var mania_offset:Array<String> = [];
		var mania_gap:Array<String> = [];
		if (Assets.exists(Paths.txt("ui skins/" + uiSkin + "/config")))
			ui_settings = CoolUtil.coolTextFile(Paths.txt("ui skins/" + uiSkin + "/config"));
		if (Assets.exists(Paths.txt("ui skins/" + uiSkin + "/maniasize")))
			mania_size = CoolUtil.coolTextFile(Paths.txt("ui skins/" + uiSkin + "/maniasize"));
		if (Assets.exists(Paths.txt("ui skins/" + uiSkin + "/maniaoffset")))
			mania_offset = CoolUtil.coolTextFile(Paths.txt("ui skins/" + uiSkin + "/maniaoffset"));
		if (Assets.exists(Paths.txt("ui skins/" + uiSkin + "/maniagap")))
			mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/" + uiSkin + "/maniagap"));
		else
			mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniagap"));

		function safeFloat(arr:Array<String>, idx:Int, fallback:Float = 0):Float
			return (arr != null && idx >= 0 && idx < arr.length) ? Std.parseFloat(arr[idx]) : fallback;

		// Strums on camHUD
		strumLines = [];
		curScale = state.isPreviewFullscreen ? 1.0 : 0.5;
		var camY = ((-FlxG.height / 4) + 32) * (-((curScale - 0.5) * 2) + 1);
		var strumScreenY:Float = Options.getData("downscroll") == true ? FlxG.height - 100 : 100;
		var strumGameY:Float = (strumScreenY - camY) / curScale;
		var playerKeyCount:Int = (PlayState.SONG.playerKeyCount != null) ? PlayState.SONG.playerKeyCount : 4;
		var enemyKeyCount:Int = (PlayState.SONG.keyCount != null) ? PlayState.SONG.keyCount : 4;

		// Enemy strums
		var enemyLine:Array<FlxSprite> = [];
		for (i in 0...enemyKeyCount)
		{
			var babyArrow:FlxSprite = new StrumNote(0, 0, i, uiSkin, ui_settings, mania_size, enemyKeyCount, 0);
			babyArrow.scrollFactor.set();
			babyArrow.cameras = [state.camHUD];
			babyArrow.ID = i;
			babyArrow.x = (babyArrow.width + 2 + safeFloat(mania_gap, enemyKeyCount - 1)) * i
				+ safeFloat(mania_offset, enemyKeyCount - 1);
			babyArrow.x += 100 - ((enemyKeyCount - 4) * 16) + (enemyKeyCount >= 10 ? 30 : 0);
			babyArrow.y = strumGameY - (babyArrow.height / 2);
			state.add(babyArrow);
			enemyLine.push(babyArrow);
		}
		strumLines.push(enemyLine);

		// Player strums
		var playerLine:Array<FlxSprite> = [];
		for (i in 0...playerKeyCount)
		{
			var babyArrow:FlxSprite = new StrumNote(0, 0, i, uiSkin, ui_settings, mania_size, playerKeyCount, 1);
			babyArrow.scrollFactor.set();
			babyArrow.cameras = [state.camHUD];
			babyArrow.ID = i;
			babyArrow.x = (babyArrow.width + 2 + safeFloat(mania_gap, playerKeyCount - 1)) * i
				+ safeFloat(mania_offset, playerKeyCount - 1);
			babyArrow.x += 100 - ((playerKeyCount - 4) * 16) + (playerKeyCount >= 10 ? 30 : 0);
			babyArrow.x += FlxG.width / 2;
			babyArrow.y = strumGameY - (babyArrow.height / 2);
			state.add(babyArrow);
			playerLine.push(babyArrow);
		}
		strumLines.push(playerLine);

		state.add(gameplayContainer);

		// Initialize camHUD transforms so notes/strums are visible from frame 1
		var initCurScale = state.isPreviewFullscreen ? 1.0 : 0.5;
		var initCamY = ((-FlxG.height / 4) + 32) * (-((initCurScale - 0.5) * 2) + 1);
		
		previewCam.flashSprite.scaleX = previewCam.flashSprite.scaleY = initCurScale;
		if (state.camHUD != null)
		{
			state.camHUD.flashSprite.scaleX = state.camHUD.flashSprite.scaleY = initCurScale;
			state.camHUD.y = initCamY;
		}
		
		var initStrumScreenY:Float = Options.getData("downscroll") == true ? FlxG.height - 100 : 100;
		var initStrumGameY:Float = (initStrumScreenY - initCamY) / initCurScale;
		if (state.camHUD != null)
		{
			state.camHUD.scroll.y = initStrumGameY - initStrumScreenY;
		}

		// Notes
		notes = new FlxTypedGroup<EditorNote>();
		notes.cameras = [state.camHUD];
		state.add(notes);
		unspawnNotes = [];
		generateNotes();

		// Initial camera position (will be smoothed by updateCamera)
		var focusX = boyfriend.getMidpoint().x + boyfriend.cameraOffset[0];
		var focusY = boyfriend.getMidpoint().y + boyfriend.cameraOffset[1];
		previewCam.scroll.x = focusX - FlxG.width * 0.5;
		previewCam.scroll.y = focusY - FlxG.height * 0.5;
		previewCam.zoom = stage.camZoom != 0 ? stage.camZoom : 1.0;

		// Reposition strums to align correctly from startup
		repositionStrums();
	}

	function generateNotes():Void
	{
		var song = PlayState.SONG;
		if (song == null || song.notes == null) return;

		for (section in song.notes)
		{
			Conductor.recalculateStuff(1);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0] + Conductor.offset + song.chartOffset;
				var keyCount:Int = song.keyCount;
				var playerKeyCount:Int = song.playerKeyCount;
				var totalKeys:Int = keyCount + playerKeyCount;

				var rawNote:Int = Std.int(Math.abs(songNotes[1]));
				// noteData mod total keys (matching PlayState's first step)
				var noteDataMod:Int = rawNote % totalKeys;

				// resolveMustPress logic (PlayState line 1485-1497)
				var mustPress:Bool = section.mustHitSection;
				if (noteDataMod >= (mustPress ? playerKeyCount : keyCount))
					mustPress = !mustPress;

				// Adjust noteData to be within the correct side's range (PlayState lines 1561-1566)
				var editorNoteData:Int;
				if (section.mustHitSection)
					editorNoteData = noteDataMod >= playerKeyCount
						? (noteDataMod - playerKeyCount) % keyCount
						: noteDataMod;
				else
					editorNoteData = noteDataMod >= keyCount
						? (noteDataMod - keyCount) % playerKeyCount
						: noteDataMod;

				var arrowType:String = (songNotes.length > 4 && Std.isOfType(songNotes[4], String))
					? songNotes[4] : "default";

				var noteChar:Int = 0;
				var noteChars:Array<Int> = null;
				if (songNotes.length > 3 && songNotes[3] != null)
				{
					if (Std.isOfType(songNotes[3], Array))
					{
						noteChars = songNotes[3];
						noteChar = (noteChars.length > 0) ? noteChars[0] : 0;
					}
					else if (Std.isOfType(songNotes[3], Int)) noteChar = songNotes[3];
					else if (Std.isOfType(songNotes[3], Float)) noteChar = Std.int(songNotes[3]);
				}

				var localKeyCount = mustPress ? playerKeyCount : keyCount;

				var swagNote = new EditorNote(daStrumTime, editorNoteData, false, arrowType,
					mustPress, ui_settings, mania_size, localKeyCount, false, noteChar, noteChars);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set();
				swagNote.cameras = [state.camHUD];
				unspawnNotes.push(swagNote);

				// Sustain notes
				var sustainSteps:Int = Math.floor(swagNote.sustainLength / Std.int(Conductor.stepCrochet));
				for (i in 0...sustainSteps)
				{
					var isEnd:Bool = (i == sustainSteps - 1);
					var sustainNote = new EditorNote(
						daStrumTime + Conductor.stepCrochet * i
						+ (Conductor.stepCrochet / FlxMath.roundDecimal(song.speed, 2)),
						editorNoteData, true, arrowType,
						mustPress, ui_settings, mania_size, localKeyCount, isEnd, noteChar, noteChars
					);
					sustainNote.scrollFactor.set();
					sustainNote.speed = swagNote.speed;
					sustainNote.cameras = [state.camHUD];
					unspawnNotes.push(sustainNote);
				}
			}
		}

		targetCrosshair = new FlxSprite();
		targetCrosshair.makeGraphic(24, 24, FlxColor.TRANSPARENT, true);
		targetCrosshair.pixels.fillRect(new flash.geom.Rectangle(11, 0, 2, 24), FlxColor.RED);
		targetCrosshair.pixels.fillRect(new flash.geom.Rectangle(0, 11, 24, 2), FlxColor.RED);
		targetCrosshair.cameras = [previewCam];
		state.add(targetCrosshair);

		unspawnNotes.sort(function(a, b) return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime));
		loadedNotes = unspawnNotes.copy();
	}

	public function resetModifiers():Void
	{
		modZoom = 1.0;
		modAngle = 0.0;
		modPosX = 0.0;
		modPosY = 0.0;
		modFollowX = 0.0;
		modFollowY = 0.0;
		trackDad = false;
		trackBf = false;
		turnDad = 0.0;
		turnBf = 0.0;
		cameraFly = 0.0;
	}

	public function resetNotes():Void
	{
		if (notes != null) {
			notes.clear();
		}
		unspawnNotes = [];
		for (n in loadedNotes)
		{
			n.revive();
			n.wasGoodHit = false;
			n.canBeHit = false;
			n.active = true;
			n.visible = false;
			n.y = -2000;
			if (n.strumTime + n.sustainLength >= Conductor.songPosition - 100)
			{
				unspawnNotes.push(n);
			}
		}
		unspawnNotes.sort(function(a, b) return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime));
	}

	public function repositionStrums():Void
	{
		var camY = ((-FlxG.height / 4) + 32) * (-((curScale - 0.5) * 2) + 1);
		var strumScreenY:Float = Options.getData("downscroll") == true ? FlxG.height - 100 : 100;
		var centerY = FlxG.height / 2;
		var strumGameY:Float = centerY + (strumScreenY - camY - centerY) / curScale;
		for (line in strumLines)
			for (s in line)
			{
				s.y = strumGameY - (s.height / 2);
				// Do not overwrite local key-count scale
			}
	}

	function playAnimOnNote(parentChar:game.Character, note:EditorNote, singAnim:String, force:Bool = true):Void
	{
		if (!parentChar.isCharacterGroup)
		{
			parentChar.playAnim(singAnim, force);
			return;
		}

		var chars:Array<Int> = note.characters;
		var charID:Int = note.character;

		if (chars == null || chars.length <= 1)
		{
			if (parentChar.otherCharacters != null && charID < parentChar.otherCharacters.length)
			{
				var c = parentChar.otherCharacters[charID];
				if (c != null)
				{
					parentChar.activeCharacterID = charID;
					c.playAnim(singAnim, force);
				}
			}
		}
		else
		{
			for (i in chars)
			{
				if (parentChar.otherCharacters != null && i < parentChar.otherCharacters.length)
				{
					var c = parentChar.otherCharacters[i];
					if (c != null)
					{
						parentChar.activeCharacterID = i;
						c.playAnim(singAnim, force);
					}
				}
			}
		}
	}

	public function update(elapsed:Float):Void
	{
		if (firstFrame)
		{
			firstFrame = false;
			repositionStrums();
		}

		if (stage != null) stage.update(elapsed);

		// Reset notes if song is seeked backward, but not while dragging the scrollbar (avoiding lag)
		var songPos:Float = Conductor.songPosition;
		var isDraggingScrollbar = (state.durationScrollbar != null && state.durationScrollbar.isDragging);
		if (songPos < lastSongPos && !isDraggingScrollbar)
		{
			resetNotes();
		}
		if (lastWasDragging && !isDraggingScrollbar)
		{
			resetNotes();
		}
		lastWasDragging = isDraggingScrollbar;
		lastSongPos = songPos;

		// CNE-style flashSprite scaling
		var targetScale = state.isPreviewFullscreen ? 1.0 : 0.5;
		curScale += (targetScale - curScale) * 0.15;
		if (Math.abs(targetScale - curScale) < 0.01) curScale = targetScale;
		
		previewCam.flashSprite.scaleX = previewCam.flashSprite.scaleY = curScale;
		if (state.camHUD != null)
		{
			state.camHUD.flashSprite.scaleX = state.camHUD.flashSprite.scaleY = curScale;
		}

		// CNE-style Y-offset
		var camY = ((-FlxG.height / 4) + 32) * (-((curScale - 0.5) * 2) + 1);
		previewCam.y = camY;
		if (state.camHUD != null)
		{
			state.camHUD.y = camY;
			var strumScreenY:Float = Options.getData("downscroll") == true ? FlxG.height - 100 : 100;
			var centerY = FlxG.height / 2;
			var strumGameY:Float = centerY + (strumScreenY - camY - centerY) / curScale;
			state.camHUD.scroll.y = strumGameY - strumScreenY;
		}

		// Camera follow
		updateCamera(elapsed);

		if (targetCrosshair != null)
		{
			targetCrosshair.x = previewCam.scroll.x + previewCam.width / 2 - targetCrosshair.width / 2;
			targetCrosshair.y = previewCam.scroll.y + previewCam.height / 2 - targetCrosshair.height / 2;
		}

		repositionStrums();

		// Notes
		updateNotes();
	}

	function getCamTarget(char:Dynamic):Dynamic {
		var camChar:Dynamic = null;
		try { camChar = char.getCameraCharacter(); } catch(e:Dynamic) {}
		return (camChar != null) ? camChar : char;
	}

	function updateCamera(elapsed:Float):Void
	{
		var targetX:Float, targetY:Float;

		var dadTarget = getCamTarget(dad);
		var bfTarget = getCamTarget(boyfriend);

		var dadMid = dadTarget.getMidpoint();
		var bfMid = bfTarget.getMidpoint();

		var dadTargetX = dadMid.x + 150 + dadTarget.cameraOffset[0] + stage.p2_Cam_Offset.x;
		var dadTargetY = dadMid.y - 100 + dadTarget.cameraOffset[1] + stage.p2_Cam_Offset.y;

		var bfTargetX = bfMid.x - 100 + stage.p1_Cam_Offset.x + bfTarget.cameraOffset[0];
		var bfTargetY = bfMid.y - 100 + stage.p1_Cam_Offset.y + bfTarget.cameraOffset[1];

		var centerTargetX = (dadTargetX + bfTargetX) * 0.5;
		var centerTargetY = (dadTargetY + bfTargetY) * 0.5;

		if (turnDad > 0.5) {
			targetX = dadTargetX;
			targetY = dadTargetY;
		} else if (turnBf > 0.5) {
			targetX = bfTargetX;
			targetY = bfTargetY;
		} else if (centerCamera) {
			targetX = centerTargetX;
			targetY = centerTargetY;
		} else {
			targetX = bfTargetX;
			targetY = bfTargetY;
		}

		var targetSingOffsetX = 0.0;
		var targetSingOffsetY = 0.0;
		var singOffset = 50.0;
		function applyTracking(char:Dynamic):Void
		{
			var trackChar = getCamTarget(char);
			var animName = '';
			try { animName = trackChar.curAnimName().toLowerCase(); } catch(e:Dynamic) {
				try { animName = trackChar.animation.curAnim.name.toLowerCase(); } catch(e2:Dynamic) {}
			}
			trace("PreviewCamera TrackSing -> Detected Anim: '" + animName + "'");
			if (animName.indexOf('singleft') != -1) targetSingOffsetX -= singOffset;
			else if (animName.indexOf('singright') != -1) targetSingOffsetX += singOffset;
			else if (animName.indexOf('singup') != -1) targetSingOffsetY -= singOffset;
			else if (animName.indexOf('singdown') != -1) targetSingOffsetY += singOffset;
		}
		if (trackDad) {
			trace("PreviewCamera -> trackDad is true! Applying tracking...");
			applyTracking(dad);
		}
		if (trackBf) {
			trace("PreviewCamera -> trackBf is true! Applying tracking...");
			applyTracking(boyfriend);
		}

		if (cameraFly > 0) {
			var time = Conductor.songPosition / 1000.0;
			targetX += Math.sin(time * 2) * 50 * cameraFly;
			targetY += Math.sin(time * 4) * 25 * cameraFly;
		}

		targetX += modPosX + modFollowX;
		targetY += modPosY + modFollowY;

		var targetZoom = (stage != null ? stage.camZoom : 1.0) * modZoom;
		if (hasTween) {
			previewCam.zoom = targetZoom;
		} else {
			var lerpVal:Float = lerpSpeed * FlxG.elapsed * 60;
			if (lerpVal > 1) lerpVal = 1;
			previewCam.zoom = FlxMath.lerp(previewCam.zoom, targetZoom, lerpVal);
		}
		
		var singLerpVal = 0.15 * (FlxG.elapsed / (1 / 60));
		if (singLerpVal > 1) singLerpVal = 1;
		currentSingOffsetX = FlxMath.lerp(currentSingOffsetX, targetSingOffsetX, singLerpVal);
		currentSingOffsetY = FlxMath.lerp(currentSingOffsetY, targetSingOffsetY, singLerpVal);
		
		var finalTargetX = (targetX - FlxG.width * 0.5) + currentSingOffsetX;
		var finalTargetY = (targetY - FlxG.height * 0.5) + currentSingOffsetY;

		if (hasTween) {
			previewCam.scroll.x = finalTargetX;
			previewCam.scroll.y = finalTargetY;
		} else {
			var lerpVal:Float = lerpSpeed * FlxG.elapsed * 60;
			if (lerpVal > 1) lerpVal = 1;
			previewCam.scroll.x = FlxMath.lerp(previewCam.scroll.x, finalTargetX, lerpVal);
			previewCam.scroll.y = FlxMath.lerp(previewCam.scroll.y, finalTargetY, lerpVal);
		}

		previewCam.angle = modAngle;

		dadMid.put();
		bfMid.put();
	}

	function updateNotes():Void
	{
		if (notes == null || unspawnNotes == null) return;

		var songPos:Float = Conductor.songPosition;

		// Spool notes from unspawnNotes to active group
		while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - songPos < 1500)
		{
			var note = unspawnNotes.shift();
			notes.add(note);
		}

		notes.forEachAlive(function(note:EditorNote)
		{
			var enemyStrumLen = strumLines[0].length;
			var playerStrumLen = strumLines.length > 1 ? strumLines[1].length : 0;

			var coolStrum:StrumNote;
			if (!note.mustPress)
				coolStrum = cast strumLines[0][Std.int(Math.abs(note.noteData)) % enemyStrumLen];
			else
				coolStrum = cast strumLines[1][Std.int(Math.abs(note.noteData)) % playerStrumLen];

			if (coolStrum == null) return;

			note.visible = true;
			note.active = true;
			note.calculateY(coolStrum);

			// Align X to strum center (PlayState-style) - Optimized O(1)
			note.x = coolStrum.x + (coolStrum.width / 2) - (note.width / 2);

			note.calculateCanBeHit();

			// Auto-hit: mustPress determines parent character (PlayState logic)
			if (songPos >= note.strumTime && !note.wasGoodHit)
			{
				var parentChar = note.mustPress ? boyfriend : dad;
				var keyCount = note.mustPress
					? ((PlayState.SONG.playerKeyCount != null) ? PlayState.SONG.playerKeyCount : 4)
					: ((PlayState.SONG.keyCount != null) ? PlayState.SONG.keyCount : 4);
				var animIndex = Std.int(Math.abs(note.noteData)) % keyCount;
				var singAnim:String = NoteVariables.characterAnimations[keyCount - 1][animIndex];

				playAnimOnNote(parentChar, note, singAnim);

				var strumLine = note.mustPress ? 1 : 0;
				var strumLen = note.mustPress ? playerStrumLen : enemyStrumLen;
				var spr = cast(strumLines[strumLine][Std.int(Math.abs(note.noteData)) % strumLen], StrumNote);
				if (spr != null)
				{
					spr.playAnim('confirm', true);
					spr.resetAnim = 0.2;
				}

				note.wasGoodHit = true;
			}

			// Kill/remove notes that have been hit and passed the strumline (safely using note.kill() to avoid group mutation crash)
			var killTime = note.strumTime + (note.isSustainNote ? Conductor.stepCrochet : 0);
			if (songPos >= killTime)
			{
				note.kill();
				return;
			}

			// Player notes: mirror strum visual state
			if (note.mustPress)
			{
				var spr = cast(strumLines[1][Std.int(Math.abs(note.noteData)) % playerStrumLen], StrumNote);
				if (spr != null)
				{
					note.visible = spr.visible;
					if (spr.alpha != 1)
						note.alpha = note.isSustainNote ? 0.6 * spr.alpha : spr.alpha;
					if (!note.isSustainNote)
						note.modAngle = spr.angle;
					note.flipX = spr.flipX;
					if (!note.isSustainNote)
						note.flipY = spr.flipY;
					note.color = spr.color;
				}
			}
		});
	}

	public function beatHit():Void
	{
		if (stage != null) stage.beatHit();
		danceChar(dad);
		danceChar(boyfriend);
		danceChar(gf);
	}
	public function destroy():Void
	{
		if (gameplayContainer != null) gameplayContainer.destroy();
		if (notes != null) { notes.clear(); notes.destroy(); }
		if (unspawnNotes != null) { unspawnNotes = null; }
		if (loadedNotes != null) { for (n in loadedNotes) n.destroy(); loadedNotes = null; }
	}
}
