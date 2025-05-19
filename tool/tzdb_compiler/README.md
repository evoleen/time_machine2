# TZDB compiler

The Dart program in this folder generates Time Machine's TZDB database by downloading
the original TZDB archive from IANA and then compiling it to Time Machine's internal
binary format.

The compiler is based on NodaTime's TZDB compiler. Theoretically Time Machine's format
should be fully compatible with NodaTime's format, but using the same TZDB files between
both projects hasn't been tested.

Furthermore, Time Machine leverages compression to enhance loading performance on web
platforms, which is not supported by NodaTime.
