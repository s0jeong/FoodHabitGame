import 'dart:async';

class Phase2DetectionResult {
  final bool isEating;        // 먹기 인식 상태 (0 or 1)
  final bool hasVegetable;    // 야채 인식 상태 (0 or 1)
  final Map<String, dynamic>? mouthBoundingBox;    // 입 주변 영역
  final Map<String, dynamic>? vegetableBoundingBox; // 야채 영역

  Phase2DetectionResult({
    required this.isEating,
    required this.hasVegetable,
    this.mouthBoundingBox,
    this.vegetableBoundingBox,
  });

  // 야채와 입의 위치 관계 검증
  bool get isValidEatingPosition {
    if (!hasVegetable || mouthBoundingBox == null || vegetableBoundingBox == null) {
      return false;
    }
    return _checkBoundingBoxOverlap();
  }

  // 실제 먹기 동작 검증 (야채 인식 0, 먹기 인식 1, 이전에 위치가 겹쳤음)
  bool get isValidEating {
    return isEating && !hasVegetable;
  }

  bool _checkBoundingBoxOverlap() {
    if (mouthBoundingBox == null || vegetableBoundingBox == null) return false;

    double mouthX = mouthBoundingBox!['x'] as double;
    double mouthY = mouthBoundingBox!['y'] as double;
    double mouthW = mouthBoundingBox!['width'] as double;
    double mouthH = mouthBoundingBox!['height'] as double;

    double vegX = vegetableBoundingBox!['x'] as double;
    double vegY = vegetableBoundingBox!['y'] as double;
    double vegW = vegetableBoundingBox!['width'] as double;
    double vegH = vegetableBoundingBox!['height'] as double;

    // 입 주변 영역을 15% 확장 (기존 20%에서 더 엄격하게 조정)
    double expandedMouthX = mouthX - (mouthW * 0.15);
    double expandedMouthY = mouthY - (mouthH * 0.15);
    double expandedMouthW = mouthW * 1.3;
    double expandedMouthH = mouthH * 1.3;

    return !(
      expandedMouthX + expandedMouthW < vegX ||
      vegX + vegW < expandedMouthX ||
      expandedMouthY + expandedMouthH < vegY ||
      vegY + vegH < expandedMouthY
    );
  }
}

class Phase2Detector {
  bool _wasEating = false;
  bool _hadVegetable = false;
  bool _wasOverlapping = false;
  Timer? _eatingTimer;
  final Function(bool) onEatingComplete;
  
  Phase2Detector({required this.onEatingComplete});

  void processDetection(Phase2DetectionResult result) {
    // 1. 초기 상태 (모두 0)
    if (!result.isEating && !result.hasVegetable) {
      _resetState();
      return;
    }

    // 2. 야채를 들어올린 상태 (야채 1, 먹기 0)
    if (!result.isEating && result.hasVegetable) {
      _hadVegetable = true;
      _wasOverlapping = false;
      return;
    }

    // 3. 야채를 입으로 가져간 상태 (둘 다 1, 위치 겹침)
    if (result.isEating && result.hasVegetable && result.isValidEatingPosition) {
      _wasEating = true;
      _hadVegetable = true;
      _wasOverlapping = true;
      return;
    }

    // 4. 야채를 입에 넣은 상태 (먹기 1, 야채 0, 이전에 겹침)
    if (result.isEating && !result.hasVegetable && _wasOverlapping) {
      _startEatingTimer();
      return;
    }

    // 5. 식기도구를 내려놓은 상태 (모두 0)
    if (!result.isEating && !result.hasVegetable && _wasEating && _hadVegetable) {
      _completeEating();
    }
  }

  void _startEatingTimer() {
    _eatingTimer?.cancel();
    _eatingTimer = Timer(Duration(milliseconds: 800), () {
      if (_wasEating && _hadVegetable && _wasOverlapping) {
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
    _wasOverlapping = false;
    _eatingTimer?.cancel();
  }

  void dispose() {
    _eatingTimer?.cancel();
  }
} 