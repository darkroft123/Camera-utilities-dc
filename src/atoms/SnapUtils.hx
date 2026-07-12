package atoms;

class SnapUtils
{
	public static function stepSnapSize(beatSnap:Int):Float
	{
		var snap = 1.0 / (beatSnap / 4.0);
		return snap < 0.05 ? 0.25 : snap;
	}

	public static function snapValue(value:Float, beatSnap:Int):Float
	{
		var snap = stepSnapSize(beatSnap);
		return Math.round(value / snap) * snap;
	}

	public static function snapSteps(rawStep:Float, beatSnap:Int):Float
	{
		return Math.round(rawStep / beatSnap) * beatSnap;
	}
}
