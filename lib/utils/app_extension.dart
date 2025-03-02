import 'package:myezzecommerce_app/utils/utils.dart';

extension PriceParsing on int {
  String toPrice() {
    return "${UtilFormatter.formatNumber(this)}₫";
  }
}
