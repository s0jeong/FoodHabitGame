import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/mlkit/detector_view.dart';
import 'package:flutter_app/mlkit/painters/face_detector_painter.dart';
import 'package:flutter_app/utils/img_util.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// ignore: must_be_immutable
// 먹기 카메라 뷰
class EatDetectorView extends StatefulWidget {
  @override
  State<EatDetectorView> createState() => _FaceDetectorViewState();

  EatDetectorView({required this.onFinished});
  Function onFinished;
}

class _FaceDetectorViewState extends State<EatDetectorView> {
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

  int _recognizedTime = 0;
  Timer? _recognitionTimer;
  double _boxOpacity = 1.0;
  final maxTime = 2000;

  // 먹기 패턴 인식을 위한 변수들
  bool _wasEating = false; // 이전 상태가 먹는 중이었는지
  int _eatingCount = 0; // 완료된 먹기 동작 횟수
  double _currentProgress = 0.0; // 현재 진행도 (0-100%)

  List<String> _imagePaths = [
    'assets/images/ui/eat_guide_1.png',
    'assets/images/ui/eat_guide_2.png',
    'assets/images/ui/eat_guide_3.png',
  ];
  
  int _currentImageIndex = 0;
  Timer? _imageChangeTimer;

  String? _text;
  int flag = 0;

  @override
  void initState() {
    super.initState();
    _startImageChange();
    _recognitionTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // 먹기 패턴 인식 로직
      bool isEating = flag == 1;
      
      // 0->1->0 패턴 감지
      if (!_wasEating && isEating) {
        // 0에서 1로 변경된 순간
        print('Started eating');
      } else if (_wasEating && !isEating) {
        // 1에서 0으로 변경된 순간 (먹기 동작 완료)
        _eatingCount++;
        _currentProgress = (_eatingCount / 4) * 100; // 25%씩 증가
        print('Completed eating motion: $_eatingCount');

        if (_eatingCount >= 4) {
          // 4번의 먹기 동작 완료
          timer.cancel();
          _recognitionTimer = null;
          print('All eating motions completed');
          widget.onFinished();
        }
      }
      
      _wasEating = isEating;

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final imageSize = screenSize.width * 0.3;
    final sliderWidth = screenSize.width * 0.8;
    
    return Material(
      color: Colors.black.withOpacity(1),
      child: Stack(
        children: [
          DetectorView(
            title: 'Face Detector',
            customPaint: _customPaint,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) {
              if (mounted) setState(() => _cameraLensDirection = value);
            },
          ),
          Positioned(
            top: screenSize.height * 0.05,
            left: screenSize.width * 0.05,
            child: Opacity(
              opacity: _boxOpacity.clamp(0.0, 1.0),
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
          ),
          Positioned(
            bottom: screenSize.height * 0.05,
            left: (screenSize.width - sliderWidth) / 2,
            width: sliderWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: screenSize.width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.02),
                Container(
                  width: sliderWidth,
                  height: screenSize.height * 0.03,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenSize.height * 0.015),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenSize.height * 0.015),
                    child: LinearProgressIndicator(
                      value: _currentProgress / 100,
                      backgroundColor: Colors.black45,
                      valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
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

  String _getStatusText() {
    if (_eatingCount >= 4) {
      return "완료!";
    }
    return "${_eatingCount}번 먹었어요! (${4 - _eatingCount}번 남음)";
  }

  Color _getStatusColor() {
    if (flag == 1) {
      return Colors.greenAccent;
    }
    return _eatingCount >= 4 ? Colors.purple : Colors.white;
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;
    _isBusy = true;
    setState(() {});

    final faces = await _faceDetector.processImage(inputImage);
    final squareRect = _getSquareRect(faces, inputImage.metadata!.size);

    final image = Platform.isAndroid ? decodeYUV420SP(inputImage): decodeBGRA8888(inputImage);
    if (squareRect != null) {
      final croppedImage = cropImage(image, squareRect);
      //print(croppedImage?.height);
      if (croppedImage != null) {
        //final input = convertToFloat32List(await getCnnInput(croppedImage)).reshape([1, 224, 224, 3]);
        final input = await getCnnInput(croppedImage);
        final output = Float32List(1 * 1).reshape([1, 1]);
        await aiManager.isolateInterpreter.run(input, output);
        
        
        setState(() {
          if (output[0][0] > 0.6) {
            flag = 1;
          } else {
            flag = 0;
          }
          _text = output[0][0].toStringAsFixed(2);
          //print('Inference Result: ${(output[0][0]).toStringAsFixed(7)}');
        });
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

  void _startImageChange() {
    _imageChangeTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        // 다음 이미지로 변경하고 인덱스를 순환함.
        _currentImageIndex = (_currentImageIndex + 1) % _imagePaths.length;
      });
    });
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
        final squareLeft = (centerX - squareSize / 2);
        final squareTop = (centerY - squareSize / 2);

        return Rect.fromLTWH(squareLeft, squareTop, squareSize, squareSize);
      }
    }
    return null;
  }

  img.Image? cropImage(img.Image image, Rect rect) {
    return img.copyCrop(image, x: rect.left.toInt(), y: rect.top.toInt(), width: rect.width.toInt(), height: rect.height.toInt());
  }

  Float32List convertToFloat32List(List<List<List<double>>> input) {
    return Float32List.fromList(input.expand((row) => row.expand((col) => col)).toList());
  }
  Future<List> getCnnInput(img.Image image) async{
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
    Float32List inputBytes = Float32List(1 * 224 * 224 * 3);



    final range = resizedImage.getRange(0, 0, 224, 224);
    int pixelIndex = 0;
    while (range.moveNext()) {
      final pixel = range.current;
      pixel.r = pixel.maxChannelValue - pixel.r; // Invert the red channel.
      pixel.g = pixel.maxChannelValue - pixel.g; // Invert the green channel.
      pixel.b = pixel.maxChannelValue - pixel.b; // Invert the blue channel.
      inputBytes[pixelIndex++] = pixel.r / 255.0;
      inputBytes[pixelIndex++] = pixel.g / 255.0;
      inputBytes[pixelIndex++] = pixel.b / 255.0;
    }

    final input = inputBytes.reshape([1, 224, 224, 3]);
    return input;
  }
}
