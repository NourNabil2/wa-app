import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fastway/features/home/data/datasources/products_remote_datasource.dart';
import 'package:fastway/features/home/data/model/product_model.dart';
import 'package:fastway/features/home/domain/entities/product_entity.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final ProductsRemoteDataSource _remote;
  Timer? _debounce;
  
  String _currentQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;
  List<ProductEntity> _products = [];
  int _total = 0;

  SearchCubit(this._remote) : super(SearchInitial());

  bool _isLoadingMore = false;

  void search(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().isEmpty) {
        _currentQuery = '';
        _currentPage = 1;
        _hasMore = true;
        _products = [];
        _total = 0;
        emit(SearchInitial());
        return;
      }

      _currentQuery = query;
      _currentPage = 1;
      _hasMore = true;
      _products = [];
      _total = 0;
      emit(SearchLoading());

      try {
        final data = await _remote.searchProducts(_currentQuery, page: _currentPage);
        
        final List<ProductEntity> newProducts = (data['products'] as List?)
            ?.map((e) => ProductModel.fromJson(e))
            .toList() ?? [];
            
        final total = data['total'] as int? ?? 0;
        final currentPage = data['current_page'] as int? ?? 1;
        final lastPage = data['last_page'] as int? ?? 1;
        
        _products.addAll(newProducts);
        _total = total;
        _hasMore = currentPage < lastPage;
        
        emit(SearchLoaded(
          products: List.from(_products),
          total: _total,
          page: _currentPage,
          hasMore: _hasMore,
        ));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });
  }

  Future<void> loadMore() async {
    if (state is SearchLoaded && _hasMore && !_isLoadingMore) {
      _isLoadingMore = true;
      _currentPage++;
      
      try {
        final data = await _remote.searchProducts(_currentQuery, page: _currentPage);
        
        final List<ProductEntity> newProducts = (data['products'] as List?)
            ?.map((e) => ProductModel.fromJson(e))
            .toList() ?? [];
            
        final total = data['total'] as int? ?? 0;
        final currentPage = data['current_page'] as int? ?? 1;
        final lastPage = data['last_page'] as int? ?? 1;
        
        _products.addAll(newProducts);
        _total = total;
        _hasMore = currentPage < lastPage;
        
        emit(SearchLoaded(
          products: List.from(_products),
          total: _total,
          page: _currentPage,
          hasMore: _hasMore,
        ));
      } catch (e) {
        _currentPage--;
      } finally {
        _isLoadingMore = false;
      }
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
