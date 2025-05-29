import 'package:tflite_flutter/tflite_flutter.dart';

class AiManager {
  
  late Interpreter _interpreter;
  late IsolateInterpreter isolateInterpreter;

  late Interpreter _vegetableInterpreter;
  late IsolateInterpreter isolateVegetableInterpreter;
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/MobileNetV2(200).tflite',
        options: InterpreterOptions()..threads = 4,
        );
      isolateInterpreter = await IsolateInterpreter.create(address: _interpreter.address);
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }

    try {
      _vegetableInterpreter = await Interpreter.fromAsset(
        'assets/vege3.tflite',
        options: InterpreterOptions()..threads = 4,
        );
      isolateVegetableInterpreter = await IsolateInterpreter.create(address: _interpreter.address);
      print('Model vege loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }
}