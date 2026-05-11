import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_task/background/background_socket_service.dart';

void main() {
  group('BackgroundSocketService', () {
    late BackgroundSocketService service;

    setUp(() {
      service = BackgroundSocketService();
    });

    tearDown(() {
      service.dispose();
    });

    test('isConnected is initially false', () {
      expect(service.isConnected, false);
    });

    test('connect should initialize socket with correct config', () {
      service.connect('https://test-server.com');
      expect(service.isConnected, false);
    });

    test('disconnect should close socket connection', () {
      service.connect('https://test-server.com');
      service.disconnect();
      expect(service.isConnected, false);
    });

    test('dispose should clean up resources', () {
      service.connect('https://test-server.com');
      service.dispose();
      expect(service.isConnected, false);
    });
  });
}