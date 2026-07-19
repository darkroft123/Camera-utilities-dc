package components;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;

import game.Boyfriend;
import game.Character;
import game.StageGroup;
import camera.ModchartFX;
import states.PlayState;

class EditorPreviewCameraComponent
{
	public var state:ModchartFX;
	public var previewCam:FlxCamera;

	public var stage:StageGroup;
	public var dad:Character;
	public var boyfriend:Boyfriend;
	public var gf:Character;

	public var camFollow:FlxObject;

	public function new(state:ModchartFX, previewCam:FlxCamera)
	{
		this.state = state;
		this.previewCam = previewCam;
	}

	public function create(owner:ModchartFX):Void
	{
		if (PlayState.SONG == null)
			return;

		createStageAndCharacters(owner);
		setupCamera();
		updateCameraZoom();
	}

	public function update(elapsed:Float):Void
	{
		if (stage != null)
		{
			stage.update(elapsed);
			updateCameraZoom();
		}
	}

	public function beatHit():Void
	{
		if (stage != null)
			stage.beatHit();
	}

	public function destroy():Void {}

	function updateCameraZoom():Void
	{
		if (stage == null)
			return;

		// Compensar tamaño del preview
		var ratioX:Float = previewCam.width / FlxG.width;
		var ratioY:Float = previewCam.height / FlxG.height;
		var ratio:Float = Math.min(ratioX, ratioY);

		previewCam.zoom = stage.camZoom * ratio;
	}

	function createStageAndCharacters(owner:ModchartFX):Void
	{
		stage = new StageGroup(PlayState.SONG.stage);
		stage.cameras = [previewCam];

		gf = new Character(
			400,
			130,
			PlayState.SONG.gf != null ? PlayState.SONG.gf : "gf"
		);
		gf.cameras = [previewCam];

		dad = new Character(
			100,
			100,
			PlayState.SONG.player2
		);
		dad.cameras = [previewCam];

		boyfriend = new Boyfriend(
			770,
			450,
			PlayState.SONG.player1
		);
		boyfriend.cameras = [previewCam];

		owner.add(stage);

		addCharacter(owner, gf);
		addCharacter(owner, dad);
		addCharacter(owner, boyfriend);

		stage.setCharOffsets(boyfriend, gf, dad);
	}

	function addCharacter(owner:ModchartFX, char:Character):Void
	{
		if (char == null)
			return;

		if (char.otherCharacters == null)
		{
			char.cameras = [previewCam];
			owner.add(char);
		}
		else
		{
			for (c in char.otherCharacters)
			{
				if (c != null)
				{
					c.cameras = [previewCam];
					owner.add(c);
				}
			}
		}
	}

	function setupCamera():Void
	{
		if (dad == null)
			return;

		var camX:Float = dad.getMidpoint().x + 150 + dad.cameraOffset[0] + stage.p2_Cam_Offset.x;
		var camY:Float = dad.getMidpoint().y - 100 + dad.cameraOffset[1] + stage.p2_Cam_Offset.y;

		camFollow = new FlxObject(camX, camY, 1, 1);

		previewCam.follow(
			camFollow,
			LOCKON,
			0.04 * (60 / Main.display.framerate)
		);

		previewCam.focusOn(new FlxPoint(camX, camY));
	}
}