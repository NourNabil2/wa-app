// lib/features/points/domain/usecases/get_points_summary_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/points_entity.dart';
import '../repositories/points_repository.dart';

class GetPointsSummaryUseCase {
  final PointsRepository _repository;
  GetPointsSummaryUseCase(this._repository);

  Future<Either<Failure, PointsSummaryEntity>> call() =>
      _repository.getPointsSummary();
}