package components;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import camera.ModchartFX;

class SongBackgroundComponent
{
	var state:ModchartFX;

	public function new(state:ModchartFX)
	{
		this.state = state;

		state.cubogris = new FlxSprite(0, 720-330).makeGraphic(1285, 320, FlxColor.GRAY);
		state.cubogris.screenCenter(X);
		state.cubogris.scrollFactor.set(0,0);
		state.add(state.cubogris);

		state.cubonegro = new FlxSprite(0, 720-320).makeGraphic(1285, 320, FlxColor.BLACK);
		state.cubonegro.screenCenter(X);
		state.cubonegro.scrollFactor.set(0,0);
		state.add(state.cubonegro);

		state.lineablanca = new FlxSprite(0, 720-280).makeGraphic(1285, 10, FlxColor.WHITE);
		state.lineablanca.screenCenter(X);
		state.lineablanca.scrollFactor.set(0,0);
		state.add(state.lineablanca);
	}
}
