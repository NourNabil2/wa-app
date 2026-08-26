import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/orders_repository.dart';

class SubmitReturnUseCase {
  final OrdersRepository repository;

  SubmitReturnUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String orderNumber,
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String? notes,
    List<String> imagePaths = const [],
  }) {
    return repository.submitReturn(
      orderNumber: orderNumber,
      orderId: orderId,
      items: items,
      reason: reason,
      notes: notes,
      imagePaths: imagePaths,
    );
  }
}
