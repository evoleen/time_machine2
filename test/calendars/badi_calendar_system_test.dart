// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'package:time_machine2/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:parameterized_test/parameterized_test.dart';

import '../time_machine_testing.dart';

/// Tests for the Badíʿ calendar system.
void main() {
  test('BadiEpoch', BadiEpoch);
  test('UnixEpoch', UnixEpoch);
  test('SampleDate', SampleDate);
  parameterizedTest(
      'GeneralConversionNearNawRuz',
      [
        [2016, 2, 26, 172, AyyamiHaMonth, 1],
        [2016, 2, 29, 172, AyyamiHaMonth, 4],
        [2016, 3, 1, 172, 19, 1],
        [2016, 3, 20, 173, 1, 1],
        [2016, 3, 20, 173, 1, 1],
        [2016, 3, 21, 173, 1, 2],
        [2016, 5, 26, 173, 4, 11],
        [2017, 3, 20, 174, 1, 1],
        [2018, 3, 21, 175, 1, 1],
        [2019, 3, 21, 176, 1, 1],
        [2020, 3, 20, 177, 1, 1],
        [2021, 3, 20, 178, 1, 1],
        [2022, 3, 21, 179, 1, 1],
        [2023, 3, 21, 180, 1, 1],
        [2024, 3, 20, 181, 1, 1],
        [2025, 3, 20, 182, 1, 1],
        [2026, 3, 21, 183, 1, 1],
        [2027, 3, 21, 184, 1, 1],
        [2028, 3, 20, 185, 1, 1],
        [2029, 3, 20, 186, 1, 1],
        [2030, 3, 20, 187, 1, 1],
        [2031, 3, 21, 188, 1, 1],
        [2032, 3, 20, 189, 1, 1],
        [2033, 3, 20, 190, 1, 1],
        [2034, 3, 20, 191, 1, 1],
        [2035, 3, 21, 192, 1, 1],
        [2036, 3, 20, 193, 1, 1],
        [2037, 3, 20, 194, 1, 1],
        [2038, 3, 20, 195, 1, 1],
        [2039, 3, 21, 196, 1, 1],
        [2040, 3, 20, 197, 1, 1],
        [2041, 3, 20, 198, 1, 1],
        [2042, 3, 20, 199, 1, 1],
        [2043, 3, 21, 200, 1, 1],
        [2044, 3, 20, 201, 1, 1],
        [2045, 3, 20, 202, 1, 1],
        [2046, 3, 20, 203, 1, 1],
        [2047, 3, 21, 204, 1, 1],
        [2048, 3, 20, 205, 1, 1],
        [2049, 3, 20, 206, 1, 1],
        [2050, 3, 20, 207, 1, 1],
        [2051, 3, 21, 208, 1, 1],
        [2052, 3, 20, 209, 1, 1],
        [2053, 3, 20, 210, 1, 1],
        [2054, 3, 20, 211, 1, 1],
        [2055, 3, 21, 212, 1, 1],
        [2056, 3, 20, 213, 1, 1],
        [2057, 3, 20, 214, 1, 1],
        [2058, 3, 20, 215, 1, 1],
        [2059, 3, 20, 216, 1, 1],
        [2060, 3, 20, 217, 1, 1],
        [2061, 3, 20, 218, 1, 1],
        [2062, 3, 20, 219, 1, 1],
        [2063, 3, 20, 220, 1, 1],
        [2064, 3, 20, 221, 1, 1],
      ],
      GeneralConversionNearNawRuz,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'SpecialCases',
      [
        [2012, 2, 29, 168, AyyamiHaMonth, 4],
        [2012, 3, 1, 168, AyyamiHaMonth, 5],
        [2015, 3, 1, 171, AyyamiHaMonth, 4],
        [2015, 3, 1, 171, AyyamiHaMonth, 4],
        [2016, 3, 1, 172, 19, 1],
        [2016, 3, 19, 172, 19, 19],
        [2017, 3, 1, 173, 19, 1],
        [2017, 3, 19, 173, 19, 19],
        [2018, 2, 24, 174, 18, 19],
        [2018, 2, 25, 174, AyyamiHaMonth, 1],
        [2018, 3, 1, 174, AyyamiHaMonth, 5],
        [2018, 3, 2, 174, 19, 1],
        [2018, 3, 19, 174, 19, 18],
      ],
      SpecialCases,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'GeneralWtoG',
      [
        [1, 1, 1, 1844, 3, 21],
        [169, 1, 1, 2012, 3, 21],
        [170, 1, 1, 2013, 3, 21],
        [171, 1, 1, 2014, 3, 21],
        [171, 1, 1, 2014, 3, 21],
        [172, AyyamiHaMonth, 1, 2016, 2, 26],
        [172, AyyamiHaMonth, 2, 2016, 2, 27],
        [172, AyyamiHaMonth, 3, 2016, 2, 28],
        [172, AyyamiHaMonth, 4, 2016, 2, 29],
        [172, 1, 1, 2015, 3, 21],
        [172, 1, 1, 2015, 3, 21],
        [172, 17, 18, 2016, 2, 5],
        [172, 18, 17, 2016, 2, 23],
        [172, 18, 19, 2016, 2, 25],
        [172, 19, 1, 2016, 3, 1],
        [173, 1, 1, 2016, 3, 20],
        [173, 1, 1, 2016, 3, 20],
        [174, 1, 1, 2017, 3, 20],
        [175, 1, 1, 2018, 3, 21],
        [176, 1, 1, 2019, 3, 21],
        [177, 1, 1, 2020, 3, 20],
        [178, 1, 1, 2021, 3, 20],
        [179, 1, 1, 2022, 3, 21],
        [180, 1, 1, 2023, 3, 21],
        [181, 1, 1, 2024, 3, 20],
        [182, 1, 1, 2025, 3, 20],
        [183, 1, 1, 2026, 3, 21],
        [184, 1, 1, 2027, 3, 21],
        [185, 1, 1, 2028, 3, 20],
        [186, 1, 1, 2029, 3, 20],
        [187, 1, 1, 2030, 3, 20],
        [188, 1, 1, 2031, 3, 21],
        [189, 1, 1, 2032, 3, 20],
        [190, 1, 1, 2033, 3, 20],
        [191, 1, 1, 2034, 3, 20],
        [192, 1, 1, 2035, 3, 21],
        [193, 1, 1, 2036, 3, 20],
        [194, 1, 1, 2037, 3, 20],
        [195, 1, 1, 2038, 3, 20],
        [196, 1, 1, 2039, 3, 21],
        [197, 1, 1, 2040, 3, 20],
        [198, 1, 1, 2041, 3, 20],
        [199, 1, 1, 2042, 3, 20],
        [200, 1, 1, 2043, 3, 21],
        [201, 1, 1, 2044, 3, 20],
        [202, 1, 1, 2045, 3, 20],
        [203, 1, 1, 2046, 3, 20],
        [204, 1, 1, 2047, 3, 21],
        [205, 1, 1, 2048, 3, 20],
        [206, 1, 1, 2049, 3, 20],
        [207, 1, 1, 2050, 3, 20],
        [208, 1, 1, 2051, 3, 21],
        [209, 1, 1, 2052, 3, 20],
        [210, 1, 1, 2053, 3, 20],
        [211, 1, 1, 2054, 3, 20],
        [212, 1, 1, 2055, 3, 21],
        [213, 1, 1, 2056, 3, 20],
        [214, 1, 1, 2057, 3, 20],
        [215, 1, 1, 2058, 3, 20],
        [216, 1, 1, 2059, 3, 20],
        [217, 1, 1, 2060, 3, 20],
        [218, 1, 1, 2061, 3, 20],
        [219, 1, 1, 2062, 3, 20],
        [220, 1, 1, 2063, 3, 20],
        [221, 1, 1, 2064, 3, 20],
      ],
      GeneralWtoG,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'DaysInAyyamiHa',
      [
        [172, 4],
        [173, 4],
        [174, 5],
        [175, 4],
        [176, 4],
        [177, 4],
        [178, 5],
        [179, 4],
        [180, 4],
        [181, 4],
        [182, 5],
        [183, 4],
        [184, 4],
        [185, 4],
        [186, 4],
        [187, 5],
        [188, 4],
        [189, 4],
        [190, 4],
        [191, 5],
        [192, 4],
        [193, 4],
        [194, 4],
        [195, 5],
        [196, 4],
        [197, 4],
        [198, 4],
        [199, 5],
        [200, 4],
        [201, 4],
        [202, 4],
        [203, 5],
        [204, 4],
        [205, 4],
        [206, 4],
        [207, 5],
        [208, 4],
        [209, 4],
        [210, 4],
        [211, 5],
        [212, 4],
        [213, 4],
        [214, 4],
        [215, 4],
        [216, 5],
        [217, 4],
        [218, 4],
        [219, 4],
        [220, 5],
        [221, 4],
      ],
      DaysInAyyamiHa,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'DayOfYear',
      [
        [165, 1, 1, 1],
        [170, 1, 1, 1],
        [172, 1, 1, 1],
        [175, 1, 1, 1],
        [173, 18, 1, 17 * 19 + 1],
        [173, 18, 19, 18 * 19],
        [173, AyyamiHaMonth, 1, 18 * 19 + 1],
        [173, 19, 1, 18 * 19 + 5],
        [220, AyyamiHaMonth, 1, 18 * 19 + 1],
        [220, AyyamiHaMonth, 5, 18 * 19 + 5],
        [220, 19, 1, 18 * 19 + 6],
      ],
      DayOfYear,
      customDescriptionBuilder: describeArguments);
  parameterizedTest(
      'EndOfMonth',
      [
        [173, 1, 1, 1, 19],
        [173, 18, 1, AyyamiHaMonth, 4],
        [173, AyyamiHaMonth, 1, AyyamiHaMonth, 4],
        [173, 19, 1, 19, 19],
        [220, 19, 1, 19, 19],
        [220, 4, 5, 4, 19],
        [220, 18, 1, AyyamiHaMonth, 5],
        [220, AyyamiHaMonth, 1, AyyamiHaMonth, 5],
      ],
      EndOfMonth,
      customDescriptionBuilder: describeArguments);
  test('LeapYear', LeapYear);
  test('GetMonthsInYear', GetMonthsInYear);
  parameterizedTest(
      'GetDaysInMonth',
      [
        [180, 1, 19],
        [180, 18, 23],
      ],
      GetDaysInMonth,
      customDescriptionBuilder: describeArguments);
  test('CreateDate_InAyyamiHa', CreateDate_InAyyamiHa);
  parameterizedTest(
      'CreateDate_Invalid',
      [
        [180, -1, 1],
        [180, 1, -1],
        [180, 0, 0],
        [180, 0, 5],
        [182, 0, 6],
        [180, 1, 0],
        [180, 1, 20],
        [180, 20, 1],
      ],
      CreateDate_Invalid,
      customDescriptionBuilder: describeArguments);
  test('BetweenLocalDates_InvalidUnits', BetweenLocalDates_InvalidUnits);
  test('SetYear', SetYear);
  test('BetweenLocalDates_MovingForwardNoLeapYears_WithExactResults',
      BetweenLocalDates_MovingForwardNoLeapYears_WithExactResults);
  test('BetweenLocalDates_MovingForwardNoLeapYears_WithExactResults_2',
      BetweenLocalDates_MovingForwardNoLeapYears_WithExactResults_2);
  test('BetweenLocalDates_MovingForwardInLeapYear_WithExactResults',
      BetweenLocalDates_MovingForwardInLeapYear_WithExactResults);
  test('BetweenLocalDates_MovingBackwardNoLeapYears_WithExactResults',
      BetweenLocalDates_MovingBackwardNoLeapYears_WithExactResults);
  test('BetweenLocalDates_MovingBackward_WithExactResults',
      BetweenLocalDates_MovingBackward_WithExactResults);
  test('BetweenLocalDates_MovingForward_WithJustMonths',
      BetweenLocalDates_MovingForward_WithJustMonths);
  test('BetweenLocalDates_MovingBackward_WithJustMonths',
      BetweenLocalDates_MovingBackward_WithJustMonths);
  test('BetweenLocalDates_AsymmetricForwardAndBackward',
      BetweenLocalDates_AsymmetricForwardAndBackward);
  test('BetweenLocalDates_EndOfMonth', BetweenLocalDates_EndOfMonth);
  test('BetweenLocalDates_OnLeapYear', BetweenLocalDates_OnLeapYear);
  test('BetweenLocalDates_AfterLeapYear', BetweenLocalDates_AfterLeapYear);
  test('Addition_DayCrossingMonthBoundary', Addition_DayCrossingMonthBoundary);
  test('Addition', Addition);
  test('Addition_DayCrossingMonthBoundaryFromAyyamiHa',
      Addition_DayCrossingMonthBoundaryFromAyyamiHa);
  test('Addition_OneYearOnLeapDay', Addition_OneYearOnLeapDay);
  test('Addition_FiveYearsOnLeapDay', Addition_FiveYearsOnLeapDay);
  test('Addition_YearMonthDay', Addition_YearMonthDay);
  test('HelperMethod_BadiDay', HelperMethod_BadiDay);
  test('HelperMethod_BadiMonth', HelperMethod_BadiMonth);
  test('HelperMethod_AsBadiString', HelperMethod_AsBadiString);
}

// For use with CreateBadíʿDate, this is a notional 'month'
// containing Ayyam-i-Ha. The days here are represented in month
// 18 in LocalDate etc.
const int AyyamiHaMonth = 0;

void BadiEpoch() {
  LocalDate badiEpoch = CreateBadiDate(1, 1, 1);

  CalendarSystem gregorian = CalendarSystem.gregorian;
  LocalDate converted = badiEpoch.withCalendar(gregorian);

  LocalDate expected = LocalDate(1844, 3, 21);

  expect(expected.toString(), converted.toString());
}

void UnixEpoch() {
  CalendarSystem badi = CalendarSystem.badi;
  LocalDate unixEpochInBadiCalendar = TimeConstants.unixEpoch
      .inZone(DateTimeZone.utc, badi)
      .localDateTime
      .calendarDate;
  LocalDate expected = CreateBadiDate(126, 16, 2);
  expect(expected, unixEpochInBadiCalendar);
}

void SampleDate() {
  CalendarSystem badiCalendar = CalendarSystem.badi;
  LocalDate iso = LocalDate(2017, 3, 4);
  LocalDate badi = iso.withCalendar(badiCalendar);

  expect(19, BadiMonth(badi));

  expect(Era.bahai, badi.era);
  expect(173, badi.yearOfEra);

  expect(173, badi.year);
  expect(badiCalendar.isLeapYear(173), isFalse);

  expect(4, BadiDay(badi));

  expect(DayOfWeek.saturday, badi.dayOfWeek);
}

void GeneralConversionNearNawRuz(
    int gYear, int gMonth, int gDay, int bYear, int bMonth, int bDay) {
  // create in the Badíʿ calendar
  var bDate = CreateBadiDate(bYear, bMonth, bDay);
  var gDate = bDate.withCalendar(CalendarSystem.gregorian);
  expect(gYear, gDate.year);
  expect(gMonth, gDate.monthOfYear);
  expect(gDay, gDate.dayOfMonth);

  // convert to the Badíʿ calendar
  var bDate2 = LocalDate(gYear, gMonth, gDay).withCalendar(CalendarSystem.badi);
  expect(bYear, bDate2.year);
  expect(bMonth, BadiMonth(bDate2));
  expect(bDay, BadiDay(bDate2));
}

void SpecialCases(
    int gYear, int gMonth, int gDay, int bYear, int bMonth, int bDay) {
  // create in test calendar
  var bDate = CreateBadiDate(bYear, bMonth, bDay);

  // convert to gregorian
  var gDate = bDate.withCalendar(CalendarSystem.gregorian);

  expect('$gYear-$gMonth-$gDay',
      "${gDate.year}-${gDate.monthOfYear}-${gDate.dayOfMonth}");

  // create in gregorian
  // convert to test calendar
  var gDate2 = LocalDate(gYear, gMonth, gDay);
  var bDate2 = gDate2.withCalendar(CalendarSystem.badi);

  expect('$bYear-$bMonth-$bDay',
      "${bDate2.year}-${BadiMonth(bDate2)}-${BadiDay(bDate2)}");
}

void GeneralWtoG(
    int bYear, int bMonth, int bDay, int gYear, int gMonth, int gDay) {
  // create in this calendar
  var bDate = CreateBadiDate(bYear, bMonth, bDay);
  var gDate = bDate.withCalendar(CalendarSystem.gregorian);
  expect(gYear, gDate.year);
  expect(gMonth, gDate.monthOfYear);
  expect(gDay, gDate.dayOfMonth);

  // convert to this calendar
  var bDate2 = LocalDate(gYear, gMonth, gDay).withCalendar(CalendarSystem.badi);
  expect(bYear, bDate2.year);
  expect(bMonth, BadiMonth(bDate2));
  expect(bDay, BadiDay(bDate2));
}

void DaysInAyyamiHa(int bYear, int days) {
  expect(days, BadiYearMonthDayCalculator.getDaysInAyyamiHa(bYear));
}

void DayOfYear(int bYear, int bMonth, int bDay, int dayOfYear) {
  var badi = BadiYearMonthDayCalculator();
  expect(
      dayOfYear,
      badi.getDayOfYear(
          ILocalDate.yearMonthDay(CreateBadiDate(bYear, bMonth, bDay))));
}

// Cannot use EndOfMonth with Ayyam-i-Ha because they are internally stored as days in month 18.
// In Ayyam-i-Ha, EndOfMonth should throw an exception or return the last day of Ayyam-i-Ha.
// In this implementation, it will always return the last day of the month 18.
void EndOfMonth(int year, int month, int day, int eomMonth, int eomDay) {
  var start = CreateBadiDate(year, month, day);
  var end = CreateBadiDate(year, eomMonth, eomDay);
  expect(AsBadiString(end), AsBadiString(DateAdjusters.endOfMonth(start)));
}

void LeapYear() {
  var calendar = CalendarSystem.badi;
  expect(calendar.isLeapYear(172), isFalse);
  expect(calendar.isLeapYear(173), isFalse);
  expect(calendar.isLeapYear(207), isTrue);
  expect(calendar.isLeapYear(220), isTrue);
}

void GetMonthsInYear() {
  var calendar = CalendarSystem.badi;
  expect(19, calendar.getMonthsInYear(180));
}

void GetDaysInMonth(int year, int month, int expectedDays) {
  var calendar = CalendarSystem.badi;
  expect(expectedDays, calendar.getDaysInMonth(year, month));
}

void CreateDate_InAyyamiHa() {
  var d1 = CreateBadiDate(180, 0, 3);
  var d3 = CreateBadiDate(180, 18, 22);

  expect(d1, d3);
}

void CreateDate_Invalid(int year, int month, int day) {
  expect(() => CreateBadiDate(year, month, day), throwsRangeError);
}

// Period related tests
final LocalDate TestDate1_167_5_15 = CreateBadiDate(167, 5, 15);
final LocalDate TestDate1_167_6_7 = CreateBadiDate(167, 6, 7);
final LocalDate TestDate2_167_Ayyam_4 = CreateBadiDate(167, AyyamiHaMonth, 4);
final LocalDate TestDate3_168_Ayyam_5 = CreateBadiDate(168, AyyamiHaMonth, 5);

void BetweenLocalDates_InvalidUnits() {
  expect(
      () => Period.differenceBetweenDates(
          TestDate1_167_5_15, TestDate2_167_Ayyam_4, PeriodUnits.none),
      throwsArgumentError);
  expect(
      () => Period.differenceBetweenDates(
          TestDate1_167_5_15, TestDate2_167_Ayyam_4, const PeriodUnits(-1)),
      throwsArgumentError);
  expect(
      () => Period.differenceBetweenDates(
          TestDate1_167_5_15, TestDate2_167_Ayyam_4, PeriodUnits.allTimeUnits),
      throwsArgumentError);
  expect(
      () => Period.differenceBetweenDates(TestDate1_167_5_15,
          TestDate2_167_Ayyam_4, PeriodUnits.years | PeriodUnits.hours),
      throwsArgumentError);
}

void SetYear() {
  // crafted to test SetYear with 0
  var d1 = CreateBadiDate(180, 1, 1);
  LocalDate result = d1 + const Period(years: 0);
  expect(180, result.year);
}

void BetweenLocalDates_MovingForwardNoLeapYears_WithExactResults() {
  Period actual =
      Period.differenceBetweenDates(TestDate1_167_5_15, TestDate1_167_6_7);
  Period expected = const Period(days: 11);
  expect(expected, actual);
}

void BetweenLocalDates_MovingForwardNoLeapYears_WithExactResults_2() {
  Period actual =
      Period.differenceBetweenDates(TestDate1_167_5_15, TestDate2_167_Ayyam_4);
  Period expected = const Period(months: 13) + const Period(days: 8);
  expect(expected, actual);
}

void BetweenLocalDates_MovingForwardInLeapYear_WithExactResults() {
  Period actual =
      Period.differenceBetweenDates(TestDate1_167_5_15, TestDate3_168_Ayyam_5);
  Period expected =
      const Period(years: 1) + const Period(months: 13) + const Period(days: 9);
  expect(expected, actual);
}

void BetweenLocalDates_MovingBackwardNoLeapYears_WithExactResults() {
  Period actual =
      Period.differenceBetweenDates(TestDate2_167_Ayyam_4, TestDate1_167_5_15);
  Period expected = const Period(months: -13) + const Period(days: -8);
  expect(expected, actual);
}

void BetweenLocalDates_MovingBackward_WithExactResults() {
  // should be -1y -13m -9d
  // but system first moves back a year, and in that year, the last day of Ayyam-i-Ha is day 4
  // from there, it is -13m -8d

  Period expected = const Period(years: -1) +
      const Period(months: -13) +
      const Period(days: -8);
  Period actual =
      Period.differenceBetweenDates(TestDate3_168_Ayyam_5, TestDate1_167_5_15);
  expect(expected, actual);
}

void BetweenLocalDates_MovingForward_WithJustMonths() {
  Period actual = Period.differenceBetweenDates(
      TestDate1_167_5_15, TestDate3_168_Ayyam_5, PeriodUnits.months);
  Period expected = const Period(months: 32);
  expect(expected, actual);
}

void BetweenLocalDates_MovingBackward_WithJustMonths() {
  Period actual = Period.differenceBetweenDates(
      TestDate3_168_Ayyam_5, TestDate1_167_5_15, PeriodUnits.months);
  Period expected = const Period(months: -32);
  expect(expected, actual);
}

void BetweenLocalDates_AsymmetricForwardAndBackward() {
  LocalDate d1 = CreateBadiDate(166, 18, 4);
  LocalDate d2 = CreateBadiDate(167, 1, 10);

  // spanning Ayyam-i-Ha - not counted as a month
  expect(const Period(months: 2) + const Period(days: 6),
      Period.differenceBetweenDates(d1, d2));
  expect(const Period(months: -2) + const Period(days: -6),
      Period.differenceBetweenDates(d2, d1));
}

void BetweenLocalDates_EndOfMonth() {
  LocalDate d1 = CreateBadiDate(171, 5, 19);
  LocalDate d2 = CreateBadiDate(171, 6, 19);
  expect(const Period(months: 1), Period.differenceBetweenDates(d1, d2));
  expect(const Period(months: -1), Period.differenceBetweenDates(d2, d1));
}

void BetweenLocalDates_OnLeapYear() {
  LocalDate d1 = LocalDate(2012, 2, 29).withCalendar(CalendarSystem.badi);
  LocalDate d2 = LocalDate(2013, 2, 28).withCalendar(CalendarSystem.badi);

  expect('168-0-4', AsBadiString(d1));
  expect('169-0-3', AsBadiString(d2));

  expect(const Period(months: 19) + const Period(days: 18),
      Period.differenceBetweenDates(d1, d2));
}

void BetweenLocalDates_AfterLeapYear() {
  LocalDate d1 = CreateBadiDate(180, 19, 5);
  LocalDate d2 = CreateBadiDate(181, 19, 5);
  expect(const Period(years: 1), Period.differenceBetweenDates(d1, d2));
  expect(const Period(years: -1), Period.differenceBetweenDates(d2, d1));
}

void Addition_DayCrossingMonthBoundary() {
  LocalDate start = CreateBadiDate(182, 4, 13);
  LocalDate result = start + const Period(days: 10);
  expect(CreateBadiDate(182, 5, 4), result);
}

void Addition() {
  var start = CreateBadiDate(182, 1, 1);

  var result = start + const Period(days: 3);
  expect(CreateBadiDate(182, 1, 4), result);

  result = start + const Period(days: 20);
  expect(CreateBadiDate(182, 2, 2), result);
}

void Addition_DayCrossingMonthBoundaryFromAyyamiHa() {
  var start = CreateBadiDate(182, AyyamiHaMonth, 3);

  var result = start + const Period(days: 10);
  // in 182, Ayyam-i-Ha has 5 days
  expect(CreateBadiDate(182, 19, 8), result);
}

void Addition_OneYearOnLeapDay() {
  LocalDate start = CreateBadiDate(182, AyyamiHaMonth, 5);
  LocalDate result = start + const Period(years: 1);
  // Ayyam-i-Ha 5 becomes Ayyam-i-Ha 4
  expect(CreateBadiDate(183, AyyamiHaMonth, 4), result);
}

void Addition_FiveYearsOnLeapDay() {
  LocalDate start = CreateBadiDate(182, AyyamiHaMonth, 5);
  LocalDate result = start + const Period(years: 5);
  expect(CreateBadiDate(187, AyyamiHaMonth, 5), result);
}

void Addition_YearMonthDay() {
  // One year, one month, two days
  Period period =
      const Period(years: 1) + const Period(months: 1) + const Period(days: 2);
  LocalDate start = CreateBadiDate(171, 1, 19);
  // Periods are added in order, so this becomes...
  // Add one year: 172.1.19
  // Add one month: 172.2.19
  // Add two days: 172.3.2
  LocalDate result = start + period;
  expect(CreateBadiDate(172, 3, 2), result);
}

/// <summary>
/// Create a <see cref='LocalDate'/> in the Badíʿ calendar, treating 0
/// as the month containing Ayyam-i-Ha.
/// </summary>
/// <param name='year'>Year in the Badíʿ calendar</param>
/// <param name='month'>Month (use 0 for Ayyam-i-Ha)</param>
/// <param name='day'>Day in month</param>
LocalDate CreateBadiDate(int year, int month, int day) {
  if (month == AyyamiHaMonth) {
    Preconditions.checkArgumentRange(
        'day', day, 1, BadiYearMonthDayCalculator.getDaysInAyyamiHa(year));
    // Move Ayyam-i-Ha days to fall after the last day of month 18.
    month = BadiYearMonthDayCalculator.month18;
    day += BadiYearMonthDayCalculator.daysInMonth;
  }
  return LocalDate(year, month, day, CalendarSystem.badi);
}

/// <summary>
/// Return the day of this month, treating Ayyam-i-Ha as a separate month.
/// </summary>
int BadiDay(LocalDate input) {
  Preconditions.checkArgument(input.calendar == CalendarSystem.badi, 'input',
      "Only valid when using the Badíʿ calendar");

  if (input.monthOfYear == BadiYearMonthDayCalculator.month18 &&
      input.dayOfMonth > BadiYearMonthDayCalculator.daysInMonth) {
    return input.dayOfMonth - BadiYearMonthDayCalculator.daysInMonth;
  }
  return input.dayOfMonth;
}

/// <summary>
/// Return the month of this date. If in Ayyam-i-Ha, returns 0.
/// </summary>
int BadiMonth(LocalDate input) {
  Preconditions.checkArgument(input.calendar == CalendarSystem.badi, 'input',
      "Only valid when using the Badíʿ calendar");

  if (input.monthOfYear == BadiYearMonthDayCalculator.month18 &&
      input.dayOfMonth > BadiYearMonthDayCalculator.daysInMonth) {
    return AyyamiHaMonth;
  }
  return input.monthOfYear;
}

/// <summary>
/// Get a text representation of the date.
/// </summary>
@internal
String AsBadiString(LocalDate input) {
  var year = input.year;
  var month = BadiMonth(input);
  var day = BadiDay(input);

  return '$year-$month-$day';
}

void HelperMethod_BadiDay() {
  // ensure that this helper method is working
  expect(BadiDay(CreateBadiDate(180, 10, 10)), 10);
  expect(BadiDay(CreateBadiDate(180, 18, 19)), 19);
  expect(BadiDay(CreateBadiDate(180, 0, 3)), 3);
  expect(BadiDay(CreateBadiDate(180, 19, 1)), 1);
}

void HelperMethod_BadiMonth() {
  // ensure that this helper method is working
  expect(BadiMonth(CreateBadiDate(180, 10, 10)), 10);
  expect(BadiMonth(CreateBadiDate(180, 18, 19)), 18);
  expect(BadiMonth(CreateBadiDate(180, 0, 3)), 0);
  expect(BadiMonth(CreateBadiDate(180, 19, 1)), 19);
}

void HelperMethod_AsBadiString() {
  // ensure that this helper method is working
  expect(AsBadiString(CreateBadiDate(180, 10, 10)), '180-10-10');
  expect(AsBadiString(CreateBadiDate(180, 18, 19)), '180-18-19');
  expect(AsBadiString(CreateBadiDate(180, 0, 3)), '180-0-3');
  expect(AsBadiString(CreateBadiDate(180, 19, 1)), '180-19-1');
}
