import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/points_entity.dart';
import '../repositories/points_repository.dart';

class GetPointsHistoryUseCase {
  final PointsRepository repository;

  GetPointsHistoryUseCase(this.repository);

  Future<Either<Failure, List<PointsHistoryEntity>>> call(int page) async {
    return await repository.getPointsHistory(page);
  }
}
