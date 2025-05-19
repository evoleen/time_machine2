import 'package:test/test.dart';
import '../tzdb/tokens.dart';

void main() {
  group('Tokens', () {
    void assertTokensEqual(List<String> expectedTokens, Tokens tokens) {
      for (int i = 0; i < expectedTokens.length; i++) {
        expect(tokens.hasNextToken, isTrue,
            reason: 'Not enough items in enumeration');
        var actual = tokens.nextToken(i.toString());
        expect(actual, isNotNull,
            reason: 'The enumeration item at index [$i] is null');
        expect(actual, equals(expectedTokens[i]),
            reason: 'The enumeration item at index [$i] is not correct');
      }
      expect(tokens.hasNextToken, isFalse,
          reason: 'Too many items in enumeration');
    }

    test('tokenize empty string returns empty list', () {
      assertTokensEqual([], Tokens.tokenize(''));
    });

    test('tokenize single word', () {
      assertTokensEqual(['One'], Tokens.tokenize('One'));
    });

    test('tokenize multiple words with various whitespace', () {
      assertTokensEqual(
        ['One', 'Two', 'Three', 'Four'],
        Tokens.tokenize('One Two  \tThree\n\nFour   '),
      );
    });

    test('tokenize with leading whitespace includes empty token', () {
      assertTokensEqual(
        ['', 'One', 'Two', 'Three', 'Four'],
        Tokens.tokenize('  One Two  \tThree\n\nFour   '),
      );
    });

    test('tokenize with quoted strings', () {
      assertTokensEqual(
        ['One', 'TwoA TwoB', 'Three'],
        Tokens.tokenize('One "TwoA TwoB" Three'),
      );
    });

    test('tokenize with quotes within word', () {
      assertTokensEqual(
        ['One', 'XTwoA TwoBY', 'Three'],
        Tokens.tokenize('One X"TwoA TwoB"Y Three'),
      );
    });

    test('tokenize preserves spaces in quotes', () {
      assertTokensEqual(
        ['One', ' Spaced ', 'Three'],
        Tokens.tokenize('One " Spaced " Three'),
      );
    });

    // Note: I've omitted the ParseOffset tests since they appear to be testing
    // a different class (ParserHelper) that wasn't shown in the provided code.
    // Those tests should be implemented separately when porting the ParserHelper class.
  });
}
