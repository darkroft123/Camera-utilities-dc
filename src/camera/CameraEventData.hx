package camera;

class CameraEventData
{
	public var camZoom:Float = 1.0;
	public var cameraBump:Float = 0.0;
	public var cameraBumpX:Float = 0.0;
	public var cameraBumpY:Float = 0.0;
	public var cameraBumpAngle:Float = 0.0;
	public var camAngle:Float = 0.0;
	public var camPosX:Float = 0.0;
	public var camPosY:Float = 0.0;
	public var turnDad:Float = 0.0;
	public var turnBf:Float = 0.0;
	public var camCenter:Float = 0.0;
	public var trackDad:Float = 0.0;
	public var trackBf:Float = 0.0;
	public var cameraFly:Float = 0.0;

	public var targetX:Float = 0.0;
	public var targetY:Float = 0.0;
	public var singOffsetX:Float = 0.0;
	public var singOffsetY:Float = 0.0;

	public var hasTween:Bool = false;
	public var hasPosTween:Bool = false;
	public var hasZoomTween:Bool = false;

	public function new() {}
}
