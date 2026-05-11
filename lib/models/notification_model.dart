import 'dart:convert';

import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String message;
  final NotificationData data;
  final DateTime timestamp;
  const NotificationModel({
    required this.message,
    required this.data,
    required this.timestamp,
  });

  NotificationModel copyWith({
    String? message,
    NotificationData? data,
    DateTime? timestamp,
  }) {
    return NotificationModel(
      message: message ?? this.message,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'data': data.toMap(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      message: map['message'] ?? '',
      data: NotificationData.fromMap(map['data']),
      timestamp: DateTime.parse(map['timestamp'] ?? ''),
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'NotificationModel(message: $message, data: $data, timestamp: $timestamp)';

  @override
  List<Object> get props => [message, data, timestamp];
}

class NotificationData extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final Data data;
  final String imageUrl;
  final String actionUrl;
  final String userId;
  final List<dynamic> userIds;
  final bool isGlobal;
  final bool isRead;
  final String readAt;
  final String createdBy;
  final bool isDeleted;
  final String deletedAt;
  final String createdAt;
  final String updatedAt;
  final String scheduledFor;
  final bool isSent;
  const NotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.data,
    required this.imageUrl,
    required this.actionUrl,
    required this.userId,
    required this.userIds,
    required this.isGlobal,
    required this.isRead,
    required this.readAt,
    required this.createdBy,
    required this.isDeleted,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.scheduledFor,
    required this.isSent,
  });

  NotificationData copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? priority,
    Data? data,
    String? imageUrl,
    String? actionUrl,
    String? userId,
    List<dynamic>? userIds,
    bool? isGlobal,
    bool? isRead,
    String? readAt,
    String? createdBy,
    bool? isDeleted,
    String? deletedAt,
    String? createdAt,
    String? updatedAt,
    String? scheduledFor,
    bool? isSent,
  }) {
    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      userId: userId ?? this.userId,
      userIds: userIds ?? this.userIds,
      isGlobal: isGlobal ?? this.isGlobal,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdBy: createdBy ?? this.createdBy,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isSent: isSent ?? this.isSent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'data': data.toMap(),
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'userId': userId,
      'userIds': userIds,
      'isGlobal': isGlobal,
      'isRead': isRead,
      'readAt': readAt,
      'createdBy': createdBy,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'scheduledFor': scheduledFor,
      'isSent': isSent,
    };
  }

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      priority: map['priority'] ?? '',
      data: Data.fromMap(map['data']),
      imageUrl: map['imageUrl'] ?? '',
      actionUrl: map['actionUrl'] ?? '',
      userId: map['userId'] ?? '',
      userIds: List<dynamic>.from(map['userIds'] ?? const []),
      isGlobal: map['isGlobal'] ?? false,
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'] ?? '',
      createdBy: map['createdBy'] ?? '',
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: map['deletedAt'] ?? '',
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      scheduledFor: map['scheduledFor'] ?? '',
      isSent: map['isSent'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationData.fromJson(String source) =>
      NotificationData.fromMap(json.decode(source));

  @override
  String toString() {
    return 'NotificationData(id: $id, title: $title, message: $message, type: $type, priority: $priority, data: $data, imageUrl: $imageUrl, actionUrl: $actionUrl, userId: $userId, userIds: $userIds, isGlobal: $isGlobal, isRead: $isRead, readAt: $readAt, createdBy: $createdBy, isDeleted: $isDeleted, deletedAt: $deletedAt, createdAt: $createdAt, updatedAt: $updatedAt, scheduledFor: $scheduledFor, isSent: $isSent)';
  }

  @override
  List<Object> get props {
    return [
      id,
      title,
      message,
      type,
      priority,
      data,
      imageUrl,
      actionUrl,
      userId,
      userIds,
      isGlobal,
      isRead,
      readAt,
      createdBy,
      isDeleted,
      deletedAt,
      createdAt,
      updatedAt,
      scheduledFor,
      isSent,
    ];
  }
}

class Data extends Equatable {
  final String hello;
  const Data({
    required this.hello,
  });

  Data copyWith({
    String? hello,
  }) {
    return Data(
      hello: hello ?? this.hello,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hello': hello,
    };
  }

  factory Data.fromMap(Map<String, dynamic> map) {
    return Data(
      hello: map['hello'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Data.fromJson(String source) => Data.fromMap(json.decode(source));

  @override
  String toString() => 'Data(hello: $hello)';

  @override
  List<Object> get props => [hello];
}
