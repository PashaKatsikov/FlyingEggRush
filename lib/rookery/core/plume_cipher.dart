import 'dart:convert';

/// Symmetric byte-stream cipher for the encoded secrets living in
/// `rookery_config.dart` + `plume_stash.dart`.
///
/// Algorithm: RC4-family (KSA + PRGA) keyed on the ASCII salt below.
/// Every project MUST rotate the salt (and ideally the algorithm family)
/// before shipping — identical machine code across sibling apps clusters
/// the portfolio.
class PlumeCipher {
  // FINGERPRINT: unique per-project salt, do not reuse.
  static const String _flightSalt = 'Rk9-Zt4qPnMv73Wc';

  static List<int> _prepareState() {
    final s = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      s[i] = i;
    }
    final key = utf8.encode(_flightSalt);
    var j = 0;
    for (var i = 0; i < 256; i++) {
      j = (j + s[i] + key[i % key.length]) & 0xff;
      final t = s[i];
      s[i] = s[j];
      s[j] = t;
    }
    return s;
  }

  static List<int> _stream(List<int> input) {
    final s = _prepareState();
    var i = 0;
    var j = 0;
    final out = List<int>.filled(input.length, 0);
    for (var n = 0; n < input.length; n++) {
      i = (i + 1) & 0xff;
      j = (j + s[i]) & 0xff;
      final t = s[i];
      s[i] = s[j];
      s[j] = t;
      final k = s[(s[i] + s[j]) & 0xff];
      out[n] = input[n] ^ k;
    }
    return out;
  }

  /// Decode an encoded byte array to plaintext UTF-8.
  static String unwrapPlumes(List<int> bytes) {
    return utf8.decode(_stream(bytes));
  }

  /// Encode a UTF-8 plaintext to a byte array (used only by the encoder tool).
  static List<int> foldPlumes(String plaintext) {
    return _stream(utf8.encode(plaintext));
  }
}
