import 'package:equatable/equatable.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsConnecting extends NotificationsState {
  const NotificationsConnecting();
}

class NotificationsConnected extends NotificationsState {
  const NotificationsConnected();
}

class NotificationsDisconnected extends NotificationsState {
  const NotificationsDisconnected();
}

class NotificationReceived extends NotificationsState {
  final String eventType;
  final Map<String, dynamic> data;

  const NotificationReceived({
    required this.eventType,
    required this.data,
  });

  @override
  List<Object?> get props => [eventType, data];
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError({required this.message});

  @override
  List<Object?> get props => [message];
}
