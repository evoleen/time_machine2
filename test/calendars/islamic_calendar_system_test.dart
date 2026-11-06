// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
// import 'package:matcher/matcher.dart';

void main() {
  test('SampleDate1', SampleDate1);
  test('SampleDate2', SampleDate2);
  test('SampleDate3', SampleDate3);
  test('InternalConsistency', InternalConsistency);
  test('Base15LeapYear', Base15LeapYear);
  test('Base16LeapYear', Base16LeapYear);
  test('IndianBasedLeapYear', IndianBasedLeapYear);
  test('HabashAlHasibBasedLeapYear', HabashAlHasibBasedLeapYear);
  test('ThursdayEpoch', ThursdayEpoch);
  test('FridayEpoch', FridayEpoch);
  test('BclUsesAstronomicalEpoch', BclUsesAstronomicalEpoch);
  test('SampleDateBclCompatibility', SampleDateBclCompatibility, skip: true);
  test('BclThroughHistory', BclThroughHistory, skip: true);
  test('GetDaysInMonth', GetDaysInMonth);
  test('GetInstance_Caching', GetInstance_Caching, skip: true);
  test('GetInstance_ArgumentValidation', GetInstance_ArgumentValidation,
      skip: true);
  test('PlusYears_Simple', PlusYears_Simple);
  test('PlusYears_TruncatesAtLeapYear', PlusYears_TruncatesAtLeapYear);
  test('PlusYears_DoesNotTruncateFromOneLeapYearToAnother',
      PlusYears_DoesNotTruncateFromOneLeapYearToAnother);
  test('PlusMonths_Simple', PlusMonths_Simple);
  test('Constructor_InvalidEnumsForCoverage',
      Constructor_InvalidEnumsForCoverage,
      skip: "Doesn't make sense in Dart");
}

final CalendarSystem SampleCalendar = CalendarSystem.getIslamicCalendar(
    IslamicLeapYearPattern.base16, IslamicEpoch.civil);

void SampleDate1() {
  // Note: field checks removed from the tests.
  LocalDateTime ldt =
      LocalDateTime(1945, 11, 12, 0, 0, 0, calendar: CalendarSystem.iso);

  ldt = ldt.withCalendar(SampleCalendar);
  expect(Era.annoHegirae, ldt.era);
  expect(1364, ldt.yearOfEra);

  expect(1364, ldt.year);
  expect(12, ldt.monthOfYear);
  expect(6, ldt.dayOfMonth);
  expect(DayOfWeek.monday, ldt.dayOfWeek);
  expect(6 * 30 + 5 * 29 + 6, ldt.dayOfYear);

  expect(0, ldt.hourOfDay);
  expect(0, ldt.minuteOfHour);
  expect(0, ldt.secondOfMinute);
  expect(0, ldt.microsecondOfSecond);
}

void SampleDate2() {
  LocalDateTime ldt =
      LocalDateTime(2005, 11, 26, 0, 0, 0, calendar: CalendarSystem.iso);
  ldt = ldt.withCalendar(SampleCalendar);
  expect(Era.annoHegirae, ldt.era);
  expect(1426, ldt.yearOfEra);

  expect(1426, ldt.year);
  expect(10, ldt.monthOfYear);
  expect(24, ldt.dayOfMonth);
  expect(DayOfWeek.saturday, ldt.dayOfWeek);
  expect(5 * 30 + 4 * 29 + 24, ldt.dayOfYear);
  expect(0, ldt.hourOfDay);
  expect(0, ldt.minuteOfHour);
  expect(0, ldt.secondOfMinute);
  expect(0, ldt.microsecondOfSecond);
}

void SampleDate3() {
  LocalDateTime ldt =
      LocalDateTime(1426, 12, 24, 0, 0, 0, calendar: SampleCalendar);
  expect(Era.annoHegirae, ldt.era);

  expect(1426, ldt.year);
  expect(12, ldt.monthOfYear);
  expect(24, ldt.dayOfMonth);
  expect(DayOfWeek.tuesday, ldt.dayOfWeek);
  expect(6 * 30 + 5 * 29 + 24, ldt.dayOfYear);
  expect(0, ldt.hourOfDay);
  expect(0, ldt.minuteOfHour);
  expect(0, ldt.secondOfMinute);
  expect(0, ldt.microsecondOfSecond);
}

void InternalConsistency() {
  var calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.base15, IslamicEpoch.civil);
  // Check construction and then deconstruction for every day of every year in one 30-year cycle.
  for (int year = 1; year <= 30; year++) {
    for (int month = 1; month <= 12; month++) {
      int monthLength = calendar.getDaysInMonth(year, month);
      for (int day = 1; day < monthLength; day++) {
        LocalDate date = LocalDate(year, month, day, calendar);
        expect(year, date.year, reason: 'Year of $year-$month-$day');
        expect(month, date.monthOfYear, reason: 'Month of $year-$month-$day');
        expect(day, date.dayOfMonth, reason: 'Day of $year-$month-$day');
      }
    }
  }
}

void Base15LeapYear() {
  CalendarSystem calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.base15, IslamicEpoch.civil);

  expect(false, calendar.isLeapYear(1));
  expect(true, calendar.isLeapYear(2));
  expect(false, calendar.isLeapYear(3));
  expect(false, calendar.isLeapYear(4));
  expect(true, calendar.isLeapYear(5));
  expect(false, calendar.isLeapYear(6));
  expect(true, calendar.isLeapYear(7));
  expect(false, calendar.isLeapYear(8));
  expect(false, calendar.isLeapYear(9));
  expect(true, calendar.isLeapYear(10));
  expect(false, calendar.isLeapYear(11));
  expect(false, calendar.isLeapYear(12));
  expect(true, calendar.isLeapYear(13));
  expect(false, calendar.isLeapYear(14));
  expect(true, calendar.isLeapYear(15));
  expect(false, calendar.isLeapYear(16));
  expect(false, calendar.isLeapYear(17));
  expect(true, calendar.isLeapYear(18));
  expect(false, calendar.isLeapYear(19));
  expect(false, calendar.isLeapYear(20));
  expect(true, calendar.isLeapYear(21));
  expect(false, calendar.isLeapYear(22));
  expect(false, calendar.isLeapYear(23));
  expect(true, calendar.isLeapYear(24));
  expect(false, calendar.isLeapYear(25));
  expect(true, calendar.isLeapYear(26));
  expect(false, calendar.isLeapYear(27));
  expect(false, calendar.isLeapYear(28));
  expect(true, calendar.isLeapYear(29));
  expect(false, calendar.isLeapYear(30));
}

void Base16LeapYear() {
  CalendarSystem calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.base16, IslamicEpoch.civil);

  expect(false, calendar.isLeapYear(1));
  expect(true, calendar.isLeapYear(2));
  expect(false, calendar.isLeapYear(3));
  expect(false, calendar.isLeapYear(4));
  expect(true, calendar.isLeapYear(5));
  expect(false, calendar.isLeapYear(6));
  expect(true, calendar.isLeapYear(7));
  expect(false, calendar.isLeapYear(8));
  expect(false, calendar.isLeapYear(9));
  expect(true, calendar.isLeapYear(10));
  expect(false, calendar.isLeapYear(11));
  expect(false, calendar.isLeapYear(12));
  expect(true, calendar.isLeapYear(13));
  expect(false, calendar.isLeapYear(14));
  expect(false, calendar.isLeapYear(15));
  expect(true, calendar.isLeapYear(16));
  expect(false, calendar.isLeapYear(17));
  expect(true, calendar.isLeapYear(18));
  expect(false, calendar.isLeapYear(19));
  expect(false, calendar.isLeapYear(20));
  expect(true, calendar.isLeapYear(21));
  expect(false, calendar.isLeapYear(22));
  expect(false, calendar.isLeapYear(23));
  expect(true, calendar.isLeapYear(24));
  expect(false, calendar.isLeapYear(25));
  expect(true, calendar.isLeapYear(26));
  expect(false, calendar.isLeapYear(27));
  expect(false, calendar.isLeapYear(28));
  expect(true, calendar.isLeapYear(29));
  expect(false, calendar.isLeapYear(30));
}

void IndianBasedLeapYear() {
  CalendarSystem calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.indian, IslamicEpoch.civil);

  expect(false, calendar.isLeapYear(1));
  expect(true, calendar.isLeapYear(2));
  expect(false, calendar.isLeapYear(3));
  expect(false, calendar.isLeapYear(4));
  expect(true, calendar.isLeapYear(5));
  expect(false, calendar.isLeapYear(6));
  expect(false, calendar.isLeapYear(7));
  expect(true, calendar.isLeapYear(8));
  expect(false, calendar.isLeapYear(9));
  expect(true, calendar.isLeapYear(10));
  expect(false, calendar.isLeapYear(11));
  expect(false, calendar.isLeapYear(12));
  expect(true, calendar.isLeapYear(13));
  expect(false, calendar.isLeapYear(14));
  expect(false, calendar.isLeapYear(15));
  expect(true, calendar.isLeapYear(16));
  expect(false, calendar.isLeapYear(17));
  expect(false, calendar.isLeapYear(18));
  expect(true, calendar.isLeapYear(19));
  expect(false, calendar.isLeapYear(20));
  expect(true, calendar.isLeapYear(21));
  expect(false, calendar.isLeapYear(22));
  expect(false, calendar.isLeapYear(23));
  expect(true, calendar.isLeapYear(24));
  expect(false, calendar.isLeapYear(25));
  expect(false, calendar.isLeapYear(26));
  expect(true, calendar.isLeapYear(27));
  expect(false, calendar.isLeapYear(28));
  expect(true, calendar.isLeapYear(29));
  expect(false, calendar.isLeapYear(30));
}

void HabashAlHasibBasedLeapYear() {
  CalendarSystem calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.habashAlHasib, IslamicEpoch.civil);

  expect(false, calendar.isLeapYear(1));
  expect(true, calendar.isLeapYear(2));
  expect(false, calendar.isLeapYear(3));
  expect(false, calendar.isLeapYear(4));
  expect(true, calendar.isLeapYear(5));
  expect(false, calendar.isLeapYear(6));
  expect(false, calendar.isLeapYear(7));
  expect(true, calendar.isLeapYear(8));
  expect(false, calendar.isLeapYear(9));
  expect(false, calendar.isLeapYear(10));
  expect(true, calendar.isLeapYear(11));
  expect(false, calendar.isLeapYear(12));
  expect(true, calendar.isLeapYear(13));
  expect(false, calendar.isLeapYear(14));
  expect(false, calendar.isLeapYear(15));
  expect(true, calendar.isLeapYear(16));
  expect(false, calendar.isLeapYear(17));
  expect(false, calendar.isLeapYear(18));
  expect(true, calendar.isLeapYear(19));
  expect(false, calendar.isLeapYear(20));
  expect(true, calendar.isLeapYear(21));
  expect(false, calendar.isLeapYear(22));
  expect(false, calendar.isLeapYear(23));
  expect(true, calendar.isLeapYear(24));
  expect(false, calendar.isLeapYear(25));
  expect(false, calendar.isLeapYear(26));
  expect(true, calendar.isLeapYear(27));
  expect(false, calendar.isLeapYear(28));
  expect(false, calendar.isLeapYear(29));
  expect(true, calendar.isLeapYear(30));
}

void ThursdayEpoch() {
  CalendarSystem thursdayEpochCalendar = CalendarSystem.islamicBcl;
  CalendarSystem julianCalendar = CalendarSystem.julian;

  LocalDate thursdayEpoch = LocalDate(1, 1, 1, thursdayEpochCalendar);
  LocalDate thursdayEpochJulian = LocalDate(622, 7, 15, julianCalendar);
  expect(thursdayEpochJulian, thursdayEpoch.withCalendar(julianCalendar));
}

void FridayEpoch() {
  CalendarSystem fridayEpochCalendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.base16, IslamicEpoch.civil);
  CalendarSystem julianCalendar = CalendarSystem.julian;

  LocalDate fridayEpoch = LocalDate(1, 1, 1, fridayEpochCalendar);
  LocalDate fridayEpochJulian = LocalDate(622, 7, 16, julianCalendar);
  expect(fridayEpochJulian, fridayEpoch.withCalendar(julianCalendar));
}

void BclUsesAstronomicalEpoch() {
  // Calendar hijri = BclCalendars.Hijri;
  // DateTime bclDirect = hijri.ToDateTime(1, 1, 1, 0, 0, 0, 0);
  // toString(): 7/18/22 12:00:00 AM (year is 622 but prints weird)
  // ticks: 196139232000000000
  var bclDirect = DateTime.utc(622, 7, 18);

  CalendarSystem julianCalendar = CalendarSystem.julian;
  LocalDate julianIslamicEpoch = LocalDate(622, 7, 15, julianCalendar);
  LocalDate isoIslamicEpoch =
      julianIslamicEpoch.withCalendar(CalendarSystem.iso);
  DateTime bclFromNoda = isoIslamicEpoch.atMidnight().toDateTimeLocal();
  expect(bclDirect, bclFromNoda);
}

void SampleDateBclCompatibility() {
  dynamic hijri; // = BclCalendars.Hijri;
  DateTime bclDirect = hijri.ToDateTime(1302, 10, 15, 0, 0, 0, 0);

  CalendarSystem islamicCalendar = CalendarSystem.islamicBcl;
  LocalDate iso = LocalDate(1302, 10, 15, islamicCalendar);
  DateTime bclFromNoda = iso.atMidnight().toDateTimeLocal();
  expect(bclDirect, bclFromNoda);
}

/// This tests every day for 9000 (ISO) years, to check that it always matches the year, month and day.
// [Category('Slow')]
void BclThroughHistory() {
  //var bcl = BclCalendars.Hijri;
  //var noda = CalendarSystem.islamicBcl;
  //BclEquivalenceHelper.AssertEquivalent(bcl, noda);
}

void GetDaysInMonth() {
  // Just check that we've got the long/short the right way round...
  CalendarSystem calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.habashAlHasib, IslamicEpoch.civil);
  expect(30, calendar.getDaysInMonth(7, 1));
  expect(29, calendar.getDaysInMonth(7, 2));
  expect(30, calendar.getDaysInMonth(7, 3));
  expect(29, calendar.getDaysInMonth(7, 4));
  expect(30, calendar.getDaysInMonth(7, 5));
  expect(29, calendar.getDaysInMonth(7, 6));
  expect(30, calendar.getDaysInMonth(7, 7));
  expect(29, calendar.getDaysInMonth(7, 8));
  expect(30, calendar.getDaysInMonth(7, 9));
  expect(29, calendar.getDaysInMonth(7, 10));
  expect(30, calendar.getDaysInMonth(7, 11));
  // As noted before, 7 isn't a leap year in this calendar
  expect(29, calendar.getDaysInMonth(7, 12));
  // As noted before, 8 is a leap year in this calendar
  expect(30, calendar.getDaysInMonth(8, 12));
}

void GetInstance_Caching() {
  /*
  var queue = new Queue<CalendarSystem>();
  var set = new HashSet<CalendarSystem>();
  var ids = new HashSet<String>();

  for (IslamicLeapYearPattern leapYearPattern in Enum.GetValues(typeof(IslamicLeapYearPattern)))
  {
  for (IslamicEpoch epoch in Enum.GetValues(typeof(IslamicEpoch)))
  {
  var calendar = CalendarSystem.getIslamicCalendar(leapYearPattern, epoch);
  queue.Enqueue(calendar);
  expect(set.Add(calendar), isTrue); // Check we haven't already seen it...
  expect(ids.Add(calendar.Id), isTrue);
  }
  }

  // Now check we get the same references again...
  for (IslamicLeapYearPattern leapYearPattern in Enum.GetValues(typeof(IslamicLeapYearPattern)))
  {
  for (IslamicEpoch epoch in Enum.GetValues(typeof(IslamicEpoch)))
  {
  var oldCalendar = queue.Dequeue();
  var newCalendar = CalendarSystem.getIslamicCalendar(leapYearPattern, epoch);
  Assert.AreSame(oldCalendar, newCalendar);
  }
  }*/
}

void GetInstance_ArgumentValidation() {
  /*
  var epochs = Enum.GetValues(typeof(IslamicEpoch)).Cast<IslamicEpoch>();
  var leapYearPatterns = Enum.GetValues(typeof(IslamicLeapYearPattern)).Cast<IslamicLeapYearPattern>();
  expect(() => CalendarSystem.getIslamicCalendar(leapYearPatterns.Min() - 1, epochs.Min()), throwsRangeError);
  expect(() => CalendarSystem.getIslamicCalendar(leapYearPatterns.Min(), epochs.Min() - 1), throwsRangeError);
  expect(() => CalendarSystem.getIslamicCalendar(leapYearPatterns.Max() + 1, epochs.Min()), throwsRangeError);
  expect(() => CalendarSystem.getIslamicCalendar(leapYearPatterns.Min(), epochs.Max() + 1), throwsRangeError);
  */
}

void PlusYears_Simple() {
  var calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.base15, IslamicEpoch.civil);
  LocalDateTime start = LocalDateTime(5, 8, 20, 2, 0, 0, calendar: calendar);
  LocalDateTime expectedEnd =
      LocalDateTime(10, 8, 20, 2, 0, 0, calendar: calendar);
  expect(expectedEnd, start.addYears(5));
}

void PlusYears_TruncatesAtLeapYear() {
  var calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.base15, IslamicEpoch.civil);
  expect(calendar.isLeapYear(2), isTrue);
  expect(calendar.isLeapYear(3), isFalse);

  LocalDateTime start = LocalDateTime(2, 12, 30, 2, 0, 0, calendar: calendar);
  LocalDateTime expectedEnd =
      LocalDateTime(3, 12, 29, 2, 0, 0, calendar: calendar);

  expect(expectedEnd, start.addYears(1));
}

void PlusYears_DoesNotTruncateFromOneLeapYearToAnother() {
  var calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.base15, IslamicEpoch.civil);
  expect(calendar.isLeapYear(2), isTrue);
  expect(calendar.isLeapYear(5), isTrue);

  LocalDateTime start = LocalDateTime(2, 12, 30, 2, 0, 0, calendar: calendar);
  LocalDateTime expectedEnd =
      LocalDateTime(5, 12, 30, 2, 0, 0, calendar: calendar);

  expect(expectedEnd, start.addYears(3));
}

void PlusMonths_Simple() {
  var calendar = CalendarSystem.getIslamicCalendar(
      IslamicLeapYearPattern.base15, IslamicEpoch.civil);
  expect(calendar.isLeapYear(2), isTrue);

  LocalDateTime start = LocalDateTime(2, 12, 30, 2, 0, 0, calendar: calendar);
  LocalDateTime expectedEnd =
      LocalDateTime(3, 11, 30, 2, 0, 0, calendar: calendar);
  expect(11, expectedEnd.monthOfYear);
  expect(30, expectedEnd.dayOfMonth);
  expect(expectedEnd, start.addMonths(11));
}

void Constructor_InvalidEnumsForCoverage() {
  // expect(() => new IslamicYearMonthDayCalculator(IslamicLeapYearPattern.base15 + 100, IslamicEpoch.astronomical), throwsRangeError);
  // expect(() => new IslamicYearMonthDayCalculator(IslamicLeapYearPattern.base15, IslamicEpoch.astronomical + 100), throwsRangeError);
}
