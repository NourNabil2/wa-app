import 'package:dartz/dartz.dart';
import 'package:fastway/core/errors/failures.dart';
import '../entities/announcement_entity.dart';

abstract class AnnouncementsRepository {
  Future<Either<Failure, List<AnnouncementEntity>>> getAnnouncements();
}
