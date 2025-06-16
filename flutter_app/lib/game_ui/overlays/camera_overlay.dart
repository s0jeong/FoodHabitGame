import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/recognition/eating_detector.dart';
import 'package:flutter_app/game/game.dart';

class CameraOverlay extends StatefulWidget {
  final BattleGame game;
  
  const CameraOverlay({Key? key, required this.game}) : super(key: key);

  @override
  State<CameraOverlay> createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay> {
  late CameraController _controller;
  late EatingDetector _eatingDetector;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _eatingDetector = EatingDetector(
      onEatingComplete: (success) {
        if (success) {
          widget.game.hideEatCameraOverlay();
        }
      }
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller.initialize();
    if (mounted) {
      setState(() {});
      _startImageStream();
    }
  }

  void _startImageStream() {
    _controller.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        // 두 모델 동시 실행
        final eatingResult = await _runEatingModel(image);
        final vegetableResult = await _runVegetableModel(image);

        // 결과 통합 및 처리
        final detectionResult = DetectionResult(
          isEating: eatingResult['isEating'] ?? false,
          hasVegetable: vegetableResult['hasVegetable'] ?? false,
          mouthBoundingBox: eatingResult['boundingBox'],
          vegetableBoundingBox: vegetableResult['boundingBox'],
        );

        _eatingDetector.processDetection(detectionResult);
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<Map<String, dynamic>> _runEatingModel(CameraImage image) async {
    // TODO: 실제 먹기 인식 모델 구현
    return {'isEating': false, 'boundingBox': null};
  }

  Future<Map<String, dynamic>> _runVegetableModel(CameraImage image) async {
    // TODO: 실제 야채 인식 모델 구현
    return {'hasVegetable': false, 'boundingBox': null};
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }

    return Stack(
      children: [
        CameraPreview(_controller),
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              widget.game.hideEatCameraOverlay();
            },
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '야채를 입에 가져다 대세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _eatingDetector.dispose();
    super.dispose();
  }
} 