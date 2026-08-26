import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../cart/domain/repositories/cart_repository.dart';
import '../entities/checkout_entity.dart';

/// There is no dedicated `/checkout` data endpoint.
/// The checkout summary is derived directly from the cart (`GET /cart`).
class GetCheckoutDataUseCase {
  final CartRepository _cartRepository;

  GetCheckoutDataUseCase(this._cartRepository);

  Future<Either<Failure, CheckoutEntity>> call() async {
    final result = await _cartRepository.getCart();

    return result.map((cart) => CheckoutEntity(
      items: cart.items
          .map((item) => CheckoutItemEntity(
        id: item.id,
        name: item.name,
        imageUrl: item.imageUrl,
        price: item.price,
        quantity: item.quantity,
      ))
          .toList(),
      subtotal: cart.subtotal,
      discount: cart.discount,
      shippingCost: cart.shippingCost,
      total: cart.total,
      couponCode: cart.couponCode,
      couponDiscount: cart.couponDiscount,
    ));
  }
}