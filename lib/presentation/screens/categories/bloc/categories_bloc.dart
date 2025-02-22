import 'dart:async';
import 'package:ecommerce_bloc_app/data/models/models.dart';
import 'package:ecommerce_bloc_app/data/repository/app_repository.dart';
import 'package:ecommerce_bloc_app/data/repository/repository.dart';
import 'package:ecommerce_bloc_app/presentation/screens/categories/bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final ProductRepository _productRepository = AppRepository.productRepository;
  late CategoryModel _category;
  String _currKeyword = "";
  ProductSortOption _currSortOption = ProductSortOption();

  CategoriesBloc() : super(DisplayListProducts.loading()) {
    on<OpenScreen>(_onOpenScreen);
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounceTransformer(Duration(milliseconds: 300)),
    );
    on<SortOptionsChanged>(_onSortOptionsChanged);
    on<ClickIconSort>((event, emit) =>
        emit(OpenSortOption(isOpen: true, currSortOption: _currSortOption)));
    on<CloseSortOption>((event, emit) =>
        emit(OpenSortOption(isOpen: false, currSortOption: _currSortOption)));
    on<ClickIconSearch>(
        (event, emit) => emit(UpdateToolbarState(showSearchField: true)));
    on<ClickCloseSearch>(_onClickCloseSearch);
  }

  EventTransformer<T> debounceTransformer<T>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
  }

  Future<void> _onOpenScreen(
      OpenScreen event, Emitter<CategoriesState> emit) async {
    emit(UpdateToolbarState(showSearchField: false));
    try {
      _category = event.category;
      emit(DisplayListProducts.data(await fetchProducts()));
    } catch (e) {
      emit(DisplayListProducts.error(e.toString()));
    }
  }

  Future<void> _onSearchQueryChanged(
      SearchQueryChanged event, Emitter<CategoriesState> emit) async {
    emit(DisplayListProducts.loading());
    try {
      _currKeyword = event.keyword;
      emit(DisplayListProducts.data(await fetchProducts()));
    } catch (e) {
      emit(DisplayListProducts.error(e.toString()));
    }
  }

  Future<void> _onSortOptionsChanged(
      SortOptionsChanged event, Emitter<CategoriesState> emit) async {
    _currSortOption = event.productSortOption;
    emit(UpdateToolbarState(showSearchField: false));
    emit(DisplayListProducts.data(await fetchProducts()));
  }

  Future<void> _onClickCloseSearch(
      ClickCloseSearch event, Emitter<CategoriesState> emit) async {
    emit(UpdateToolbarState(showSearchField: false));
    emit(DisplayListProducts.data(await fetchProducts()));
  }

  Future<PriceSegment> fetchProducts() async {
    List<Product> products =
        await _productRepository.fetchProductsByCategory(_category.id);
    products = products
        .where((p) =>
            _currKeyword.isEmpty ||
            p.name.toLowerCase().contains(_currKeyword.toLowerCase()))
        .toList();
    products.sort(_mapOptionToSortMethod());

    return PriceSegment(
      productsInLowRange:
          products.where((p) => p.price <= PriceSegment.LOW_SEGMENT).toList(),
      productsInMidRange: products
          .where((p) =>
              p.price > PriceSegment.LOW_SEGMENT &&
              p.price <= PriceSegment.HIGH_SEGMENT)
          .toList(),
      productsInHighRange:
          products.where((p) => p.price > PriceSegment.HIGH_SEGMENT).toList(),
    );
  }

  int Function(Product, Product) _mapOptionToSortMethod() {
    if (_currSortOption.productSortBy == PRODUCT_SORT_BY.SOLD_QUANTITY) {
      return _currSortOption.productSortOrderModel ==
              PRODUCT_SORT_ORDER.DESCENDING
          ? sortSoldQuantityDescending
          : sortSoldQuantityAscending;
    }
    if (_currSortOption.productSortBy == PRODUCT_SORT_BY.PRICE) {
      return _currSortOption.productSortOrderModel ==
              PRODUCT_SORT_ORDER.DESCENDING
          ? sortPriceDescending
          : sortPriceAscending;
    }
    return sortSoldQuantityDescending;
  }

  int sortSoldQuantityDescending(Product a, Product b) =>
      b.soldQuantity.compareTo(a.soldQuantity);
  int sortSoldQuantityAscending(Product a, Product b) =>
      a.soldQuantity.compareTo(b.soldQuantity);
  int sortPriceDescending(Product a, Product b) => b.price.compareTo(a.price);
  int sortPriceAscending(Product a, Product b) => a.price.compareTo(b.price);
}

// Products by price segment
class PriceSegment {
  static const LOW_SEGMENT = 1000000;
  static const HIGH_SEGMENT = 4000000;

  final List<Product> productsInLowRange;
  final List<Product> productsInMidRange;
  final List<Product> productsInHighRange;

  PriceSegment({
    required this.productsInLowRange,
    required this.productsInMidRange,
    required this.productsInHighRange,
  });
}

/// Product sort options
class ProductSortOption {
  final PRODUCT_SORT_BY? productSortBy;
  final PRODUCT_SORT_ORDER productSortOrderModel;

  ProductSortOption({
    this.productSortBy,
    this.productSortOrderModel = PRODUCT_SORT_ORDER.DESCENDING,
  });

  ProductSortOption update({productSortBy, productSortOrderModel}) {
    return ProductSortOption(
      productSortBy: productSortBy ?? this.productSortBy,
      productSortOrderModel:
          productSortOrderModel ?? this.productSortOrderModel,
    );
  }

  @override
  String toString() {
    return "ProductSortOption: ${this.productSortBy}, ${this.productSortOrderModel}";
  }
}

enum PRODUCT_SORT_BY { PRICE, SOLD_QUANTITY }

enum PRODUCT_SORT_ORDER { ASCENDING, DESCENDING }
