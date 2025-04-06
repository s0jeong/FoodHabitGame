import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Android: YUV420SP 디코더
decodeYUV420SP(InputImage image) {
  final width = image.metadata!.size.width.toInt();
  final height = image.metadata!.size.height.toInt();

  Uint8List yuv420sp = image.bytes!;
  var rotationOfCamera = 0;
  if (image.metadata != null && image.metadata!.rotation.rawValue != 0) {
    rotationOfCamera = image.metadata!.rotation.rawValue;
  }

  return decodeYUV420SPFromCamera(
    width,
    height,
    yuv420sp,
    rotationOfCamera,
  );
}

img.Image decodeYUV420SPFromCamera(
  int width,
  int height,
  Uint8List yuv420sp,
  int rotationOfCamera,
) {
  var outImg = img.Image(width: width, height: height);

  final int frameSize = width * height;

  for (int j = 0, yp = 0; j < height; j++) {
    int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
    for (int i = 0; i < width; i++, yp++) {
      int y = (0xff & yuv420sp[yp]) - 16;
      if (y < 0) y = 0;
      if ((i & 1) == 0) {
        v = (0xff & yuv420sp[uvp++]) - 128;
        u = (0xff & yuv420sp[uvp++]) - 128;
      }

      int y1192 = 1192 * y;
      int r = (y1192 + 1634 * v);
      int g = (y1192 - 833 * v - 400 * u);
      int b = (y1192 + 2066 * u);

      if (r < 0) {
        r = 0;
      } else if (r > 262143) {
        r = 262143;
      }
      if (g < 0) {
        g = 0;
      } else if (g > 262143) {
        g = 262143;
      }
      if (b < 0) {
        b = 0;
      } else if (b > 262143) {
        b = 262143;
      }
      outImg.setPixelRgb(i, j, ((r << 6) & 0xff0000) >> 16,
          ((g >> 2) & 0xff00) >> 8, (b >> 10) & 0xff);
    }
  }

  if (rotationOfCamera != 0) {
    outImg = img.copyRotate(outImg, angle: rotationOfCamera);
  }

  return outImg;
}

/// iOS: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange 디코더
decodeYUV420BiPlanar(InputImage image) {
  final width = image.metadata!.size.width.toInt();
  final height = image.metadata!.size.height.toInt();

  Uint8List yPlane = image.bytes!.sublist(0, width * height);
  Uint8List uvPlane = image.bytes!.sublist(width * height);

  return decodeYUV420BiPlanarFromPlanes(
    width,
    height,
    yPlane,
    uvPlane,
  );
}

img.Image decodeYUV420BiPlanarFromPlanes(
  int width,
  int height,
  Uint8List yPlane,
  Uint8List uvPlane,
) {
  final outImg = img.Image(width: width, height: height);

  for (int j = 0; j < height; j++) {
    for (int i = 0; i < width; i++) {
      int y = yPlane[j * width + i] & 0xff;
      int uvIndex = (j >> 1) * (width >> 1) + (i >> 1);
      int u = uvPlane[uvIndex * 2] & 0xff;
      int v = uvPlane[uvIndex * 2 + 1] & 0xff;

      int c = y - 16;
      int d = u - 128;
      int e = v - 128;

      int r = (298 * c + 409 * e + 128) >> 8;
      int g = (298 * c - 100 * d - 208 * e + 128) >> 8;
      int b = (298 * c + 516 * d + 128) >> 8;

      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

      outImg.setPixelRgb(i, j, r, g, b);
    }
  }

  return outImg;
}

/// iOS: BGRA8888 데이터를 디코딩
decodeBGRA8888(InputImage image) {
  final width = image.metadata!.size.width.toInt();
  final height = image.metadata!.size.height.toInt();

  Uint8List bgraBytes = image.bytes!;

  return convertBGRA8888ToImage(
    width,
    height,
    bgraBytes,
  );
}

img.Image convertBGRA8888ToImage(int width, int height, Uint8List bgraBytes) {
  final outImg = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixelIndex = (y * width + x) * 4;

      final b = bgraBytes[pixelIndex];
      final g = bgraBytes[pixelIndex + 1];
      final r = bgraBytes[pixelIndex + 2];
      final a = bgraBytes[pixelIndex + 3];

      outImg.setPixelRgba(x, y, r, g, b, a);
    }
  }

  return outImg;
}
