// Include all static assets compiled to Dart here and call their respective
// "register()" handlers.

import 'package:time_machine2/data/tzdb/latest.dart';
import 'package:time_machine2/data/tzdb/latest_10y.dart';
import 'package:time_machine2/data/tzdb/latest_all.dart';

import 'cultures/cultures.dart';

void registerAllStaticAssets() {
  registerCulturesAsset();
  registerTzdbData_latest();
  registerTzdbData_latest_all();
  registerTzdbData_latest_10y();
}
