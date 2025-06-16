import 'dart:async';

class DetectionResult {
  final bool isEating;
  final bool hasVegetable;
  final Map<String, dynamic>? mouthBoundingBox;
  final Map<String, dynamic>? vegetableBoundingBox;

  DetectionResult({
    required this.isEating,
    required this.hasVegetable,
    this.mouthBoundingBox,
    this.vegetableBoundingBox,
  });

  bool get isValidEating {
    if (!isEating || !hasVegetable) return false;
    if (mouthBoundingBox == null || vegetableBoundingBox == null) return false;
    
    // 입과 야채의 위치가 충분히 가까운지 확인
    return _checkBoundingBoxOverlap();
  }

  bool _checkBoundingBoxOverlap() {
    if (mouthBoundingBox == null || vegetableBoundingBox == null) return false;

    // 입 주변 영역 확장 (여유 공간)
    double mouthX = mouthBoundingBox!['x'] as double;
    double mouthY = mouthBoundingBox!['y'] as double;
    double mouthW = mouthBoundingBox!['width'] as double;
    double mouthH = mouthBoundingBox!['height'] as double;

    double vegX = vegetableBoundingBox!['x'] as double;
    double vegY = vegetableBoundingBox!['y'] as double;
    double vegW = vegetableBoundingBox!['width'] as double;
    double vegH = vegetableBoundingBox!['height'] as double;

    // 입 주변 영역을 20% 확장
    double expandedMouthX = mouthX - (mouthW * 0.2);
    double expandedMouthY = mouthY - (mouthH * 0.2);
    double expandedMouthW = mouthW * 1.4;
    double expandedMouthH = mouthH * 1.4;

    // 두 영역이 겹치는지 확인
    bool hasOverlap = !(
      expandedMouthX + expandedMouthW < vegX ||
      vegX + vegW < expandedMouthX ||
      expandedMouthY + expandedMouthH < vegY ||
      vegY + vegH < expandedMouthY
    );

    return hasOverlap;
  }
}

class EatingDetector {
  bool _wasEating = false;
  bool _hadVegetable = false;
  Timer? _eatingTimer;
  final Function(bool) onEatingComplete;
  
  EatingDetector({required this.onEatingComplete});

  void processDetection(DetectionResult result) {
    if (result.isValidEating) {
      // 야채가 입 근처에 있고 먹기 동작이 감지됨
      _wasEating = true;
      _hadVegetable = true;
      _startEatingTimer();
    } else if (_wasEating && _hadVegetable) {
      // 이전에 먹고 있었고 야채도 있었는데, 지금은 둘 다 없음
      // -> 먹기 완료로 간주
      _completeEating();
    } else {
      // 먹기 동작이 없거나 야채가 없음
      _resetState();
    }
  }

  void _startEatingTimer() {
    _eatingTimer?.cancel();
    _eatingTimer = Timer(Duration(milliseconds: 500), () {
      // 타이머 동안 상태가 유지되었다면 먹기 완료로 간주
      if (_wasEating && _hadVegetable) {
        _completeEating();
      }
    });
  }

  void _completeEating() {
    onEatingComplete(true);
    _resetState();
  }

  void _resetState() {
    _wasEating = false;
    _hadVegetable = false;
    _eatingTimer?.cancel();
  }

  void dispose() {
    _eatingTimer?.cancel();
  }
} 