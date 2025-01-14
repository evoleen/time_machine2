// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

/// A pattern parser for a single format info, which caches patterns by text/style.
@internal
class FixedFormatInfoPatternParser<T> {
  // It would be unusual to have more than 50 different patterns for a specific culture
  // within a real app.
  static const int _cacheSize = 50;
  final Cache<String, IPattern<T>> _cache;

  FixedFormatInfoPatternParser(
      IPatternParser<T> patternParser, TimeMachineFormatInfo formatInfo)
      : _cache = Cache<String, IPattern<T>>(_cacheSize,
            (patternText) => patternParser.parsePattern(patternText, formatInfo)
            // https://msdn.microsoft.com/en-us/library/system.stringcomparer.ordinal(v=vs.110).aspx
            // StringComparer object that performs a case-sensitive ordinal string comparison.
            /*StringComparer.Ordinal*/);

  IPattern<T> parsePattern(String pattern) => _cache.getOrAdd(pattern);
}
