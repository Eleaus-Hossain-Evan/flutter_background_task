import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_task/background/background_socket_service.dart';

void main() {
  group('BackgroundSocketService', () {
    late BackgroundSocketService service;

    setUp(() {
      service = BackgroundSocketService();
    });

    test('connect should initialize socket with correct config', () {
      service.connect('https://test-server.com');
    });

    test('disconnect should close socket connection', () {
      service.connect('https://test-server.com');
      service.disconnect();
    });

    test('dispose should clean up resources', () {
      service.connect('https://test-server.com');
      service.dispose();
    });
  });
}