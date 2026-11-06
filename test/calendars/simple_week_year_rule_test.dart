// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine2/src/time_machine_internal.dart';
import 'package:test/test.dart';

import '../time_machine_testing.dart';

Future main() async {
  await runTests();
}

// List<DayOfWeek> BclDaysOfWeek = []; //(DayOfWeek[])Enum.GetValues(typeof(DayOfWeek));
List<CalendarWeekRule> CalendarWeekRules = CalendarWeekRule.values;

@Test()
void RoundtripFirstDay_Iso7() {
  // In the Gregorian calendar with a minimum of 7 days in the first
  // week, Tuesday January 1st -9998 is in week year -9999. We should be able to
  // round-trip.
  var rule = WeekYearRules.forMinDaysInFirstWeek(7);
  var date = LocalDate(-9998, 1, 1);
  expect(
      date,
      rule.getLocalDate(rule.getWeekYear(date), rule.getWeekOfWeekYear(date),
          date.dayOfWeek, CalendarSystem.iso));
}

@Test()
void RoundtripLastDay_Iso1() {
  // In the Gregorian calendar with a minimum of 1 day in the first
  // week, Friday December 31st 9999 is in week year 10000. We should be able to
  // round-trip.
  var rule = WeekYearRules.forMinDaysInFirstWeek(1);
  var date = LocalDate(9999, 12, 31);
  expect(
      date,
      rule.getLocalDate(rule.getWeekYear(date), rule.getWeekOfWeekYear(date),
          date.dayOfWeek, CalendarSystem.iso));
}

/// As [RoundtripFirstDay_Iso7] and [RoundtripLastDay_Iso1], for every calendar and rule:
/// the first and last days of a calendar may be in the week-year before its first year or after its last year, which
/// [WeekYearRule.getLocalDate] documents as valid.
@Test()
@TestCaseSource(#CalendarBoundaryRules)
void RoundtripFirstAndLastDays_AllCalendars(
    String calendarId, WeekYearRule rule) {
  var calendar = CalendarSystem.forId(calendarId);
  var firstDay = LocalDate(calendar.minYear, 1, 1, calendar);
  var lastMonth = calendar.getMonthsInYear(calendar.maxYear);
  var lastDay = LocalDate(calendar.maxYear, lastMonth,
      calendar.getDaysInMonth(calendar.maxYear, lastMonth), calendar);

  for (var date in [firstDay, lastDay]) {
    var weekYear = rule.getWeekYear(date);
    var weekOfWeekYear = rule.getWeekOfWeekYear(date);
    var description = '${date.year}-${date.monthOfYear}-${date.dayOfMonth}';
    expect(weekOfWeekYear,
        inInclusiveRange(1, rule.getWeeksInWeekYear(weekYear, calendar)),
        reason: description);
    expect(
        rule.getLocalDate(weekYear, weekOfWeekYear, date.dayOfWeek, calendar),
        date,
        reason: description);
  }
}

List<TestCaseData> get CalendarBoundaryRules {
  var daysOfWeek = [for (var i = 1; i <= 7; i++) DayOfWeek(i)];
  var rules = <(String, WeekYearRule)>[];
  for (var minDays = 1; minDays <= 7; minDays++) {
    for (var firstDayOfWeek in daysOfWeek) {
      rules.add((
        'forMinDaysInFirstWeek($minDays, $firstDayOfWeek)',
        WeekYearRules.forMinDaysInFirstWeek(minDays, firstDayOfWeek)
      ));
    }
  }
  for (var calendarWeekRule in CalendarWeekRules) {
    for (var firstDayOfWeek in daysOfWeek) {
      rules.add((
        'fromCalendarWeekRule(${calendarWeekRule.name}, $firstDayOfWeek)',
        WeekYearRules.fromCalendarWeekRule(calendarWeekRule, firstDayOfWeek)
      ));
    }
  }

  return [
    for (var calendarId in CalendarSystem.ids)
      for (var (name, rule) in rules)
        TestCaseData([calendarId, rule])..name = '($calendarId, $name)'
  ];
}

@Test()
void FirstDayInWeekYearBeforeFirstYear_Badi() {
  // 1 Bahá 1 BE is Thursday March 21st 1844. With weeks starting on Monday and at least 5 days in the first
  // week, its week (Monday March 18th to Sunday March 24th 1844) has only 4 days in year 1, so it's the last
  // week of week-year 0. Year 0 starts on Tuesday March 21st 1843, so week 1 of week-year 0 starts on Monday
  // March 20th 1843, and the week of 1 Bahá 1 is week 53.
  var rule = WeekYearRules.forMinDaysInFirstWeek(5, DayOfWeek.monday);
  var date = LocalDate(1, 1, 1, CalendarSystem.badi);
  expect(date.withCalendar(CalendarSystem.iso), LocalDate(1844, 3, 21));
  expect(rule.getWeekYear(date), 0);
  expect(rule.getWeekOfWeekYear(date), 53);
  expect(rule.getWeeksInWeekYear(0, CalendarSystem.badi), 53);
  expect(
      rule.getLocalDate(0, 53, DayOfWeek.thursday, CalendarSystem.badi), date);
}

@Test()
void OutOfRange_ValidWeekYearAndWeek_TooEarly() {
  // Gregorian 4: Week year 1 starts on Monday December 31st -9999,
  // and is therefore out of range, even though the week-year
  // and week-of-week-year are valid.
  expect(
      () => WeekYearRules.iso
          .getLocalDate(-9998, 1, DayOfWeek.monday, CalendarSystem.iso),
      willThrow<ArgumentError>());

  // Sanity check: no exception for January 1st
  WeekYearRules.iso
      .getLocalDate(-9998, 1, DayOfWeek.tuesday, CalendarSystem.iso);
}

@Test()
void OutOfRange_ValidWeekYearAndWeek_TooLate() {
// Gregorian 4: December 31st 9999 is a Friday, so the Saturday of the
// same week is therefore out of range, even though the week-year
// and week-of-week-year are valid.
//Assert.Throws<ArgumentOutOfRangeException>(
//        () => WeekYearRules.Iso.GetLocalDate(9999, 52, Saturday));

  expect(
      () => WeekYearRules.iso
          .getLocalDate(9999, 52, DayOfWeek.saturday, CalendarSystem.iso),
      willThrow<ArgumentError>());

  // Sanity check: no exception for December 31st
  WeekYearRules.iso
      .getLocalDate(9999, 52, DayOfWeek.friday, CalendarSystem.iso);
}

// Tests ported from IsoCalendarSystemTest and LocalDateTest.Construction
@Test()
@TestCase([2011, 1, 1, 2010, 52, DayOfWeek.saturday])
@TestCase([2012, 12, 31, 2013, 1, DayOfWeek.monday])
@TestCase([1960, 1, 19, 1960, 3, DayOfWeek.tuesday])
@TestCase([2012, 10, 19, 2012, 42, DayOfWeek.friday])
@TestCase([2005, 1, 2, 2004, 53, DayOfWeek.sunday])
void WeekYearDifferentToYear(int year, int month, int day, int weekYear,
    int weekOfWeekYear, DayOfWeek dayOfWeek) {
  var date = LocalDate(year, month, day);
  expect(weekYear, WeekYearRules.iso.getWeekYear(date));
  expect(weekOfWeekYear, WeekYearRules.iso.getWeekOfWeekYear(date));
  expect(dayOfWeek, date.dayOfWeek);
  expect(
      date,
      WeekYearRules.iso.getLocalDate(
          weekYear, weekOfWeekYear, dayOfWeek, CalendarSystem.iso));
}

// Ported from CalendarSystemTest.Validation
@Test()
@TestCase([2009, 53])
@TestCase([2010, 52])
@TestCase([2011, 52])
@TestCase([2012, 52])
@TestCase([2013, 52])
@TestCase([2014, 52])
@TestCase([2015, 53])
@TestCase([2016, 52])
@TestCase([2017, 52])
@TestCase([2018, 52])
@TestCase([2019, 52])
void GetWeeksInWeekYear(int weekYear, int expectedResult) {
  expect(expectedResult,
      WeekYearRules.iso.getWeeksInWeekYear(weekYear, CalendarSystem.iso));
}

// Ported from LocalDateTest.BasicProperties
// See https://stackoverflow.com/questions/8010125
@Test()
@TestCase([2007, 12, 31, 1])
@TestCase([2008, 1, 6, 1])
@TestCase([2008, 1, 7, 2])
@TestCase([2008, 12, 28, 52])
@TestCase([2008, 12, 29, 1])
@TestCase([2009, 1, 4, 1])
@TestCase([2009, 1, 5, 2])
@TestCase([2009, 12, 27, 52])
@TestCase([2009, 12, 28, 53])
@TestCase([2010, 1, 3, 53])
@TestCase([2010, 1, 4, 1])
void WeekOfWeekYear_ComparisonWithOracle(
    int year, int month, int day, int weekOfWeekYear) {
  var date = LocalDate(year, month, day);
  expect(weekOfWeekYear, WeekYearRules.iso.getWeekOfWeekYear(date));
}

@Test()
@TestCase([2000, DayOfWeek.saturday, 2])
@TestCase([2001, DayOfWeek.monday, 7])
@TestCase([2002, DayOfWeek.tuesday, 6])
@TestCase([2003, DayOfWeek.wednesday, 5])
@TestCase([2004, DayOfWeek.thursday, 4])
@TestCase([2005, DayOfWeek.saturday, 2])
@TestCase([2006, DayOfWeek.sunday, 1])
void Gregorian(int year, DayOfWeek firstDayOfYear,
    int maxMinDaysInFirstWeekForSameWeekYear) {
  var startOfCalendarYear = LocalDate(year, 1, 1);
  expect(firstDayOfYear, startOfCalendarYear.dayOfWeek);

  // Rules which put the first day of the calendar year into the same week year
  for (int i = 1; i <= maxMinDaysInFirstWeekForSameWeekYear; i++) {
    var rule = WeekYearRules.forMinDaysInFirstWeek(i);
    expect(year, rule.getWeekYear(startOfCalendarYear));
    expect(1, rule.getWeekOfWeekYear(startOfCalendarYear));
  }
  // Rules which put the first day of the calendar year into the previous week year
  for (int i = maxMinDaysInFirstWeekForSameWeekYear + 1; i <= 7; i++) {
    var rule = WeekYearRules.forMinDaysInFirstWeek(i);
    expect(year - 1, rule.getWeekYear(startOfCalendarYear));
    expect(rule.getWeeksInWeekYear(year - 1, CalendarSystem.iso),
        rule.getWeekOfWeekYear(startOfCalendarYear));
  }
}

// Test cases from https://blogs.msdn.microsoft.com/shawnste/2006/01/24/iso-8601-week-of-year-format-in-microsoft-net/
// which distinguish our ISO option from the BCL. When we implement the BCL equivalents, we should have similar
// tests there...
@Test()
@TestCase([2000, 12, 31, 2000, 52, DayOfWeek.sunday])
@TestCase([2001, 1, 1, 2001, 1, DayOfWeek.monday])
@TestCase([2005, 1, 1, 2004, 53, DayOfWeek.saturday])
@TestCase([2007, 12, 31, 2008, 1, DayOfWeek.monday])
void Iso(int year, int month, int day, int weekYear, int weekOfWeekYear,
    DayOfWeek dayOfWeek) {
  var viaCalendar = LocalDate(year, month, day);
  var rule = WeekYearRules.iso;
  expect(weekYear, rule.getWeekYear(viaCalendar));
  expect(weekOfWeekYear, rule.getWeekOfWeekYear(viaCalendar));
  expect(dayOfWeek, viaCalendar.dayOfWeek);
  var viaRule = rule.getLocalDate(
      weekYear, weekOfWeekYear, dayOfWeek, CalendarSystem.iso);
  expect(viaCalendar, viaRule);
}

/// Just a sample test of not using the Gregorian/ISO calendar system.
@Test()
@TestCase([5400, DayOfWeek.thursday, 1639, 9, 29, 51, 5400, 1])
@TestCase([5401, DayOfWeek.monday, 1640, 9, 17, 50, 5401, 1])
@TestCase([5402, DayOfWeek.thursday, 1641, 9, 5, 55, 5402, 1])
@TestCase([5403, DayOfWeek.thursday, 1642, 9, 25, 51, 5403, 1])
@TestCase([5404, DayOfWeek.monday, 1643, 9, 14, 55, 5404, 1])
@TestCase([5405, DayOfWeek.saturday, 1644, 10, 1, 50, 5404, 55])
@TestCase([5406, DayOfWeek.thursday, 1645, 9, 21, 51, 5406, 1])
@TestCase([5407, DayOfWeek.monday, 1646, 9, 10, 55, 5407, 1])
@TestCase([5408, DayOfWeek.monday, 1647, 9, 30, 50, 5408, 1])
@TestCase([5409, DayOfWeek.thursday, 1648, 9, 17, 51, 5409, 1])
@TestCase([5410, DayOfWeek.tuesday, 1649, 9, 7, 55, 5410, 1])
void HebrewCalendar(
    int year,
    DayOfWeek expectedFirstDay,
    int isoYear,
    int isoMonth,
    int isoDay, // Mostly for documentation
    int expectedWeeks,
    int expectedWeekYearOfFirstDay,
    int expectedWeekOfWeekYearOfFirstDay) {
  var civilDate = LocalDate(year, 1, 1, CalendarSystem.hebrewCivil);
  var rule = WeekYearRules.iso;
  expect(expectedFirstDay, civilDate.dayOfWeek);
  expect(civilDate.withCalendar(CalendarSystem.iso),
      LocalDate(isoYear, isoMonth, isoDay));
  expect(
      expectedWeeks, rule.getWeeksInWeekYear(year, CalendarSystem.hebrewCivil));
  expect(expectedWeekYearOfFirstDay, rule.getWeekYear(civilDate));
  expect(expectedWeekOfWeekYearOfFirstDay, rule.getWeekOfWeekYear(civilDate));
  expect(
      civilDate,
      rule.getLocalDate(
          expectedWeekYearOfFirstDay,
          expectedWeekOfWeekYearOfFirstDay,
          expectedFirstDay,
          CalendarSystem.hebrewCivil));

  // The scriptural month numbering system should have the same week-year and week-of-week-year.
  var scripturalDate = civilDate.withCalendar(CalendarSystem.hebrewScriptural);
  expect(expectedWeeks,
      rule.getWeeksInWeekYear(year, CalendarSystem.hebrewScriptural));
  expect(expectedWeekYearOfFirstDay, rule.getWeekYear(scripturalDate));
  expect(
      expectedWeekOfWeekYearOfFirstDay, rule.getWeekOfWeekYear(scripturalDate));
  expect(
      scripturalDate,
      rule.getLocalDate(
          expectedWeekYearOfFirstDay,
          expectedWeekOfWeekYearOfFirstDay,
          expectedFirstDay,
          CalendarSystem.hebrewScriptural));
}

// Jan 1st 2015 = Thursday
// Jan 1st 2016 = IsoDayOfWeek.friday
// Jan 1st 2017 = Sunday
@Test()
@TestCase([1, DayOfWeek.wednesday, 2015, 2, DayOfWeek.friday, 2015, 1, 9])
@TestCase([7, DayOfWeek.wednesday, 2015, 2, DayOfWeek.friday, 2015, 1, 16])
@TestCase([1, DayOfWeek.wednesday, 2015, 1, DayOfWeek.wednesday, 2014, 12, 31])
@TestCase([3, DayOfWeek.friday, 2016, 1, DayOfWeek.friday, 2016, 1, 1])
@TestCase([3, DayOfWeek.friday, 2017, 1, DayOfWeek.friday, 2016, 12, 30])
// We might want to add more tests here...
void NonMondayFirstDayOfWeek(
    int minDaysInFirstWeek,
    DayOfWeek firstDayOfWeek,
    int weekYear,
    int week,
    DayOfWeek dayOfWeek,
    int expectedYear,
    int expectedMonth,
    int expectedDay) {
  var rule =
      WeekYearRules.forMinDaysInFirstWeek(minDaysInFirstWeek, firstDayOfWeek);
  var actual = rule.getLocalDate(weekYear, week, dayOfWeek, CalendarSystem.iso);
  var expected = LocalDate(expectedYear, expectedMonth, expectedDay);
  expect(expected, actual);
  expect(weekYear, rule.getWeekYear(actual));
  expect(week, rule.getWeekOfWeekYear(actual));
}

// Tests for BCL rules...
// BclEquivalence and GetWeeksInWeekYear compare with System.Globalization.Calendar.GetWeekOfYear, so are .NET only.
/*

/// For each calendar and rule combination, check everything we can about every date
/// from mid December to mid January around each year between 2016 and 2046.
/// (For non-Gregorian calendars, the rough equivalent is used...)
/// That should give us plenty of coverage.
@Test()
[Combinatorial]
void BclEquivalence(
[ValueSource(typeof(BclCalendars), nameof(BclCalendars.MappedCalendars))] Calendar calendar,
[ValueSource(#CalendarWeekRules)] CalendarWeekRule bclRule,
[ValueSource(#BclDaysOfWeek)] DayOfWeek firstDayOfWeek)
{
var nodaCalendar = BclCalendars.CalendarSystemForCalendar(calendar);
var nodaRule = WeekYearRules.FromCalendarWeekRule(bclRule, firstDayOfWeek);
var startYear = new LocalDate(2016, 1, 1).WithCalendar(nodaCalendar).Year;

for (int year = startYear; year < startYear + 30; year++)
{
var startDate = new LocalDate(year, 1, 1, nodaCalendar).PlusDays(-15);
for (int day = 0; day < 30; day++)
{
var date = startDate.PlusDays(day);
var bclDate = date.ToDateTimeUnspecified();
var bclWeek = calendar.GetWeekOfYear(bclDate, bclRule, firstDayOfWeek);
// Weird... the BCL doesn't have a way of finding out which week-year we're in.
// We're starting at "start of year - 15 days", so a "small" week-of-year
// value means we're in "year", whereas a "large" week-of-year value means
// we're in the "year-1".
var bclWeekYear = bclWeek < 10 ? year : year - 1;

expect(bclWeek, nodaRule.GetWeekOfWeekYear(date), 'Date: {0}', date);
expect(bclWeekYear, nodaRule.GetWeekYear(date), 'Date: {0}', date);
expect(date, nodaRule.GetLocalDate(bclWeekYear, bclWeek, date.DayOfWeek, nodaCalendar),
'Week-year:{0}; Week: {1}; Day: {2}', bclWeekYear, bclWeek, date.DayOfWeek);
}
}
}

/// The number of weeks in the year is equal to the week-of-week-year for the last
/// day of the year.
@Test()
[Combinatorial]
void GetWeeksInWeekYear(
[ValueSource(typeof(BclCalendars), nameof(BclCalendars.MappedCalendars))] Calendar calendar,
[ValueSource(#CalendarWeekRules)] CalendarWeekRule bclRule,
[ValueSource(#BclDaysOfWeek)] DayOfWeek firstDayOfWeek)
{
var nodaCalendar = BclCalendars.CalendarSystemForCalendar(calendar);
var nodaRule = WeekYearRules.FromCalendarWeekRule(bclRule, firstDayOfWeek);
var startYear = new LocalDate(2016, 1, 1).WithCalendar(nodaCalendar).Year;

for (int year = startYear; year < startYear + 30; year++)
{
var bclDate = new LocalDate(year + 1, 1, 1, nodaCalendar).PlusDays(-1).ToDateTimeUnspecified();
expect(calendar.GetWeekOfYear(bclDate, bclRule, firstDayOfWeek),
nodaRule.GetWeeksInWeekYear(year, nodaCalendar), 'Year {0}', year);
}
}
*/

// Tests where we ask for an invalid combination of week-year/week/day-of-week due to a week being 'short'
// in BCL rules.
// Jan 1st 2016 = Friday
@Test()
@TestCase(
    [CalendarWeekRule.firstDay, DayOfWeek.monday, 2015, 53, DayOfWeek.saturday])
@TestCase(
    [CalendarWeekRule.firstDay, DayOfWeek.monday, 2016, 1, DayOfWeek.thursday])
void GetLocalDate_Invalid(CalendarWeekRule bclRule, DayOfWeek firstDayOfWeek,
    int weekYear, int week, DayOfWeek dayOfWeek) {
  var nodaRule = WeekYearRules.fromCalendarWeekRule(bclRule, firstDayOfWeek);
  expect(
      () => WeekYearRuleExtensions.getLocalDate(
          nodaRule, weekYear, week, dayOfWeek),
      throwsRangeError);
}

/// The BCL rules for every [CalendarWeekRule] and every first day of the week. (The BCL's DayOfWeek
/// runs from Sunday to Saturday; WeekYearRules.fromCalendarWeekRule takes the equivalent [DayOfWeek].)
List<List<Object>> get BclRules => [
      for (var bclRule in CalendarWeekRules)
        for (var i = 1; i <= 7; i++) [bclRule, DayOfWeek(i)]
    ];

@Test()
@TestCaseSource(#BclRules)
void RoundtripFirstDayBcl(CalendarWeekRule bclRule, DayOfWeek firstDayOfWeek) {
  var rule = WeekYearRules.fromCalendarWeekRule(bclRule, firstDayOfWeek);
  var date = LocalDate(-9998, 1, 1);
  expect(
      WeekYearRuleExtensions.getLocalDate(rule, rule.getWeekYear(date),
          rule.getWeekOfWeekYear(date), date.dayOfWeek),
      date);
}

@Test()
@TestCaseSource(#BclRules)
void RoundtripLastDayBcl(CalendarWeekRule bclRule, DayOfWeek firstDayOfWeek) {
  var rule = WeekYearRules.fromCalendarWeekRule(bclRule, firstDayOfWeek);
  var date = LocalDate(9999, 12, 31);
  expect(
      WeekYearRuleExtensions.getLocalDate(rule, rule.getWeekYear(date),
          rule.getWeekOfWeekYear(date), date.dayOfWeek),
      date);
}

// TODO: Test the difference in ValidateWeekYear for 9999 between regular and non-regular rules.
