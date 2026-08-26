import 'package:dartz/dartz.dart';
import 'package:fastway/features/checkout/domain/entities/city_entity.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/checkout_repository.dart';

class GetCitiesUseCase {
  final CheckoutRepository _repository;
  GetCitiesUseCase(this._repository);

  Future<Either<Failure, List<CityEntity>>> call() =>
      _repository.getCities();
}

class GetCountriesUseCase {
  final CheckoutRepository _repository;
  GetCountriesUseCase(this._repository);

  Future<Either<Failure, List<CountryEntity>>> call() =>
      _repository.getCountries();
}