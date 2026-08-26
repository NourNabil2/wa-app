import 'package:dartz/dartz.dart';
import 'package:fastway/core/errors/exceptions.dart';
import 'package:fastway/core/errors/failures.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcements_repository.dart';
import '../datasources/announcements_remote_data_source.dart';

class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  final AnnouncementsRemoteDataSource remoteDataSource;

  AnnouncementsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AnnouncementEntity>>> getAnnouncements() async {
    try {
      final announcements = await remoteDataSource.getAnnouncements();
      return Right(announcements);
    } on ServerException {
      return const Left(ServerFailure('Failed to fetch announcements'));
    }
  }
}
