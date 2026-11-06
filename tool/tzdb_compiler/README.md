# TZDB compiler

The Dart program in this folder generates Time Machine's TZDB database by downloading
the original TZDB archive from IANA and then compiling it to Time Machine's internal
binary format.

The compiler is based on NodaTime's TZDB compiler. Theoretically Time Machine's format
should be fully compatible with NodaTime's format, but using the same TZDB files between
both projects hasn't been tested.

Furthermore, Time Machine leverages compression to enhance loading performance on web
platforms, which is not supported by NodaTime.

## Windows time zone mapping

On Windows, Dart's `DateTime.timeZoneName` returns Windows zone names (such as
`AUS Eastern Standard Time`) rather than IANA abbreviations. To find the local
time zone, Time Machine uses a Windows-to-TZDB mapping that the compiler embeds in
`tzdb.bin`, as Noda Time does:

* `data/cldr/windowsZones-<cldr version>.xml`: copies of CLDR's
  [`windowsZones.xml`](https://github.com/unicode-org/cldr/blob/main/common/supplemental/windowsZones.xml).
  The compiler picks the most recent file whose TZDB version is no newer than the TZDB
  release being compiled. Use `-w <file or directory>` to pick another file or directory,
  and `--windows-override <file>` to add or override individual mappings.
* `tzdb/named_id_mapping_support.dart`: Windows zones whose standard name differs
  from their ID (for example `Coordinated Universal Time` for `UTC`).

When a new CLDR release comes out, add its `windowsZones.xml` to `data/cldr` and
rerun the compiler. On Windows, `test/windows_zones_test.dart` checks every zone in
the registry against the embedded mapping and reports any that are missing.

To regenerate the data, run from the repository root:

```
dart run tool/tzdb_compiler/main.dart
```
