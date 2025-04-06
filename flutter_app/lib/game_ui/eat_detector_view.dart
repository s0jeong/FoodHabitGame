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
  var _cameraLensDirection = CameraLensDirection.back;

  int _recognizedTime = 0; // 얼굴 인식된 시간 (밀리초 단위)
  Timer? _recognitionTimer; // 타이머 관리
  double _boxOpacity = 1.0; // 이미지 상자의 투명도
  final maxTime = 2000; // 최대 인식 시간

  List<String> _imagePaths = [
    'assets/images/ui/eat_guide_1.png',
    'assets/images/ui/eat_guide_2.png',
    'assets/images/ui/eat_guide_3.png',
  ];
  
  int _currentImageIndex = 0; // 현재 표시할 이미지 인덱스
  Timer? _imageChangeTimer; // 이미지 변경 타이머

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
      if (flag == 0) {
        return;
      }
      // 음식 먹는 동안만 게이지 증가
      _recognizedTime += 10;

      if (_recognizedTime >= maxTime) {
        // 인식 완료
        timer.cancel();
        _recognitionTimer = null;
        print('finish');
        widget.onFinished();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _canProcess = false;
    _recognitionTimer?.cancel();
    _faceDetector.close();
    _imageChangeTimer?.cancel(); // 이미지 변경 타이머 해제
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(1),
      child: Stack(
        children: [
          DetectorView(
            title: 'Face Detector',
            customPaint: _customPaint,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Opacity(
              opacity: _boxOpacity.clamp(0.0, 1.0), // Clamp opacity to ensure it is between 0 and 1
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_imagePaths[_currentImageIndex]), // 현재 이미지 경로 설정
                    fit: BoxFit.cover, // 이미지가 상자에 맞게 조정됨
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50, // 슬라이더 위치 조정
            left: 16,
            right: 16,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.green,
                inactiveTrackColor: Colors.black,
                thumbColor: Colors.white,
                trackHeight: 32, // 슬라이더 바 두께 조정
                overlayColor: Colors.green.withOpacity(1),
              ),
              child: Slider(
                value: _recognizedTime.toDouble(),
                max: maxTime.toDouble(), // 최대값은 2초
                min: 0,
                divisions: 20, // 구간 나누기
                onChanged: (_) {}, // 사용자 입력 방지
              ),
            ),
          ),
          Center(
          child: Text(_text ?? '', style: TextStyle(color: flag == 0? Colors.white : Colors.greenAccent, fontSize: 32)),
        ),
        ],
      ),
    );
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
