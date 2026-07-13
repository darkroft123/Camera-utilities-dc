package camera.utilities;



/**
 * Helper class with lots of utilitiy functions.
 */

class CameraUtilities {
	

	public static function timeToStr(ms:Float):String{
				if (ms < 0) ms = 0;

				var totalSeconds:Int = Std.int(ms / 1000);
				var minutes:Int = Std.int(totalSeconds / 60);
				var seconds:Int = totalSeconds % 60;

				return minutes + ":" + (seconds < 10 ? "0" + seconds : Std.string(seconds));
			}

}