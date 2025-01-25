/// Provides a simple string tokenizer that breaks the string into words
/// that are separated by white space.
///
/// Multiple white spaces in a row are treated as one separator.
/// White space at the beginning of the line causes an empty token to be
/// returned as the first token. White space at the end of the line is ignored.
class Tokens {
  /// Represents an empty token list.
  static final List<String> _noTokens = [];

  /// The list of words. This will never be null but may be empty.
  final List<String> _words;

  /// The current index into the words list.
  int _index = 0;

  /// Private constructor for initializing a Tokens instance.
  Tokens._(this._words);

  /// Returns whether this instance has another token.
  bool get hasNextToken => _index < _words.length;

  /// Returns the next token.
  ///
  /// [name] is the name of the token, used in the exception to identify
  /// the missing token.
  ///
  /// Throws [StateError] if there is no next token.
  String nextToken(String name) {
    final result = tryNextToken();
    if (result == null) {
      throw StateError('Missing token: $name');
    }
    return result;
  }

  /// Tries to get the next token.
  ///
  /// Returns the next token if it exists, or `null` otherwise.
  String? tryNextToken() {
    if (hasNextToken) {
      return _words[_index++];
    }
    return null;
  }

  /// Returns an object that contains the list of the whitespace-separated words
  /// in the given string. The string is assumed to be culture-invariant.
  static Tokens tokenize(String text) {
    if (text.isEmpty) {
      return Tokens._(_noTokens);
    }

    text = text.trimRight();
    if (text.isEmpty) {
      return Tokens._(_noTokens);
    }

    final list = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    bool lastCharWasWhitespace = false;

    for (var char in text.runes) {
      final c = String.fromCharCode(char);
      if (c == '"') {
        inQuotes = !inQuotes;
        lastCharWasWhitespace = false;
        continue;
      }
      if (_isWhiteSpace(c) && !inQuotes) {
        if (!lastCharWasWhitespace) {
          list.add(buffer.toString());
          buffer.clear();
          lastCharWasWhitespace = true;
        }
      } else {
        buffer.write(c);
        lastCharWasWhitespace = false;
      }
    }

    if (!lastCharWasWhitespace) {
      list.add(buffer.toString());
    }

    if (inQuotes) {
      throw FormatException('Line has unterminated quotes');
    }

    return Tokens._(list);
  }

  /// Helper method to check if a character is whitespace.
  static bool _isWhiteSpace(String char) {
    return RegExp(r'\s').hasMatch(char);
  }
}
