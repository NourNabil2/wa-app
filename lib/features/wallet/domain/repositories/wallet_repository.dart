import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletSummaryEntity>> getWalletSummary();
  Future<Either<Failure, List<WalletHistoryEntity>>> getWalletHistory(int page);
}
