import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/mlkit/detector_view.dart';
import 'package:flutter_app/utils/img_util.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// ignore: must_be_immutable
class VegetableDetectorView extends StatefulWidget {
  VegetableDetectorView({required this.onFinished});
  final Function onFinished;

  @override
  State<VegetableDetectorView> createState() => _VegetableDetectorViewState();
}

class _VegetableDetectorViewState extends State<VegetableDetectorView>
    with SingleTickerProviderStateMixin {
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;

  int flag = 0;
  Timer? _recognitionTimer;
  int _recognizedTime = 0; // 얼굴 인식된 시간 (밀리초 단위)
  final int maxTime = 2000; // 최대 인식 시간

  final String _imagePath = 'assets/images/heros/bro.png'; // 사용될 이미지 경로
  late AnimationController _controller; // 애니메이션 컨트롤러
  late Animation<double> _animation; // 회전 애니메이션

  @override
  void initState() {
    super.initState();
    _startAnimation();
    _recognitionTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (flag == 0) {
        return;
      }
      _recognizedTime += 10;

      if (_recognizedTime >= maxTime) {
        timer.cancel();
        _recognitionTimer = null;
        print('finish');
        if (mounted) {
          widget.onFinished();
        }
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _canProcess = false;
    _recognitionTimer?.cancel(); // 타이머 해제
    _controller.dispose(); // 애니메이션 컨트롤러 해제
    super.dispose();
  }

  void _startAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true); // 애니메이션을 반복하며 역방향으로 실행

    _animation = Tween<double>(begin: -0.1, end: 0.1).animate(_controller);
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
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 게이지 차오르는 애니메이션
                SizedBox(
                  width: 400,
                  height: 400,
                  child: CircularProgressIndicator(
                    value: (_recognizedTime.toDouble() / maxTime.toDouble()).clamp(0.0, 1.0), // 게이지 값
                    strokeWidth: 30,
                    backgroundColor: Colors.black, // 배경 색상
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.greenAccent), // 차오르는 색상
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16, // 화면 왼쪽 위 위치 조정
            left: 16,
            child: RotationTransition(
              turns: _animation,
              child: Image.asset(
                _imagePath,
                width: 300, // 이미지 크기 조정
                height: 300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;
    _isBusy = true;

    try {
      final image = Platform.isAndroid ? decodeYUV420SP(inputImage) : decodeBGRA8888(inputImage);
      final croppedImage = cropImage(image);
      final input = await getCnnInput(croppedImage);
      final output = Float32List(1 * 1).reshape([1, 1]);

      await aiManager.isolateVegetableInterpreter.run(input, output);

      if (mounted) {
        setState(() {
          flag = output[0][0] > 0.8 ? 1 : 0;
          print('Inference Result: ${(output[0][0]).toStringAsFixed(7)}');
        });
      }
    } catch (e) {
      print("Error processing image: $e");
    } finally {
      _isBusy = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  img.Image cropImage(img.Image image) {
    final int imageWidth = image.width;
    final int imageHeight = image.height;

    final double scale = 0.6; // 크롭 크기를 조정하는 비율
    final int cropSize = (imageWidth < imageHeight
            ? imageWidth
            : imageHeight * scale)
        .toInt();

    final int cropX = (imageWidth - cropSize) ~/ 2;
    final int cropY = (imageHeight - cropSize) ~/ 2;

    return img.copyCrop(image, x: cropX, y: cropY, width: cropSize, height: cropSize);
  }

  Future<List> getCnnInput(img.Image image) async {
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
    Float32List inputBytes = Float32List(1 * 224 * 224 * 3);

    final range = resizedImage.getRange(0, 0, 224, 224);
    int pixelIndex = 0;
    while (range.moveNext()) {
      final pixel = range.current;
      inputBytes[pixelIndex++] = pixel.r / 255.0;
      inputBytes[pixelIndex++] = pixel.g / 255.0;
      inputBytes[pixelIndex++] = pixel.b / 255.0;
    }

    final input = inputBytes.reshape([1, 224, 224, 3]);
    return input;
  }
}
