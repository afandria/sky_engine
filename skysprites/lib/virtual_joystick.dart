part of skysprites;

class VirtualJoystick extends NodeWithSize {
  VirtualJoystick() : super(new Size(160.0, 160.0)) {
    userInteractionEnabled = true;
    handleMultiplePointers = false;
    position = new Point(160.0, -20.0);
    pivot = new Point(0.5, 1.0);
    _center = new Point(size.width / 2.0, size.height / 2.0);
    _handlePos = _center;

    _paintHandle = new Paint()
      ..color=new Color(0xffffffff);
    _paintControl = new Paint()
      ..color=new Color(0xffffffff)
      ..strokeWidth = 1.0
      ..setStyle(PaintingStyle.stroke);
  }

  Point _value = Point.origin;
  Point get value => _value;

  bool _isDown = false;
  bool get isDown => _isDown;

  Point _pointerDownAt;
  Point _center;
  Point _handlePos;

  Paint _paintHandle;
  Paint _paintControl;

  bool handleEvent(SpriteBoxEvent event) {
    if (event.type == "pointerdown") {
      _pointerDownAt = event.boxPosition;
      actions.stopAll();
      _isDown = true;
    }
    else if (event.type == "pointerup" || event.type == "pointercancel") {
      _pointerDownAt = null;
      _value = Point.origin;
      ActionTween moveToCenter = new ActionTween((a) => _handlePos = a, _handlePos, _center, 0.4, elasticOut);
      actions.run(moveToCenter);
      _isDown = false;
    } else if (event.type == "pointermove") {
      Offset movedDist = event.boxPosition - _pointerDownAt;

      _value = new Point(
        (movedDist.dx / 80.0).clamp(-1.0, 1.0),
        (movedDist.dy / 80.0).clamp(-1.0, 1.0));

        _handlePos = _center + new Offset(_value.x * 40.0, _value.y * 40.0);
    }
    return true;
  }

  void paint(PaintingCanvas canvas) {
    applyTransformForPivot(canvas);
    canvas.drawCircle(_handlePos, 25.0, _paintHandle);
    canvas.drawCircle(_center, 40.0, _paintControl);
  }
}
