import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletHistoryUseCase {
  final WalletRepository _repo;
  GetWalletHistoryUseCase(this._repo);

  Future<Either<Failure, List<WalletHistoryEntity>>> call(int page) =>
      _repo.getWalletHistory(page);
}
