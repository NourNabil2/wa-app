import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({int page = 1});
  Future<Either<Failure, void>> markAsRead(List<String> ids);
  Future<Either<Failure, int>> getUnreadCount();
}
