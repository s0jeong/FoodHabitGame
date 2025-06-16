import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/recognition/phase2_detector.dart';
import 'package:flutter_app/game/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/mlkit/detector_view.dart';
import 'package:flutter_app/mlkit/painters/face_detector_painter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_app/utils/img_util.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_app/main.dart';

class Phase2DetectorView extends StatefulWidget {
  final BattleGame game;
  final Function() onFinished;

  const Phase2DetectorView({
    Key? key,
    required this.game,
    required this.onFinished,
  }) : super(key: key);

  @override
  State<Phase2DetectorView> createState() => _Phase2DetectorViewState();
}

class _Phase2DetectorViewState extends State<Phase2DetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );

  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.front;

  late Phase2Detector _detector;
  bool _isEating = false;
  bool _hasVegetable = false;
  String _statusMessage = " ";
  double _currentProgress = 0.0;
  Map<String, dynamic>? _lastMouthBoundingBox;
  Map<String, dynamic>? _lastVegetableBoundingBox;

  List<String> _imagePaths = [
    'assets/images/ui/eat_guide_1.png',
    'assets/images/ui/eat_guide_2.png',
    'assets/images/ui/eat_guide_3.png',
  ];
  
  int _currentImageIndex = 0;
  Timer? _imageChangeTimer;
  Timer? _recognitionTimer;

  @override
  void initState() {
    super.initState();
    _startImageChange();
    _initializeDetector();
  }

  void _startImageChange() {
    _imageChangeTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _imagePaths.length;
        });
      }
    });
  }

  void _initializeDetector() {
    _detector = Phase2Detector(
      onEatingComplete: (success) {
        if (success) {
          widget.game.gameWorld.enemyGroup?.processPhase2EatingDetection(true);
          _resetDetection();
          _currentProgress = min((_currentProgress + 50.0), 100.0);
          if (_currentProgress >= 100.0) {
            widget.game.gameWorld.restoreEnergy(widget.game.gameWorld.maxHeroEnergy);
            widget.onFinished();
          }
        }
      },
    );
  }

  void _resetDetection() {
    setState(() {
      _isEating = false;
      _hasVegetable = false;
      _statusMessage = "야채를 들어올려주세요";
      _lastMouthBoundingBox = null;
      _lastVegetableBoundingBox = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final imageSize = screenSize.width * 0.3;
    final sliderWidth = screenSize.width * 0.8;

    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Stack(
        children: [
          DetectorView(
            title: 'Phase 2 Detector',
            customPaint: _customPaint,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) {
              if (mounted) setState(() => _cameraLensDirection = value);
            },
          ),

          // 개발용 임시 패스 버튼
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // 임시로 한 번의 프로세스 완료로 처리
                    _currentProgress = min((_currentProgress + 50.0), 100.0);
                    widget.game.gameWorld.enemyGroup?.processPhase2EatingDetection(true);
                    
                    if (_currentProgress >= 100.0) {
                      // 개발용 패스 버튼으로도 에너지 게이지 최대로 충전
                      widget.game.gameWorld.restoreEnergy(widget.game.gameWorld.maxHeroEnergy);
                      widget.onFinished();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 0,  // 음영 제거
                    shadowColor: Colors.transparent,  // 그림자 색상 투명
                    surfaceTintColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 40),
                  onPressed: () {
                    widget.game.hidePhase2CameraOverlay();
                    widget.onFinished();
                  },
                ),
              ],
            ),
          ),

          // 가이드 이미지
          Positioned(
            top: screenSize.height * 0.05,
            left: screenSize.width * 0.05,
            child: Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_imagePaths[_currentImageIndex]),
                  fit: BoxFit.contain,
                ),
                borderRadius: BorderRadius.circular(imageSize * 0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),

          // 상태 메시지
          Positioned(
            bottom: screenSize.height * 0.1,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                color: Colors.transparent,
                child: Text(
                  "야채를 먹어주세요",
                  style: GoogleFonts.jua(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // 진행 상태 및 메시지
          Positioned(
            bottom: screenSize.height * 0.05,
            left: (screenSize.width - sliderWidth) / 2,
            width: sliderWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _statusMessage,
                    style: GoogleFonts.jua(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.02),
                Container(
                  width: sliderWidth,
                  height: screenSize.height * 0.03,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenSize.height * 0.015),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenSize.height * 0.015),
                    child: LinearProgressIndicator(
                      value: _currentProgress / 100,
                      backgroundColor: Colors.black45,
                      valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.jua(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 5),
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  Color _getProgressColor() {
    if (_currentProgress >= 100) return Colors.purple;
    if (_isEating && _hasVegetable) return Colors.greenAccent;
    return Colors.blue;
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;
    _isBusy = true;
    setState(() {});

    final faces = await _faceDetector.processImage(inputImage);
    final squareRect = _getSquareRect(faces, inputImage.metadata!.size);

    final image = Platform.isAndroid ? decodeYUV420SP(inputImage) : decodeBGRA8888(inputImage);
    if (squareRect != null) {
      final croppedImage = cropImage(image, squareRect);
      if (croppedImage != null) {
        final input = await getCnnInput(croppedImage);
        final output = Float32List(1 * 1).reshape([1, 1]);
        await aiManager.isolateVegetableInterpreter.run(input, output);
        
        bool isEating = output[0][0] > 0.6;
        bool hasVegetable = output[0][0] > 0.8;

        // 결과 생성 및 처리
        final result = Phase2DetectionResult(
          isEating: isEating,
          hasVegetable: hasVegetable,
          mouthBoundingBox: squareRect != null ? {
            'x': squareRect.left,
            'y': squareRect.top,
            'width': squareRect.width,
            'height': squareRect.height,
          } : null,
          vegetableBoundingBox: hasVegetable ? {
            'x': squareRect.left,
            'y': squareRect.top,
            'width': squareRect.width,
            'height': squareRect.height,
          } : null,
        );

        // 상태 업데이트 및 감지기에 전달
        _updateDetectionStatus(result);
        _detector.processDetection(result);
      }
    }

    setState(() {
      _customPaint = CustomPaint(
        painter: FaceDetectorPainter(
          faces,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
          _cameraLensDirection,
          squareRect: squareRect,
        ),
      );
    });

    _isBusy = false;
  }

  Rect? _getSquareRect(List<Face> faces, Size imageSize) {
    for (final face in faces) {
      final landmarks = face.landmarks;
      final bottomLip = landmarks[FaceLandmarkType.bottomMouth]?.position;
      final nose = landmarks[FaceLandmarkType.noseBase]?.position;
      final leftMouth = landmarks[FaceLandmarkType.leftMouth]?.position;
      final rightMouth = landmarks[FaceLandmarkType.rightMouth]?.position;

      if (bottomLip != null && nose != null && leftMouth != null && rightMouth != null) {
        final centerX = (leftMouth.x + rightMouth.x + bottomLip.x + nose.x) / 4;
        final centerY = (leftMouth.y + rightMouth.y + bottomLip.y + nose.y) / 4;
        final squareSize = imageSize.width * 0.15;
        final squareLeft = centerX - squareSize / 2;
        final squareTop = centerY - squareSize / 2;

        return Rect.fromLTWH(squareLeft, squareTop, squareSize, squareSize);
      }
    }
    return null;
  }

  img.Image? cropImage(img.Image image, Rect rect) {
    return img.copyCrop(
      image,
      x: rect.left.toInt(),
      y: rect.top.toInt(),
      width: rect.width.toInt(),
      height: rect.height.toInt(),
    );
  }

  void _updateDetectionStatus(Phase2DetectionResult result) {
    setState(() {
      _isEating = result.isEating;
      _hasVegetable = result.hasVegetable;
      
      // if (!result.isEating && !result.hasVegetable) {
      //   _statusMessage = "야채를 들어올려주세요";
      // } else if (!result.isEating && result.hasVegetable) {
      //   _statusMessage = "야채를 입 쪽으로 가져가주세요";
      // } else if (result.isEating && result.hasVegetable && result.isValidEatingPosition) {
      //   _statusMessage = "이제 야채를 먹어주세요";
      // } else if (result.isEating && !result.hasVegetable) {
      //   _statusMessage = "잘했어요! 계속 씹어주세요";
      // }
    });
  }

  Future<List> getCnnInput(img.Image image) async {
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
    Float32List inputBytes = Float32List(1 * 224 * 224 * 3);

    final range = resizedImage.getRange(0, 0, 224, 224);
    int pixelIndex = 0;
    while (range.moveNext()) {
      final pixel = range.current;
      pixel.r = pixel.maxChannelValue - pixel.r; // Invert the red channel
      pixel.g = pixel.maxChannelValue - pixel.g; // Invert the green channel
      pixel.b = pixel.maxChannelValue - pixel.b; // Invert the blue channel
      inputBytes[pixelIndex++] = pixel.r / 255.0;
      inputBytes[pixelIndex++] = pixel.g / 255.0;
      inputBytes[pixelIndex++] = pixel.b / 255.0;
    }

    final input = inputBytes.reshape([1, 224, 224, 3]);
    return input;
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _imageChangeTimer?.cancel();
    _recognitionTimer?.cancel();
    _detector.dispose();
    super.dispose();
  }
} 