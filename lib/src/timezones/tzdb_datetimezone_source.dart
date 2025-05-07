import 'package:archive/archive.dart';
import 'package:time_machine2/src/platforms/platform_io.dart';
import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:time_machine2/src/timezones/tzdb_stream_reader.dart';

class TzdbDateTimeZoneSource extends DateTimeZoneSource {
  bool _initialized = false;

  // map of date time zones that are deserialized from TZF entries on init
  final _dateTimeZones = <String, DateTimeZone>{};

  String _defaultId = "UTC";

  TzdbDateTimeZoneSource();

  Future<void> _init() async {
    if (!_initialized) {
      final xzDecoder = XZDecoder();

      final tzdbData = xzDecoder.decodeBytes(
          (await PlatformIO.local.getBinary('tzdb', 'tzdb.bin'))
              .buffer
              .asUint8List());

      final streamReader = TzdbStreamReader(tzdbData.buffer.asByteData());

      final dateTimeZones = streamReader.read();

      _dateTimeZones.clear();
      _dateTimeZones.addAll(dateTimeZones);

      _initialized = true;
    }
  }

  @override
  Future<DateTimeZone> forId(String id) async {
    await _init();

    return forCachedId(id);
  }

  @override
  DateTimeZone forCachedId(String id) {
    return _dateTimeZones[id] ?? _dateTimeZones['UTC']!;
  }

  @override
  Future<Iterable<String>> getIds() async {
    await _init();
    return _dateTimeZones.keys;
  }

  @override
  String get systemDefaultId => _defaultId;

  @override
  Future<String> get versionId => Future.sync(() => 'TZDB: 2024b');

  @override
  void setSystemDefaultId(String id) {
    _defaultId = id;
  }
}
