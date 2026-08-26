// lib/features/legal/warehouse_cubit.dart
import 'package:fastway/core/api/base_api_services.dart';
import 'package:fastway/core/api/model/endpoints.dart';
import 'package:fastway/core/api/model/http_method.dart';
import 'package:fastway/features/legal/warehouse_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── States ────────────────────────────────────────────────────────────────────
abstract class WarehouseState {}

class WarehouseInitial extends WarehouseState {}
class WarehouseLoading extends WarehouseState {}

class WarehouseLoaded extends WarehouseState {
  final List<WarehouseEntity> warehouses;
  WarehouseLoaded(this.warehouses);
}

class WarehouseError extends WarehouseState {
  final String message;
  WarehouseError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class WarehouseCubit extends Cubit<WarehouseState> {
  final BaseApiServices _api;

  WarehouseCubit(this._api) : super(WarehouseInitial());

  Future<void> load() async {
    if (state is WarehouseLoading) return;
    emit(WarehouseLoading());
    try {
      final response = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.warehouses,
      );
      final list = response['data'] as List? ?? [];
      final warehouses = list
          .map((e) => WarehouseEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(WarehouseLoaded(warehouses));
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }
}
