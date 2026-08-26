// lib/features/points/data/repositories/points_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/points_entity.dart';
import '../../domain/repositories/points_repository.dart';
import '../datasources/points_remote_datasource.dart';

class PointsRepositoryImpl implements PointsRepository {
  final PointsRemoteDataSource _remote;

  PointsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PointsSummaryEntity>> getPointsSummary() async {
    try {
      final summary = await _remote.getPointsSummary();
      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PointsHistoryEntity>>> getPointsHistory(int page) async {
    try {
      final history = await _remote.getPointsHistory(page);
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}