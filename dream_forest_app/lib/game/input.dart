import 'package:flutter/services.dart';

/// 손가락 하나 조작 + 두 손가락 조작을 함께 지원해요.
/// - 첫 손가락: 좌우로 끌면 이동, 위로 튕기면 점프, 아래로 튕기면 발판 아래로
/// - 짧게 톡: 점프
/// - 첫 손가락을 누른 채 다른 손가락으로 톡: 점프 (왼손 이동 + 오른손 점프)
/// - 손을 다 떼면 멈춰서 자동 사격
class GameInput {
  int? _moveId;
  Offset origin = Offset.zero, current = Offset.zero, start = Offset.zero;
  int _t0 = 0;
  bool _moved = false;
  double _anchorY = 0;
  bool _armed = true;
  int _touchDir = 0;
  final Set<int> _extra = {};
  bool _jumpQueued = false, _dropQueued = false;
  bool keyLeft = false, keyRight = false, keyJumpHeld = false;
  bool usingKeys = false;

  bool get touching => _moveId != null;

  int get dir {
    final k = (keyRight ? 1 : 0) - (keyLeft ? 1 : 0);
    return k != 0 ? k : _touchDir;
  }

  bool consumeJump() {
    final j = _jumpQueued;
    _jumpQueued = false;
    return j;
  }

  bool consumeDrop() {
    final d = _dropQueued;
    _dropQueued = false;
    return d;
  }

  bool get jumpHeld => usingKeys ? keyJumpHeld : true;

  void down(int id, Offset pos) {
    usingKeys = false;
    if (_moveId == null) {
      _moveId = id;
      origin = current = start = pos;
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _moved = false;
      _anchorY = pos.dy;
      _armed = true;
      _touchDir = 0;
    } else {
      _extra.add(id);
      _jumpQueued = true;
    }
  }

  void move(int id, Offset pos) {
    if (id != _moveId) return;
    current = pos;
    var dx = pos.dx - origin.dx;
    if (dx.abs() > 64) {
      origin = Offset(pos.dx - dx.sign * 64, origin.dy);
      dx = pos.dx - origin.dx;
    }
    _touchDir = dx.abs() > 14 ? dx.sign.toInt() : 0;
    if ((pos - start).distance > 12) _moved = true;
    if (_armed) {
      if (pos.dy > _anchorY) _anchorY = pos.dy;
      if (_anchorY - pos.dy > 34) {
        _jumpQueued = true;
        _armed = false;
        _anchorY = pos.dy;
      }
    } else {
      if (pos.dy < _anchorY) _anchorY = pos.dy;
      if (pos.dy - _anchorY > 16) {
        _armed = true;
        _anchorY = pos.dy;
      }
    }
    if (pos.dy - start.dy > 70 && (pos.dx - start.dx).abs() < 40) {
      _dropQueued = true;
      start = pos;
    }
  }

  void up(int id) {
    if (_extra.remove(id)) return;
    if (id != _moveId) return;
    if (!_moved && DateTime.now().millisecondsSinceEpoch - _t0 < 230) _jumpQueued = true;
    _moveId = null;
    _touchDir = 0;
  }

  void reset() {
    _moveId = null;
    _extra.clear();
    _touchDir = 0;
    keyLeft = keyRight = keyJumpHeld = false;
    _jumpQueued = _dropQueued = false;
  }

  /// true 를 돌려주면 키를 처리한 거예요.
  bool key(KeyEvent e) {
    final k = e.logicalKey;
    final isDown = e is KeyDownEvent || e is KeyRepeatEvent;
    final first = e is KeyDownEvent;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      keyLeft = isDown;
    } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      keyRight = isDown;
    } else if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW || k == LogicalKeyboardKey.space) {
      keyJumpHeld = isDown;
      if (first) _jumpQueued = true;
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      if (first) _dropQueued = true;
    } else {
      return false;
    }
    usingKeys = true;
    return true;
  }
}
