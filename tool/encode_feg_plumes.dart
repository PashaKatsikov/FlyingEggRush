// Run:  dart run tool/encode_feg_plumes.dart
//
// Prints the encoded byte arrays for every gray-flow secret plus a VERIFY
// block that decodes them back to plaintext. The VERIFY block MUST match
// the plaintext byte-for-byte — copy the arrays into
// `lib/rookery/config/plume_stash.dart`.
//
// If you change `_flightSalt` in `plume_cipher.dart` OR the plaintext below,
// re-run this file and update the arrays.

// ignore: avoid_relative_lib_imports
import '../lib/rookery/core/plume_cipher.dart';

const Map<String, String> _plaintexts = <String, String>{
  'configEndpoint':  'https://flyingeggrush.com/config.php',
  'appsFlyerDevKey': 'XhzjhFo8ZSCHcgincMZKrC',
  'firebaseProjNum': '267597641974',
  'gcdBaseUrl':      'https://gcdsdk.appsflyer.com',
  'privacyUrl':      'https://flyingeggrush.com/privacy-policy.html',
  'supportUrl':      'https://flyingeggrush.com/support.html',
};

String _fmt(List<int> bytes) {
  final b = StringBuffer('const List<int> _bytes = <int>[');
  for (var i = 0; i < bytes.length; i++) {
    if (i % 16 == 0) b.write('\n  ');
    b.write(bytes[i].toString());
    if (i != bytes.length - 1) b.write(', ');
  }
  b.write('\n];');
  return b.toString();
}

void main() {
  for (final entry in _plaintexts.entries) {
    final bytes = PlumeCipher.foldPlumes(entry.value);
    final round = PlumeCipher.unwrapPlumes(bytes);
    final ok = round == entry.value;
    // ignore: avoid_print
    print('\n=== ${entry.key} ===');
    // ignore: avoid_print
    print('plaintext : ${entry.value}');
    // ignore: avoid_print
    print('length    : ${bytes.length}');
    // ignore: avoid_print
    print('bytes     : ${bytes.toString()}');
    // ignore: avoid_print
    print('VERIFY    : $round  ${ok ? '[OK]' : '[FAIL]'}');
    if (!ok) {
      throw StateError('Round-trip failed for ${entry.key}');
    }
  }
  // ignore: avoid_print
  print('\nAll round-trips OK. Paste the bytes into plume_stash.dart.');
  // ignore: avoid_print
  print('(Formatted example for one entry:)');
  // ignore: avoid_print
  print(_fmt(PlumeCipher.foldPlumes(_plaintexts.values.first)));
}
