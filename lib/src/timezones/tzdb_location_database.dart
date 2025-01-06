// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// Locations database
import 'tzdb_location.dart';

/// TzdbLocationDatabase provides interface to find [TzdbLocation]s by their name.
///
///     List<int> data = load(); // load database
///
///     LocationDatabase db = LocationDatabase.fromBytes(data);
///     Location loc = db.get('US/Eastern');
///
class TzdbLocationDatabase {
  /// Mapping between [TzdbLocation] name and [TzdbLocation].
  final _locations = <String, TzdbLocation>{};

  Map<String, TzdbLocation> get locations => _locations;

  /// Adds [TzdbLocation] to the database.
  void add(TzdbLocation location) {
    _locations[location.name] = location;
  }

  /// Finds [TzdbLocation] by its name.
  TzdbLocation get(String name) {
    if (!isInitialized) {
      // Before you can get a location, you need to manually initialize the
      // timezone location database by calling initializeDatabase or similar.
      throw Exception(
          'Tried to get location before initializing timezone database');
    }

    final loc = _locations[name];
    if (loc == null) {
      throw Exception('Location with the name "$name" doesn\'t exist');
    }
    return loc;
  }

  /// Clears the database of all [TzdbLocation] entries.
  void clear() => _locations.clear();

  /// Returns whether the database is empty, or has [TzdbLocation] entries.
  @Deprecated("Use 'isInitialized' instead")
  bool get isEmpty => isInitialized;

  /// Returns whether the database is empty, or has [TzdbLocation] entries.
  bool get isInitialized => _locations.isNotEmpty;
}
