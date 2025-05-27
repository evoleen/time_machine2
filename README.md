![logo-dtm](https://user-images.githubusercontent.com/7284858/43960873-65f3f080-9c81-11e8-9d4d-c34c7e4cc46c.png)

## Table of Contents
- [Overview](#overview)
- [Example Code](#example-code)
- [Installation](#installation)
  - [Flutter](#flutter)
  - [Dart](#dart)
  - [Migration Guide](#migrating-from-the-original-time_machine-package)
- [Asset Handling](#time-zone-db-and-culture-db-asset-handling)

## Overview

The Dart Time Machine is a date and time library for [Flutter (native + web)](https://flutter.io/), and [Dart](https://www.dartlang.org/) with support for time zones, calendars, cultures, formatting and parsing. Time Machine provides an alternative date and time API over Dart Core and includes an embedded copy of the [IANA time zone database](https://www.iana.org/time-zones), eliminating the need to include additional packages.

Current TZDB version: 2025b

Time Machine's type system makes working with date and time a breeze:

```dart
final now = Instant.now();
final tomorrow = now.add(Time(days: 1));

// Time Machine supports "inexact" durations, such as a month (28, 29, 30 or 31 days)
final threeMonths = Period(months: 3);

// The line below calculates the exact same date and time for "in three months"
// 2025-02-15 12:00 --> 2025-05-15 12:00
// This is more complicated than it looks, because it will take different
// month lengths, DST transitions and even leap years into account!
final sameDateNextQuarter = now.inLocalZone().localDateTime + threeMonths;

// This line does the same, but with a fixed window of 90 days.
// Note that Time Machine's API ensures that the code tells you exactly
// what happens, advancing exactly 90 days (24 * 90 hours) on the calendar.
final nextQuarter = now + Time(days: 90);
```

Time Machine is a port of NodaTime. The original author [published a great article](https://blog.nodatime.org/2011/08/what-wrong-with-datetime-anyway.html) about why a different date/time API is necessary. (the article talks about .NET but it applies to Dart/Flutter just the same) Dart's native time API is too simplistic because it only knows UTC or local time with no clear definition of time zone and no safeguards ensuring that time stamps with and without UTC flag aren't mixed up. This can easily lead to non-obvious bugs.

You are benefitting the most from Time Machine if you want to
* have awesome, type-safe access to date and time
* schedule reminders
* display an object's time information (file dates, email dates, calendar dates)
* share data between users that work in different time zones
* perform any arithmetic with dates and times without worrying about calendar logic, such as months with different number of days, varying day lengths due to DST transitions, etc.

Time Machine is also useful for applications that only work with universal timestamps. Its `Instant` class provides nanosecond precision and fake clocks can be used during unit testing.

**Time Machine API**
* Time - an amount of time with nanosecond precision
* Instant - a unique point on the UTC timeline
* LocalTime - the time on the clock
* LocalDate - the date on the calendar
* LocalDateTime - a location on the clock and calendar
* Period - amount of time on the clock and calendar
* Offset - the timezone offset from the UTC timeline
* DateTimeZone - a mapping between the UTC timeline, and clock and calendar locations
* ZonedDateTime - a unique point on the UTC timeline and a location on the clock and calendar
* Culture - formatting and parsing rules specific to a locale

**Time Machine's Goals**
* Flexibility - multiple representations of time to fit different use cases
* Consistency - works the same across all platforms
* Testable - easy to test your date and time dependent code
* Clarity - clear, concise, and intuitive
* Easy - the library should do the hard things for you

The last two/three are generic library goals.

Time Machine is a port of [Noda Time](https://www.nodatime.org). The original version of this package was created by [Dana Ferguson](https://github.com/Dana-Ferguson/time_machine).

### Example Code:

```dart
// Sets up timezone and culture information
await TimeMachine.initialize();
print('Hello, ${DateTimeZone.local} from the Dart Time Machine!\n');

var tzdb = await DateTimeZoneProviders.tzdb;
var paris = await tzdb["Europe/Paris"];

var now = Instant.now();

print('Basic');
print('UTC Time: $now');
print('Local Time: ${now.inLocalZone()}');
print('Paris Time: ${now.inZone(paris)}\n');

print('Formatted');
print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm')}');
print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm')}\n');

var french = await Cultures.getCulture('fr-FR');
print('Formatted and French ($french)');
print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm', french)}');
print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm', french)}\n');

print('Parse French Formatted ZonedDateTime');

// without the 'z' parsing will be forced to interpret the timezone as UTC
var localText = now
    .inLocalZone()
    .toString('dddd yyyy-MM-dd HH:mm z', french);

var localClone = ZonedDateTimePattern
    .createWithCulture('dddd yyyy-MM-dd HH:mm z', french)
    .parse(localText);

print(localClone.value);
```

## Installation

### Flutter

Include the package in your `pubspec.yaml` and initialize it before using it, ideally early in `main.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:time_machine2/time_machine2.dart';

WidgetsFlutterBinding.ensureInitialized();

// TimeMachine discovers your TimeZone heuristically (it's actually pretty fast).
await TimeMachine.initialize({'rootBundle': rootBundle});
```

### Dart

Include the package in your `pubspec.yaml` and initialize it before using it, ideally early in `main.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:time_machine2/time_machine2.dart';

WidgetsFlutterBinding.ensureInitialized();

// TimeMachine discovers your TimeZone heuristically (it's actually pretty fast).
await TimeMachine.initialize();
```

### Migrating from the original `time_machine` package

This project is forked from [time_machine](https://github.com/Dana-Ferguson/time_machine), the original repository seems to be abandoned. Since the original package couldn't be adopted, this package had to be given a new name and is available as `time_machine2`. The following changes are required to migrate from the original package to the new package:

Change dependency in `pubspec.yaml`:
```diff
< time_machine: ^0.9.17
> time_machine2: ^0.12.1
```

Change import statements:
```diff
< import 'package:time_machine/time_machine.dart';
> import 'package:time_machine2/time_machine2.dart';
- import 'package:time_machine2/time_machine_text_patterns.dart'; 
```

The text pattern library has been merged into the main library for better visibility and to avoid too much clutter in the import statements.

Change of asset declarations in `pubspec.yaml` (only required for Flutter): Remove all asset declarations related to Time Machine. The library now ensures that assets are available on the library level. For pure Dart, assets are compiled into the binary and for Flutter the asset definition is already contained in the library's `pubspec.yaml` file.

## Time zone DB and culture DB asset handling

Time Machine includes the [IANA Time Zone Database](https://www.iana.org/time-zones) and date/time patterns from [Unicode CLDR](https://cldr.unicode.org/). These assets are XZ compressed and have comparably small size (32kb for the full TZDB and 47kb for date/time patterns).

In order to work on all platforms seamlessly without requiring too much package-specific configuration, the following strategy is used:

- *Flutter Native:* TZDB and date/time patterns are bundled as Flutter assets. `TimeMachine.initialize()`  requires the application's `rootBundle` as parameter to locate them and will load them using the platform's native asset loaders.
- *Flutter Web:* TZDB and date/time patterns are bundled as Flutter assets and will be retrieved through Flutter's service worker. This ensures that the main Flutter binary stays small and the time to show the UI is reduced. The requests through the service worker are additional HTTP requests during `TimeMachine.initialize()`. The data can be cached by the service worker so that subsequent reloads of the application may load the assets from the cache. `TimeMachine.initialize()` requires the application's `rootBundle` as parameter in order to determine the server path of the asset files.
- *Dart only:* TZDB and date/time patterns will be compiled to code and embedded directly into the binary. This increases the size of the binary slightly but makes the entire package self-contained without additional configuration.

How to use the `rootBundle` parameter:
```dart
TimeMachine.initialize({
  // only needed for Flutter
  'rootBundle': rootBundle,
});
```

## Todos before v1

Todo (before v1):
 - [x] Port Noda Time
 - [x] Unit tests passing in DartVM
 - [ ] Dartification of the API
   - [X] First pass style updates
   - [X] Second pass ergonomics updates
   - [X] Synchronous TZDB timezone provider
   - [ ] Review all I/O and associated classes and their structure
   - [ ] Simplify the API and make the best use of named constructors
 - [X] Non-Gregorian/Julian calendar systems
 - [X] Text formatting and Parsing
 - [X] Remove XML tags from documentation and format them for pub (*human second pass still needed*)
 - [X] Implement Dart4Web features
 - [X] Unit tests passing in DartWeb
 - [ ] Fix DartDoc Formatting
 - [ ] Create simple website with examples (at minimal a good set of examples under the examples directory)

External data: Timezones (TZDB via Noda Time) and Culture (ICU via BCL) are produced by a C# tool that is not
included in this repository. The goal is to port all this functionality to Dart, the initial tool was created for
bootstrapping -- and guaranteeing that our data is exactly the same thing that Noda Time would see (to ease porting).

Future Todo:
 - [X] Produce our own TSDB files
 - [X] Produce our own Culture files
 - [ ] Benchmarking & Optimizing Library for Dart
