import 'package:ecommerce_bloc_app/utils/utils.dart';

extension PriceParsing on int {
  String toPrice() {
    return "${UtilFormatter.formatNumber(this)}₫";
  }
}
