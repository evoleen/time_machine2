// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:time_machine/src/timezones/tzdb_location.dart';
import 'package:time_machine/src/timezones/tzdb_location_database.dart';
import 'zicfile.dart';

const commonLocations = [
  'Africa/Abidjan',
  'Africa/Accra',
  'Africa/Addis_Ababa',
  'Africa/Algiers',
  'Africa/Asmara',
  'Africa/Bamako',
  'Africa/Bangui',
  'Africa/Banjul',
  'Africa/Bissau',
  'Africa/Blantyre',
  'Africa/Brazzaville',
  'Africa/Bujumbura',
  'Africa/Cairo',
  'Africa/Casablanca',
  'Africa/Ceuta',
  'Africa/Conakry',
  'Africa/Dakar',
  'Africa/Dar_es_Salaam',
  'Africa/Djibouti',
  'Africa/Douala',
  'Africa/El_Aaiun',
  'Africa/Freetown',
  'Africa/Gaborone',
  'Africa/Harare',
  'Africa/Johannesburg',
  'Africa/Juba',
  'Africa/Kampala',
  'Africa/Khartoum',
  'Africa/Kigali',
  'Africa/Kinshasa',
  'Africa/Lagos',
  'Africa/Libreville',
  'Africa/Lome',
  'Africa/Luanda',
  'Africa/Lubumbashi',
  'Africa/Lusaka',
  'Africa/Malabo',
  'Africa/Maputo',
  'Africa/Maseru',
  'Africa/Mbabane',
  'Africa/Mogadishu',
  'Africa/Monrovia',
  'Africa/Nairobi',
  'Africa/Ndjamena',
  'Africa/Niamey',
  'Africa/Nouakchott',
  'Africa/Ouagadougou',
  'Africa/Porto-Novo',
  'Africa/Sao_Tome',
  'Africa/Tripoli',
  'Africa/Tunis',
  'Africa/Windhoek',
  'America/Adak',
  'America/Anchorage',
  'America/Anguilla',
  'America/Antigua',
  'America/Araguaina',
  'America/Argentina/Buenos_Aires',
  'America/Argentina/Catamarca',
  'America/Argentina/Cordoba',
  'America/Argentina/Jujuy',
  'America/Argentina/La_Rioja',
  'America/Argentina/Mendoza',
  'America/Argentina/Rio_Gallegos',
  'America/Argentina/Salta',
  'America/Argentina/San_Juan',
  'America/Argentina/San_Luis',
  'America/Argentina/Tucuman',
  'America/Argentina/Ushuaia',
  'America/Aruba',
  'America/Asuncion',
  'America/Atikokan',
  'America/Bahia',
  'America/Bahia_Banderas',
  'America/Barbados',
  'America/Belem',
  'America/Belize',
  'America/Blanc-Sablon',
  'America/Boa_Vista',
  'America/Bogota',
  'America/Boise',
  'America/Cambridge_Bay',
  'America/Campo_Grande',
  'America/Cancun',
  'America/Caracas',
  'America/Cayenne',
  'America/Cayman',
  'America/Chicago',
  'America/Chihuahua',
  'America/Costa_Rica',
  'America/Creston',
  'America/Cuiaba',
  'America/Curacao',
  'America/Danmarkshavn',
  'America/Dawson',
  'America/Dawson_Creek',
  'America/Denver',
  'America/Detroit',
  'America/Dominica',
  'America/Edmonton',
  'America/Eirunepe',
  'America/El_Salvador',
  'America/Fortaleza',
  'America/Glace_Bay',
  'America/Godthab',
  'America/Goose_Bay',
  'America/Grand_Turk',
  'America/Grenada',
  'America/Guadeloupe',
  'America/Guatemala',
  'America/Guayaquil',
  'America/Guyana',
  'America/Halifax',
  'America/Havana',
  'America/Hermosillo',
  'America/Indiana/Indianapolis',
  'America/Indiana/Knox',
  'America/Indiana/Marengo',
  'America/Indiana/Petersburg',
  'America/Indiana/Tell_City',
  'America/Indiana/Vevay',
  'America/Indiana/Vincennes',
  'America/Indiana/Winamac',
  'America/Inuvik',
  'America/Iqaluit',
  'America/Jamaica',
  'America/Juneau',
  'America/Kentucky/Louisville',
  'America/Kentucky/Monticello',
  'America/Kralendijk',
  'America/La_Paz',
  'America/Lima',
  'America/Los_Angeles',
  'America/Lower_Princes',
  'America/Maceio',
  'America/Managua',
  'America/Manaus',
  'America/Marigot',
  'America/Martinique',
  'America/Matamoros',
  'America/Mazatlan',
  'America/Menominee',
  'America/Merida',
  'America/Metlakatla',
  'America/Mexico_City',
  'America/Miquelon',
  'America/Moncton',
  'America/Monterrey',
  'America/Montevideo',
  'America/Montreal',
  'America/Montserrat',
  'America/Nassau',
  'America/New_York',
  'America/Nipigon',
  'America/Nome',
  'America/Noronha',
  'America/North_Dakota/Beulah',
  'America/North_Dakota/Center',
  'America/North_Dakota/New_Salem',
  'America/Ojinaga',
  'America/Panama',
  'America/Pangnirtung',
  'America/Paramaribo',
  'America/Phoenix',
  'America/Port-au-Prince',
  'America/Port_of_Spain',
  'America/Porto_Velho',
  'America/Puerto_Rico',
  'America/Rainy_River',
  'America/Rankin_Inlet',
  'America/Recife',
  'America/Regina',
  'America/Resolute',
  'America/Rio_Branco',
  'America/Santa_Isabel',
  'America/Santarem',
  'America/Santiago',
  'America/Santo_Domingo',
  'America/Sao_Paulo',
  'America/Scoresbysund',
  'America/Sitka',
  'America/St_Barthelemy',
  'America/St_Johns',
  'America/St_Kitts',
  'America/St_Lucia',
  'America/St_Thomas',
  'America/St_Vincent',
  'America/Swift_Current',
  'America/Tegucigalpa',
  'America/Thule',
  'America/Thunder_Bay',
  'America/Tijuana',
  'America/Toronto',
  'America/Tortola',
  'America/Vancouver',
  'America/Whitehorse',
  'America/Winnipeg',
  'America/Yakutat',
  'America/Yellowknife',
  'Antarctica/Casey',
  'Antarctica/Davis',
  'Antarctica/DumontDUrville',
  'Antarctica/Macquarie',
  'Antarctica/Mawson',
  'Antarctica/McMurdo',
  'Antarctica/Palmer',
  'Antarctica/Rothera',
  'Antarctica/Syowa',
  'Antarctica/Troll',
  'Antarctica/Vostok',
  'Arctic/Longyearbyen',
  'Asia/Aden',
  'Asia/Almaty',
  'Asia/Amman',
  'Asia/Anadyr',
  'Asia/Aqtau',
  'Asia/Aqtobe',
  'Asia/Ashgabat',
  'Asia/Baghdad',
  'Asia/Bahrain',
  'Asia/Baku',
  'Asia/Bangkok',
  'Asia/Beirut',
  'Asia/Bishkek',
  'Asia/Brunei',
  'Asia/Chita',
  'Asia/Choibalsan',
  'Asia/Colombo',
  'Asia/Damascus',
  'Asia/Dhaka',
  'Asia/Dili',
  'Asia/Dubai',
  'Asia/Dushanbe',
  'Asia/Gaza',
  'Asia/Hebron',
  'Asia/Ho_Chi_Minh',
  'Asia/Hong_Kong',
  'Asia/Hovd',
  'Asia/Irkutsk',
  'Asia/Jakarta',
  'Asia/Jayapura',
  'Asia/Jerusalem',
  'Asia/Kabul',
  'Asia/Kamchatka',
  'Asia/Karachi',
  'Asia/Kathmandu',
  'Asia/Khandyga',
  'Asia/Kolkata',
  'Asia/Krasnoyarsk',
  'Asia/Kuala_Lumpur',
  'Asia/Kuching',
  'Asia/Kuwait',
  'Asia/Macau',
  'Asia/Magadan',
  'Asia/Makassar',
  'Asia/Manila',
  'Asia/Muscat',
  'Asia/Nicosia',
  'Asia/Novokuznetsk',
  'Asia/Novosibirsk',
  'Asia/Omsk',
  'Asia/Oral',
  'Asia/Phnom_Penh',
  'Asia/Pontianak',
  'Asia/Pyongyang',
  'Asia/Qatar',
  'Asia/Qyzylorda',
  'Asia/Rangoon',
  'Asia/Riyadh',
  'Asia/Sakhalin',
  'Asia/Samarkand',
  'Asia/Seoul',
  'Asia/Shanghai',
  'Asia/Singapore',
  'Asia/Srednekolymsk',
  'Asia/Taipei',
  'Asia/Tashkent',
  'Asia/Tbilisi',
  'Asia/Tehran',
  'Asia/Thimphu',
  'Asia/Tokyo',
  'Asia/Ulaanbaatar',
  'Asia/Urumqi',
  'Asia/Ust-Nera',
  'Asia/Vientiane',
  'Asia/Vladivostok',
  'Asia/Yakutsk',
  'Asia/Yekaterinburg',
  'Asia/Yerevan',
  'Atlantic/Azores',
  'Atlantic/Bermuda',
  'Atlantic/Canary',
  'Atlantic/Cape_Verde',
  'Atlantic/Faroe',
  'Atlantic/Madeira',
  'Atlantic/Reykjavik',
  'Atlantic/South_Georgia',
  'Atlantic/St_Helena',
  'Atlantic/Stanley',
  'Australia/Adelaide',
  'Australia/Brisbane',
  'Australia/Broken_Hill',
  'Australia/Currie',
  'Australia/Darwin',
  'Australia/Eucla',
  'Australia/Hobart',
  'Australia/Lindeman',
  'Australia/Lord_Howe',
  'Australia/Melbourne',
  'Australia/Perth',
  'Australia/Sydney',
  'Canada/Atlantic',
  'Canada/Central',
  'Canada/Eastern',
  'Canada/Mountain',
  'Canada/Newfoundland',
  'Canada/Pacific',
  'Europe/Amsterdam',
  'Europe/Andorra',
  'Europe/Athens',
  'Europe/Belgrade',
  'Europe/Berlin',
  'Europe/Bratislava',
  'Europe/Brussels',
  'Europe/Bucharest',
  'Europe/Budapest',
  'Europe/Busingen',
  'Europe/Chisinau',
  'Europe/Copenhagen',
  'Europe/Dublin',
  'Europe/Gibraltar',
  'Europe/Guernsey',
  'Europe/Helsinki',
  'Europe/Isle_of_Man',
  'Europe/Istanbul',
  'Europe/Jersey',
  'Europe/Kaliningrad',
  'Europe/Kyiv',
  'Europe/Lisbon',
  'Europe/Ljubljana',
  'Europe/London',
  'Europe/Luxembourg',
  'Europe/Madrid',
  'Europe/Malta',
  'Europe/Mariehamn',
  'Europe/Minsk',
  'Europe/Monaco',
  'Europe/Moscow',
  'Europe/Oslo',
  'Europe/Paris',
  'Europe/Podgorica',
  'Europe/Prague',
  'Europe/Riga',
  'Europe/Rome',
  'Europe/Samara',
  'Europe/San_Marino',
  'Europe/Sarajevo',
  'Europe/Simferopol',
  'Europe/Skopje',
  'Europe/Sofia',
  'Europe/Stockholm',
  'Europe/Tallinn',
  'Europe/Tirane',
  'Europe/Uzhgorod',
  'Europe/Vaduz',
  'Europe/Vatican',
  'Europe/Vienna',
  'Europe/Vilnius',
  'Europe/Volgograd',
  'Europe/Warsaw',
  'Europe/Zagreb',
  'Europe/Zaporozhye',
  'Europe/Zurich',
  'GMT',
  'Indian/Antananarivo',
  'Indian/Chagos',
  'Indian/Christmas',
  'Indian/Cocos',
  'Indian/Comoro',
  'Indian/Kerguelen',
  'Indian/Mahe',
  'Indian/Maldives',
  'Indian/Mauritius',
  'Indian/Mayotte',
  'Indian/Reunion',
  'Pacific/Apia',
  'Pacific/Auckland',
  'Pacific/Chatham',
  'Pacific/Chuuk',
  'Pacific/Easter',
  'Pacific/Efate',
  'Pacific/Enderbury',
  'Pacific/Fakaofo',
  'Pacific/Fiji',
  'Pacific/Funafuti',
  'Pacific/Galapagos',
  'Pacific/Gambier',
  'Pacific/Guadalcanal',
  'Pacific/Guam',
  'Pacific/Honolulu',
  'Pacific/Johnston',
  'Pacific/Kiritimati',
  'Pacific/Kosrae',
  'Pacific/Kwajalein',
  'Pacific/Majuro',
  'Pacific/Marquesas',
  'Pacific/Midway',
  'Pacific/Nauru',
  'Pacific/Niue',
  'Pacific/Norfolk',
  'Pacific/Noumea',
  'Pacific/Pago_Pago',
  'Pacific/Palau',
  'Pacific/Pitcairn',
  'Pacific/Pohnpei',
  'Pacific/Port_Moresby',
  'Pacific/Rarotonga',
  'Pacific/Saipan',
  'Pacific/Tahiti',
  'Pacific/Tarawa',
  'Pacific/Tongatapu',
  'Pacific/Wake',
  'Pacific/Wallis',
  'US/Alaska',
  'US/Arizona',
  'US/Central',
  'US/Eastern',
  'US/Hawaii',
  'US/Mountain',
  'US/Pacific',
  'UTC'
];

const int _maxMillisecondsSinceEpoch = 8640000000000000;
const int _maxSecondsSinceEpoch = 8640000000000;

class FilterReport {
  int originalLocationsCount = 0;
  int originalTransitionsCount = 0;
  int newLocationsCount = 0;
  int newTransitionsCount = 0;
}

class FilteredLocationDatabase {
  final TzdbLocationDatabase db;
  final FilterReport report;

  FilteredLocationDatabase(this.db, this.report);
}

FilteredLocationDatabase filterTimeZoneData(TzdbLocationDatabase db,
    {int dateFrom = -_maxMillisecondsSinceEpoch,
    int dateTo = _maxMillisecondsSinceEpoch,
    List<String> locations = const []}) {
  final report = FilterReport();
  final result = TzdbLocationDatabase();

  final locationsSet = HashSet<String>.from(locations);

  report.originalLocationsCount = db.locations.length;

  for (final l in db.locations.values) {
    if (locationsSet.isNotEmpty && !locationsSet.contains(l.name)) {
      continue;
    }

    final transitionsCount = l.transitionAt.length;
    report.originalTransitionsCount += transitionsCount;

    final newTransitionAt = <int>[];
    final newTransitionZone = <int>[];

    if (transitionsCount == 0) {
      result.add(
          TzdbLocation(l.name, newTransitionAt, newTransitionZone, l.zones));
      continue;
    }

    var i = 0;

    while (i < transitionsCount && dateFrom > l.transitionAt[i]) {
      i++;
    }

    if (i < transitionsCount) {
      newTransitionAt.add(-_maxMillisecondsSinceEpoch);
      newTransitionZone.add(i == 0 ? 0 : l.transitionZone[i - 1]);
      report.newTransitionsCount++;

      while (i < transitionsCount && l.transitionAt[i] <= dateTo) {
        // Some transitions are listed as transitions into the same zone.
        // In that case, we need to skip this transition so that isoLocalEnd
        // reports the correct end of the current zone. (see misc bug "Tbilisi" test)
        if (l.transitionZone[i] == newTransitionZone.last) {
          i++;
          continue;
        }

        newTransitionAt.add(l.transitionAt[i]);
        newTransitionZone.add(l.transitionZone[i]);
        i++;
        report.newTransitionsCount++;
      }
    } else {
      newTransitionAt.add(-_maxMillisecondsSinceEpoch);
      newTransitionZone.add(l.transitionZone[i - 1]);
    }

    result
        .add(TzdbLocation(l.name, newTransitionAt, newTransitionZone, l.zones));
    report.newLocationsCount++;
  }

  return FilteredLocationDatabase(result, report);
}

/// Convert [ZicFileLocation] to [TzdbLocation]
TzdbLocation tzfileLocationToNativeLocation(ZicFileLocation loc) {
  // convert to milliseconds
  final transitionAt = loc.transitionAt
      .map((i) =>
          (i < -_maxSecondsSinceEpoch) ? -_maxMillisecondsSinceEpoch : i * 1000)
      .toList();

  final zones = <TzdbTimeZone>[];

  for (final z in loc.zones) {
    zones.add(TzdbTimeZone(z.offset * 1000,
        isDst: z.isDst, abbreviation: loc.abbreviations[z.abbreviationIndex]));
  }

  return TzdbLocation(loc.name, transitionAt, loc.transitionZone, zones);
}
