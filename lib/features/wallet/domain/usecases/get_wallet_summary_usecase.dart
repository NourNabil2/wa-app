import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletSummaryUseCase {
  final WalletRepository _repo;
  GetWalletSummaryUseCase(this._repo);

  Future<Either<Failure, WalletSummaryEntity>> call() => _repo.getWalletSummary();
}
