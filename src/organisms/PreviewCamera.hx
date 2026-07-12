package organisms;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

import game.Boyfriend;
import game.Character;
import game.StageGroup;
import game.Note;
import game.StrumNote;
import game.NoteSplash;
import game.Conductor;
import utilities.NoteVariables;
import utilities.Options;
import pages.ModchartEditor;
import states.PlayState;
import templates.EditorLayout;

using StringTools;

class PreviewCamera
{
	public var gameplayContainer:FlxGroup;
	public var stage:StageGroup;
	public var dad:Character;
	public var boyfriend:Boyfriend;
	public var gf:Character;

	// modifier accumulators (camGame only)
	public var modZoom:Float = 1.0;
	public var modAngle:Float = 0.0;
	public var modPosX:Float = 0.0;
	public var modPosY:Float = 0.0;
	public var modFollowX:Float = 0.0;
	public var modFollowY:Float = 0.0;

	// HUD camera (strumNotes + notes, never affected by modifiers)
	public var camHUD:FlxCamera;
	public var hudContainer:FlxGroup;

	// strum & note groups
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var enemyStrums:FlxTypedGroup<StrumNote>;
	public var notesGroup:FlxTypedGroup<Note>;
	public var splashGroup:FlxTypedGroup<NoteSplash>;

	var unspawnNotes:Array<Note> = [];

	// shared positioning (single source of truth)
	var laneWidth:Float = Note.swagWidth;
	var laneSpacing:Float = 4;
	var strumLineY:Float;

	var previewCam:FlxCamera;
	var state:ModchartEditor;

	// like CNE's camScale
	var normalScale:Float;
	var initialScrollX:Float = 0;
	var initialScrollY:Float = 0;

	var isDraggingStage:Bool = false;
	var stagePanLastMouse:FlxPoint = null;

	public function new(state:ModchartEditor)
	{
		this.state = state;
		this.previewCam = FlxG.camera;
	}

	public function create(owner:ModchartEditor):Void
	{
		if (PlayState.SONG == null) return;

		normalScale = EditorLayout.previewScale;

		// --- camGame layer ---
		gameplayContainer = new FlxGroup();
		gameplayContainer.cameras = [previewCam];

		stage = new StageGroup(PlayState.SONG.stage);
		stage.cameras = [previewCam];
		gameplayContainer.add(stage);

		gf = new Character(400, 130, PlayState.SONG.gf != null ? PlayState.SONG.gf : "gf");
		addCharacterToContainer(gf);

		dad = new Character(100, 100, PlayState.SONG.player2);
		addCharacterToContainer(dad);

		boyfriend = new Boyfriend(770, 450, PlayState.SONG.player1);
		addCharacterToContainer(boyfriend);

		stage.setCharOffsets(boyfriend, gf, dad);

		dad.cameraOffset[0] += stage.p2_Cam_Offset.x;
		dad.cameraOffset[1] += stage.p2_Cam_Offset.y;

		boyfriend.cameraOffset[0] += stage.p1_Cam_Offset.x;
		boyfriend.cameraOffset[1] += stage.p1_Cam_Offset.y;

		owner.add(gameplayContainer);

		// --- init camera like CNE: one-time focus on boyfriend ---
		var focusX = boyfriend.getMidpoint().x + boyfriend.cameraOffset[0];
		var focusY = boyfriend.getMidpoint().y + boyfriend.cameraOffset[1];
		previewCam.focusOn(FlxPoint.get(focusX, focusY));
		previewCam.zoom = calcBaseZoom();
		previewCam.angle = 0;
		initialScrollX = previewCam.scroll.x;
		initialScrollY = previewCam.scroll.y;

		// --- apply initial CNE-style scale & position ---
		applyCamScale(normalScale);

		// --- camHUD layer ---
		camHUD = new FlxCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.list.remove(camHUD);
		var editorIndex = FlxG.cameras.list.indexOf(owner.camEditor);
		if (editorIndex != -1)
			FlxG.cameras.list.insert(editorIndex, camHUD);
		else
			FlxG.cameras.list.push(camHUD);

		applyCamScaleTo(camHUD, normalScale);

		hudContainer = new FlxGroup();
		hudContainer.cameras = [camHUD];
		owner.add(hudContainer);

		var downVal:Dynamic = Options.getData("downscroll");
		var isDownscroll = downVal == true;
		if (!isDownscroll && Std.is(downVal, String)) isDownscroll = downVal == "true";
		strumLineY = isDownscroll ? FlxG.height - 100 : 50;
		setupStrumNotes();
		generateNotes();

		hideNullFrameSprites();
	}

	function hideNullFrameSprites():Void
	{
		function recurse(group:FlxGroup)
		{
			for (member in group.members)
			{
				if (member == null) continue;
				if (Std.isOfType(member, FlxGroup))
					recurse(cast member);
				else if (Std.isOfType(member, flixel.FlxSprite) && cast(member, flixel.FlxSprite).frames == null)
					cast(member, flixel.FlxSprite).visible = false;
			}
		}
		recurse(gameplayContainer);
		recurse(hudContainer);
	}

	function applyCamScale(scale:Float):Void
	{
		previewCam.flashSprite.scaleX = previewCam.flashSprite.scaleY = scale;
		previewCam.y = (-180 + 32) * (-((scale - 0.5) * 2) + 1);
		previewCam.x = (FlxG.width - Std.int(FlxG.width * scale)) * 0.5;
	}

	function applyCamScaleTo(cam:FlxCamera, scale:Float):Void
	{
		cam.flashSprite.scaleX = cam.flashSprite.scaleY = scale;
		cam.y = (-180 + 32) * (-((scale - 0.5) * 2) + 1);
		cam.x = (FlxG.width - Std.int(FlxG.width * scale)) * 0.5;
	}

	function addCharacterToContainer(char:Character):Void
	{
		if (char == null) return;

		char.cameras = [previewCam];
		if (char.frames == null) char.visible = false;
		gameplayContainer.add(char);

		if (char.otherCharacters != null)
		{
			for (c in char.otherCharacters)
			{
				if (c == null) continue;
				c.cameras = [previewCam];
				if (c.frames == null) c.visible = false;
				gameplayContainer.add(c);
			}
		}
	}

	function setupStrumNotes():Void
	{
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		enemyStrums = new FlxTypedGroup<StrumNote>();

		generateStaticArrows(false);
		generateStaticArrows(true);

		hudContainer.add(strumLineNotes);
	}

	function generateStaticArrows(?isPlayer:Bool = false):Void
	{
		var usedKeyCount:Int = isPlayer ? PlayState.SONG.playerKeyCount : PlayState.SONG.keyCount;
		var strOffset:Float = isPlayer ? 0.75 : 0.25;
		var totalLaneWidth = usedKeyCount * laneWidth + (usedKeyCount - 1) * laneSpacing;
		var startX = (FlxG.width * strOffset) - totalLaneWidth / 2;

		for (i in 0...usedKeyCount)
		{
			var babyArrow = new StrumNote(0, 0, i);
			babyArrow.scrollFactor.set();
			babyArrow.ID = i;
			babyArrow.x = startX + i * (laneWidth + laneSpacing);
			babyArrow.y = strumLineY;

			if (babyArrow.frames == null) babyArrow.visible = false;

			if (strumLineNotes.members.length == 0 && babyArrow.swagWidth > 0)
				laneWidth = babyArrow.swagWidth;

			if (isPlayer)
				playerStrums.add(babyArrow);
			else
				enemyStrums.add(babyArrow);

			strumLineNotes.add(babyArrow);
		}
	}

	function generateNotes():Void
	{
		notesGroup = new FlxTypedGroup<Note>();
		splashGroup = new FlxTypedGroup<NoteSplash>();

		var song = PlayState.SONG;
		var songNotes = song.notes;

		for (section in songNotes)
		{
			var secNotes = section.sectionNotes;
			if (secNotes == null) continue;

			for (rawNote in secNotes)
			{
				var strumTime:Float = rawNote[0];
				var noteData:Int = Std.int(rawNote[1]);
				var sustainLength:Float = (rawNote[2] != null) ? rawNote[2] : 0;
				var charIndex:Int = (rawNote[3] != null && Std.isOfType(rawNote[3], Int)) ? rawNote[3] : 0;
				var arrowType:String = (rawNote[4] != null && Std.isOfType(rawNote[4], String)) ? rawNote[4] : "default";

				var mustPress:Bool = section.mustHitSection;
				if (charIndex == 1) mustPress = false;
				else if (charIndex == 2) mustPress = true;

				if (mustPress && noteData >= song.playerKeyCount)
					noteData = (noteData - song.playerKeyCount) % song.keyCount;
				else if (!mustPress && noteData >= song.keyCount)
				{
					var playerKC = song.playerKeyCount;
					noteData = (noteData - song.keyCount) % (playerKC > 0 ? playerKC : song.keyCount);
				}

				var oldNote:Note = (unspawnNotes.length > 0) ? unspawnNotes[unspawnNotes.length - 1] : null;

				var swagNote = new Note(strumTime, noteData, oldNote, false, charIndex, arrowType, song, null, mustPress, false);
				swagNote.scrollFactor.set();
				swagNote.sustainLength = sustainLength;
				swagNote.mustPress = mustPress;
				unspawnNotes.push(swagNote);

				var sustainGroup:Array<Note> = [];

				for (j in 0...Math.floor(sustainLength / Std.int(Conductor.stepCrochet)))
				{
					oldNote = unspawnNotes[unspawnNotes.length - 1];

					var sustainNote = new Note(
						strumTime + (Conductor.stepCrochet * j) + (Conductor.stepCrochet / 1),
						noteData,
						oldNote,
						true,
						charIndex,
						arrowType,
						song,
						null,
						mustPress,
						false
					);
					sustainNote.scrollFactor.set();
					sustainNote.sustainLength = sustainLength;
					sustainNote.mustPress = mustPress;
					unspawnNotes.push(sustainNote);
					sustainGroup.push(sustainNote);
				}

				swagNote.sustains = sustainGroup;
			}
		}

		unspawnNotes.sort(function(a, b) return Std.int(a.strumTime - b.strumTime));
		hudContainer.add(notesGroup);
		hudContainer.add(splashGroup);
	}

	public function resetModifiers():Void
	{
		modZoom = 1.0;
		modAngle = 0.0;
		modPosX = 0.0;
		modPosY = 0.0;
		modFollowX = 0.0;
		modFollowY = 0.0;
	}

	public function update(elapsed:Float):Void
	{
		if (stage != null) stage.update(elapsed);

		// --- CNE-style updateUI: lerp flashSprite.scale ---
		var targetScale = state.isPreviewFullscreen ? 1.0 : normalScale;
		var curScale = previewCam.flashSprite.scaleX;
		curScale += (targetScale - curScale) * 0.15;
		if (Math.abs(targetScale - curScale) < 0.01) curScale = targetScale;
		applyCamScale(curScale);
		applyCamScaleTo(camHUD, curScale);

		// --- apply modifiers directly (like CNE: no follow system) ---
		previewCam.zoom = calcBaseZoom() * modZoom;
		previewCam.angle = modAngle;

		// Stage dragging / panning (CNE-style)
		var wantsPan = FlxG.mouse.pressedRight || (FlxG.mouse.pressed && FlxG.keys.pressed.ALT);
		if (wantsPan && !state.isPreviewFullscreen)
		{
			var mouse = FlxG.mouse.getScreenPosition();
			if (!isDraggingStage)
			{
				isDraggingStage = true;
				if (stagePanLastMouse == null) stagePanLastMouse = FlxPoint.get();
				stagePanLastMouse.set(mouse.x, mouse.y);
			}
			else
			{
				var zoom = previewCam.zoom;
				if (zoom <= 0) zoom = 0.001;

				var dx = mouse.x - stagePanLastMouse.x;
				var dy = mouse.y - stagePanLastMouse.y;

				initialScrollX -= dx / zoom;
				initialScrollY -= dy / zoom;

				stagePanLastMouse.set(mouse.x, mouse.y);
			}
		}
		else
		{
			isDraggingStage = false;
			if (stagePanLastMouse != null)
			{
				stagePanLastMouse.put();
				stagePanLastMouse = null;
			}
		}

		// modPos and modFollow offset the camera scroll directly (CNE-style: properties set directly)
		previewCam.scroll.x = initialScrollX + modPosX + modFollowX;
		previewCam.scroll.y = initialScrollY + modPosY + modFollowY;

		updateVocalsVolume(elapsed);

		// --- splash cleanup ---
		splashGroup.forEachAlive(function(splash:NoteSplash) {
			if (splash.animation != null && splash.animation.finished)
				splash.kill();
		});

		// --- note spawning ---
		var songPos = Conductor.songPosition;
		while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - songPos < 1500.0)
		{
			var note = unspawnNotes[0];
			if (note.frames == null) note.visible = false;
			notesGroup.add(note);
			unspawnNotes.splice(0, 1);
		}

		// --- note cleanup ---
		var i = notesGroup.members.length;
		while (i-- > 0)
		{
			var note = notesGroup.members[i];
			if (note != null && note.strumTime + 2000 < songPos)
			{
				note.kill();
				note.destroy();
				notesGroup.remove(note);
			}
		}

		// --- note update & auto-singing ---
		if (notesGroup != null && playerStrums.members.length > 0 && enemyStrums.members.length > 0)
		{
			notesGroup.forEachAlive(function(note:Note)
			{
				if (note.frames == null) return;

				var coolStrum:StrumNote = (note.mustPress
					? playerStrums.members[Math.floor(Math.abs(note.noteData)) % playerStrums.members.length]
					: enemyStrums.members[Math.floor(Math.abs(note.noteData)) % enemyStrums.members.length]);
				if (coolStrum == null || coolStrum.frames == null) return;

				note.visible = true;
				note.active = true;
				note.scale.set(coolStrum.scale.x, coolStrum.scale.y);
				note.calculateY(coolStrum);

				if (note.isSustainNote)
				{
					var swagRect = new flixel.math.FlxRect(0, 0, note.frameWidth, note.frameHeight);
					swagRect.y = (coolStrum.y + (coolStrum.height / 2) - note.y) / note.scale.y;
					swagRect.height -= swagRect.y;
					note.clipRect = swagRect;
				}

				note.calculateCanBeHit();
				if (note.canBeHit && !note.wasGoodHit)
				{
					triggerCharacterSing(note);

					if (!note.isSustainNote)
					{
						var strumIndex = Math.floor(Math.abs(note.noteData));
						if (note.mustPress)
							playerStrums.members[strumIndex % playerStrums.members.length]?.playAnim('confirm', true);
						else
							enemyStrums.members[strumIndex % enemyStrums.members.length]?.playAnim('confirm', true);
					}

					note.wasGoodHit = true;
					if (note.isSustainNote) note.shouldHit = false;
				}

				if (coolStrum != null)
				{
					note.x = coolStrum.x;
					note.visible = coolStrum.visible;
				}

				if (note.tooLate && note.alpha > 0.3) note.alpha = 0.3;
			});
		}
	}

	function triggerCharacterSing(note:Note):Void
	{
		var singAnim:String = NoteVariables.characterAnimations[PlayState.SONG.keyCount - 1][Std.int(Math.abs(note.noteData))]
			+ note.singAnimSuffix;

		if (note.singAnimPrefix != 'sing')
			singAnim = singAnim.replace('sing', note.singAnimPrefix);

		if (note.character == 2)
		{
			if (gf != null) { gf.playAnim(singAnim, true); gf.holdTimer = 0; }
		}
		else if (note.mustPress)
		{
			boyfriend?.playAnim(singAnim, true);
			if (boyfriend != null) boyfriend.holdTimer = 0;
		}
		else
		{
			dad?.playAnim(singAnim, true);
			if (dad != null) dad.holdTimer = 0;
		}

		if (!note.isSustainNote)
		{
			if (note.character == 2)
				noteSplash(note);
			else if (note.mustPress)
				noteSplash(note);
		}

		vocalsVolume();
	}

	function noteSplash(note:Note):Void
	{
		var strum = playerStrums.members[Math.floor(Math.abs(note.noteData)) % playerStrums.members.length];
		if (strum == null) return;

		var splash = splashGroup.recycle(NoteSplash);
		splash.setup_splash(strum.ID, strum, note.mustPress);
		if (splash.frames == null) { splash.kill(); return; }
	}

	var vocalsVolumeTimer:Float = 0;

	function vocalsVolume():Void
	{
		if (state?.vocals != null) state.vocals.volume = 1;
		vocalsVolumeTimer = 0.2;
	}

	function updateVocalsVolume(elapsed:Float):Void
	{
		if (vocalsVolumeTimer > 0)
		{
			vocalsVolumeTimer -= elapsed;
			if (vocalsVolumeTimer <= 0 && state?.vocals != null)
				state.vocals.volume = 0;
		}
	}

	function calcBaseZoom():Float
	{
		if (stage == null) return 1.0;
		return stage.camZoom;
	}

	public function beatHit():Void
	{
		if (stage != null) stage.beatHit();

		function resetStrumAnim(spr:StrumNote):Void
		{
			if (spr != null && spr.animation.curAnim != null && spr.animation.curAnim.name == "confirm")
				spr.playAnim("static");
		}

		if (playerStrums != null) playerStrums.forEach(resetStrumAnim);
		if (enemyStrums != null) enemyStrums.forEach(resetStrumAnim);
	}

	public function syncViewport():Void
	{
		if (camHUD == null) return;
		var curScale = previewCam.flashSprite.scaleX;
		applyCamScale(curScale);
		applyCamScaleTo(camHUD, curScale);
	}

	public function resetNotes():Void
	{
		for (note in notesGroup.members)
		{
			if (note != null) { note.kill(); note.destroy(); }
		}
		notesGroup.clear();
		unspawnNotes = [];

		for (splash in splashGroup.members)
		{
			if (splash != null) { splash.kill(); splash.destroy(); }
		}
		splashGroup.clear();

		generateNotes();
	}

	public function songEnd():Void
	{
		if (notesGroup != null)
		{
			notesGroup.forEachAlive(function(note:Note) {
				note.kill();
				note.destroy();
			});
			notesGroup.clear();
		}
		unspawnNotes = [];

		if (splashGroup != null)
		{
			splashGroup.forEachAlive(function(splash:NoteSplash) {
				splash.kill();
				splash.destroy();
			});
			splashGroup.clear();
		}
	}

	public function destroy():Void
	{
		if (camHUD != null)
		{
			FlxG.cameras.remove(camHUD);
			camHUD.destroy();
			camHUD = null;
		}

		if (hudContainer != null)
		{
			hudContainer.destroy();
			hudContainer = null;
		}
	}
}
