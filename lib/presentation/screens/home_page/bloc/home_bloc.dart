import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myezzecommerce_app/data/models/models.dart';
import 'package:myezzecommerce_app/data/repository/repository.dart';
import 'package:myezzecommerce_app/presentation/screens/home_page/bloc/bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final BannerRepository _bannerRepository = AppRepository.bannerRepository;
  final ProductRepository _productRepository = AppRepository.productRepository;

  HomeBloc() : super(HomeLoading()) {
    on<LoadHome>(_onLoadHome);
    on<RefreshHome>(_onRefreshHome);
  }

  Future<void> _onLoadHome(LoadHome event, Emitter<HomeState> emit) async {
    await _fetchHomeData(emit);
  }

  Future<void> _onRefreshHome(
      RefreshHome event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await _fetchHomeData(emit);
  }

  Future<void> _fetchHomeData(Emitter<HomeState> emit) async {
    try {
      final homeResponse = HomeResponse(
        banners: await _bannerRepository.fetchBanners(),
        categories: await _productRepository.getCategories(),
        popularProducts: await _productRepository.fetchPopularProducts(),
        discountProducts: await _productRepository.fetchDiscountProducts(),
      );
      emit(HomeLoaded(homeResponse: homeResponse));
    } catch (e) {
      emit(HomeLoadFailure(e.toString()));
    }
  }
}

class HomeResponse {
  final List<BannerModel> banners;
  final List<CategoryModel> categories;
  final List<Product> popularProducts;
  final List<Product> discountProducts;

  HomeResponse({
    required this.banners,
    required this.popularProducts,
    required this.categories,
    required this.discountProducts,
  });
}
