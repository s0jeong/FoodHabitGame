import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import 'camera_view.dart';


class DetectorView extends StatefulWidget {
  DetectorView({
    Key? key,
    required this.title,
    required this.onImage,
    this.customPaint,
    this.text,
    this.initialCameraLensDirection = CameraLensDirection.front,
    this.onCameraFeedReady,
    this.onCameraLensDirectionChanged,
  }) : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final Function()? onCameraFeedReady;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;

  @override
  State<DetectorView> createState() => _DetectorViewState();
}

class _DetectorViewState extends State<DetectorView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
            customPaint: widget.customPaint,
            onImage: widget.onImage,
            onCameraFeedReady: widget.onCameraFeedReady,
            initialCameraLensDirection: widget.initialCameraLensDirection,
            onCameraLensDirectionChanged: widget.onCameraLensDirectionChanged,
          );
  }
}
