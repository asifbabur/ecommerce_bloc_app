import 'package:ecommerce_bloc_app/data/models/models.dart';

abstract class BannerRepository {
// Get all cart items
  Future<List<BannerModel>> fetchBanners();
}
