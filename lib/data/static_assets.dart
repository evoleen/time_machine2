// Include all static assets compiled to Dart here and call their respective
// "register()" handlers.

import 'package:time_machine2/data/tzdb/tzdb.dart';
import 'package:time_machine2/data/tzdb/tzdb_common.dart';
import 'package:time_machine2/data/tzdb/tzdb_common_10y.dart';

import 'cultures/cultures.dart';

void registerAllStaticAssets() {
  registerCulturesAsset();
  registerTzdbData_tzdb();
  registerTzdbData_tzdb_common();
  registerTzdbData_tzdb_common_10y();
}
