package;

import flixel.FlxG;

class CameraUtils {

    public static function shake(power:Float = 5, duration:Float = 0.2):Void {
        FlxG.camera.shake(power, duration);
    }

    public static function zoom(value:Float = 1.2):Void {
        FlxG.camera.zoom = value;
    }

    public static function resetZoom():Void {
        FlxG.camera.zoom = 1;
    }

    public static function followLerp(x:Float, y:Float, speed:Float = 0.1):Void {
        FlxG.camera.scroll.x += (x - FlxG.camera.scroll.x) * speed;
        FlxG.camera.scroll.y += (y - FlxG.camera.scroll.y) * speed;
    }
}