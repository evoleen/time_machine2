![logo-dtm](https://user-images.githubusercontent.com/7284858/43960873-65f3f080-9c81-11e8-9d4d-c34c7e4cc46c.png)

The Dart Time Machine is a date and time library for [Flutter (native + web)](https://flutter.io/), and [Dart](https://www.dartlang.org/) with support for timezones, calendars, cultures, formatting and parsing.

Time Machine provides an alternative date and time API over Dart Core.

Dart's native time API is too simplistic because it only knows UTC or local time with no clear definition of time zone and no safeguards ensuring that time stamps with and without UTC flag aren't mixed up. This can easily lead to bugs if applications need to work in local time, because native Dart timestamps look the same after conversion. Applications that benefit from Time Machine are applications that need to perform tasks such as
* scheduling reminders
* displaying an object's time information (file dates, email dates, calendar dates)
* sharing data between users that work in different time zones

But Time Machine is also useful for applications that work with universal timestamps only. Its `Instant` class provides nanosecond precision and fake clocks can be used during unit testing.

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

### VM

![selection_116](https://user-images.githubusercontent.com/7284858/41519375-bcbbc818-7295-11e8-9fd0-de2e8668b105.png)

### Flutter

![selection_117](https://user-images.githubusercontent.com/7284858/41519377-bebbde82-7295-11e8-8f10-d350afd1f746.png)

## Migrating from the original time_machine package

This project is forked from [time_machine](https://github.com/Dana-Ferguson/time_machine), the original repository seems to be abandoned. Since the original package couldn't be adopted, this package had to be given a new name and is available as `time_machine2`. The following changes are required to migrate from the original package to the new package:

Change dependency in `pubspec.yaml`:
```diff
< time_machine: ^0.9.17
> time_machine2: ^0.10.1
```

Change import statements:
```diff
< import 'package:time_machine/time_machine.dart';
> import 'package:time_machine2/time_machine2.dart';
- import 'package:time_machine2/time_machine_text_patterns.dart'; 
```

The text pattern library has been merged into the main library for better visibility and to avoid too much clutter in the import statements.

Change of asset declarations in `pubspec.yaml` (only required for Flutter):
```yaml
flutter:
  assets:
    - packages/time_machine2/data/cultures/cultures.bin
    - packages/time_machine2/data/tzdb/latest_10y.tzf
    - packages/time_machine2/data/tzdb/latest_all.tzf
    - packages/time_machine2/data/tzdb/latest.tzf
```

### Time zone DB and culture DB asset handling

Time Machine requires access to a time zone database as well as a culture database containing date and time format patterns. Flutter provides a (somewhat awkward) asset management system while Dart doesn't provide any mechanism for package-specific assets at all.

In order to work on all platforms seamlessly without requiring too much package-specific configuration, the following strategy is used:

- *Flutter Native:* Assets must be listed in `pubspec.yaml` (see [here](#flutter)) and will be bundled with the binary. `TimeMachine.initialize()`  requires the application's `rootBundle` as parameter.
- *Flutter Web:* Assets must be listed in `pubspec.yaml` (see [here](#flutter)) and will be retrieved through Flutter's service worker. These are additional HTTP requests executed during `TimeMachine.initialize()`. The data will be cached by the service worker so that subsequent reloads of the application will load the assets from the cache. `TimeMachine.initialize()`  requires the application's `rootBundle` as parameter.
- *Dart only:* Assets will be compiled to code and embedded directly into the binary. This increases the size of the binary slightly but makes the entire package self-contained without additional configuration.

Time Machine currently ships three versions of the time zone database but only uses one. #23 tracks an enhancement that would allow to specify which version to use. Each version differs in size, which would enable faster loading when deployed with Flutter Web.


### Web (Dart2JS and DDC)

![selection_118](https://user-images.githubusercontent.com/7284858/41519378-c058d6a0-7295-11e8-845d-6782f1e7cbbe.png)

All unit tests pass on DartVM and DartWeb (just _Chrome_ at this time).
Tests have been run on preview versions of Dart2,
but the focus is on DartStable, and they are not run before every pub publish.
The public API is stabilizing -- mostly focusing on taking C# idiomatic code
and making it Dart idiomatic code, so I wouldn't expect any over zealous changes.
This is a preview release -- but, I'd feel comfortable using it. (_Author Stamp of Approval!_)

Documentation was ported, but some things changed for Dart and the documentation is being slowly updated (and we need
an additional automated formatting pass).

Don't use any functions annotated with `@internal`. As of v0.3 you should not find any, but if you do, let me know.

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

### Flutter Specific Notes

You'll need this entry in your pubspec.yaml.

```yaml
# The following section is specific to Flutter.
flutter:
  assets:
    - packages/time_machine2/data/cultures/cultures.bin
    - packages/time_machine2/data/tzdb/latest_10y.tzf
    - packages/time_machine2/data/tzdb/latest_all.tzf
    - packages/time_machine2/data/tzdb/latest.tzf
```

Your initialization function will look like this:
```dart
import 'package:flutter/services.dart';

WidgetsFlutterBinding.ensureInitialized();

// TimeMachine discovers your TimeZone heuristically (it's actually pretty fast).
await TimeMachine.initialize({'rootBundle': rootBundle});
```

Once flutter gets [`Isolate.resolvePackageUri`](https://github.com/flutter/flutter/issues/14815) functionality,
we'll be able to merge VM and the Flutter code paths and no asset entry and no special import will be required.
It would look just like the VM example.

Or with: https://pub.dartlang.org/packages/flutter_native_timezone

```dart
import 'package:flutter/services.dart';

// you can get Timezone information directly from the native interface with flutter_native_timezone
await TimeMachine.initialize({
  'rootBundle': rootBundle,
  'timeZone': await Timezone.getLocalTimezone(),
});
```

### DDC Specific Notes

`toString` on many of the classes will not propagate `patternText` and `culture` parameters.
`Instant` and `ZonedDateTime` currently have `toStringDDC` functions available to remedy this.

This also works:

```dart
dynamic foo = new Foo();
var foo = new Foo() as dynamic;
(foo as dynamic).toString(patternText, culture);
```

We learned in [Issue:33876](https://github.com/dart-lang/sdk/issues/33876) that `dynamic` code uses a different flow path.
Wrapping your code as dynamic will allow `toString()` to work normally. It will unfortunately ruin your intellisense.

See [Issue:33876](https://github.com/dart-lang/sdk/issues/33876) for more information. The [fix](https://dart-review.googlesource.com/c/sdk/+/65282)
exists, now we just wait for it to hit a live build.

`toStringDDC` instead of `toStringFormatted` to attempt to get a negative
[contagion](https://engineering.riotgames.com/news/taxonomy-tech-debt) coefficient. If you are writing on DartStable today
and you need some extra string support because of this bug, let me know.

_Update_: Dart 2.0 stable did not launch with the fix. Stable release windows are 6 weeks.
Hopefully we get the fix in the next release (second half of September).
