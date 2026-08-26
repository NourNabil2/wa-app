// lib/features/points/domain/repositories/points_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/points_entity.dart';

abstract class PointsRepository {
  Future<Either<Failure, PointsSummaryEntity>> getPointsSummary();
  Future<Either<Failure, List<PointsHistoryEntity>>> getPointsHistory(int page);
}