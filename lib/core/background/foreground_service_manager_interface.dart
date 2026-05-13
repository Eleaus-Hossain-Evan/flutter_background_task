abstract class IForegroundServiceManager {
  Future<void> init();
  Future<void> start();
  Future<void> stop();
  Future<bool> get isRunning;
  Future<void> requestAndroidPermissions();
  void initCommunicationPort();
}
