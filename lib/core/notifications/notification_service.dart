abstract class NotificationService {
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
}
