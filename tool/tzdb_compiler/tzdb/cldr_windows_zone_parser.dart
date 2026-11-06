import 'package:universal_io/io.dart' as io;

import 'package:xml/xml.dart' as xml;

import 'package:time_machine2/src/timezones/cldr/windows_zones.dart';

export 'package:time_machine2/src/timezones/cldr/windows_zones.dart';

// todo: internal
class CldrWindowsZonesParser {
  /// Parses a CLDR windowsZones document. [fileName] (such as
  /// 'windowsZones-49.xml') supplies the CLDR version, as in Noda Time;
  /// current CLDR files no longer contain a revision number.
  static WindowsZones parse(xml.XmlDocument document, [String fileName = '']) {
    var mapTimezones = _mapTimezones(document);
    var mapZones = _mapZones(mapTimezones);
    var windowsZonesVersion = _findVersion(document, fileName);
    var tzdbVersion = mapTimezones.getAttribute('typeVersion') ?? '';
    var windowsVersion = mapTimezones.getAttribute('otherVersion') ?? '';
    return WindowsZones(
        windowsZonesVersion, tzdbVersion, windowsVersion, mapZones);
  }

  static xml.XmlElement _mapTimezones(xml.XmlDocument document) =>
      document.rootElement
          .findElements('windowsZones')
          .first
          .findElements('mapTimezones')
          .first;

  // todo: internal
  static WindowsZones parseFile(String file) =>
      parse(_loadFile(file), file);

  static xml.XmlDocument _loadFile(String file) =>
      xml.XmlDocument.parse(io.File(file).readAsStringSync());

  static String _findVersion(xml.XmlDocument document, String fileName) {
    // The CLDR version from a file name such as windowsZones-38-1.xml (38.1).
    var baseName = fileName.split(RegExp(r'[/\\]')).last;
    if (baseName.endsWith('.xml')) {
      baseName = baseName.substring(0, baseName.length - 4);
    }
    var cldrVersion =
        baseName.replaceFirst('windowsZones-', '').replaceAll('-', '.');
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(cldrVersion)) {
      return cldrVersion;
    }

    String? revision = document.rootElement
        .findElements('version')
        .firstOrNull
        ?.getAttribute('number');
    // Recent CLDR files contain an unexpanded $Revision$ keyword.
    if (revision == null || revision == r'$Revision$') {
      return '';
    }
    String prefix = r'$Revision: ';
    if (revision.startsWith(prefix)) {
      revision = revision.substring(prefix.length);
    }
    String suffix = r' $';
    if (revision.endsWith(suffix)) {
      revision = revision.substring(0, revision.length - suffix.length);
    }
    return revision;
  }

  /*
  static List<MapZone> _mapZones2(XmlDocument document) =>
      document.Root
          .Element('windowsZones')
          .Element('mapTimezones')
          .Elements('mapZone')
          .Select((x) => new MapZone(x.Attribute('other').Value,
  x.Attribute('territory').Value,
  x.Attribute('type').Value.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries)))
      .ToList();*/

  /// <summary>
  /// Reads the input XML file for the windows mappings.
  /// </summary>
  /// <returns>A lookup of Windows time zone mappings</returns>
  static List<MapZone> _mapZones(xml.XmlElement mapTimezones) => mapTimezones
      .findElements('mapZone')
      .map((x) => MapZone(
          x.getAttribute('other')!,
          x.getAttribute('territory')!,
          x
              .getAttribute('type')!
              .split(RegExp(r'\s+'))
              .where((id) => id.isNotEmpty)
              .toList()))
      .toList();
}
