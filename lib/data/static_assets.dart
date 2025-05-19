// Include all static assets compiled to Dart here and call their respective
// "register()" handlers.

import 'cultures/cultures.dart';
import 'tzdb/tzdb.dart';

void registerAllStaticAssets() {
  registerCulturesAsset();
  registerTzdbAsset();
}
