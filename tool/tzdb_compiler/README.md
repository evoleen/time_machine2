# TZDB compiler

The compiler downloads the latest [IANA Time Zone Database](http://www.iana.org/time-zones) and rebuilds Time Machine's internal database. This code is heavily based on the [Dart timezone package](https://github.com/srawlins/timezone).

The tool builds three database variants:

- default (doesn't contain deprecated and historical zones with some exceptions like US/Eastern). 78kb
- all (contains all data from the IANA time zone database). 101kb
- 10y (default database that contains historical data from the last and future 5 years). 16kb

Time Machine will ship with the "all" variant when compiled to native code and will use the "10y" variant by default when shipping code targeted at browser environments. Browser-based code needs to download the database with a separate HTTP request, so smaller files will speed up the init sequence. This behavior can be overridden when calling `TimeMachine.initialize()`. It is highly recommended to override the behavior for applications that require consistent local time stamps several years into the future or into the past and/or for uncommon regions.

## Updating time zone databases

Script for updating Time Zone database, it will automatically download the [IANA Time Zone Database](http://www.iana.org/time-zones) and compile into Time Machine's internal format:

```sh
$ chmod +x tools/tzdb_compiler/refresh.sh
$ tools/tzdb_compiler/refresh.sh
```

After updating, ensure that the `id` property in `tzdb_datetimezone_source.dart` reflects the new TZDB version.
