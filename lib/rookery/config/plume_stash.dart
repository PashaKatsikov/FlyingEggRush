import '../core/plume_cipher.dart';

/// Encoded byte-arrays for every network / legal secret in the gray flow.
///
/// Do NOT hand-edit these values. To rotate:
///   1) update plaintext in `tool/encode_feg_plumes.dart`
///   2) run `dart run tool/encode_feg_plumes.dart`
///   3) copy the printed arrays back here, verify VERIFY block matches.
class PlumeStash {
  static String get configEndpoint => PlumeCipher.unwrapPlumes(_configEndpoint);
  static String get appsFlyerDevKey => PlumeCipher.unwrapPlumes(_appsFlyerKey);
  static String get firebaseProjectNumber => PlumeCipher.unwrapPlumes(_firebaseProjectNumber);
  static String get gcdBaseUrl => PlumeCipher.unwrapPlumes(_gcdBaseUrl);
  static String get privacyUrl => PlumeCipher.unwrapPlumes(_privacyUrl);
  static String get supportUrl => PlumeCipher.unwrapPlumes(_supportUrl);

  static const List<int> _configEndpoint = <int>[
    70, 158, 173, 159, 254, 135, 153, 92, 161, 162, 178, 181, 82, 73, 56, 250,
    13, 168, 81, 19, 138, 52, 222, 137, 49, 215, 212, 46, 118, 161, 177, 57,
    23, 79, 103, 246,
  ];

  static const List<int> _appsFlyerKey = <int>[
    118, 130, 163, 133, 229, 251, 217, 75, 157, 157, 136, 148, 95, 73, 52, 243,
    9, 151, 126, 43, 144, 89,
  ];

  static const List<int> _firebaseProjectNumber = <int>[
    28, 220, 238, 218, 180, 138, 128, 71, 246, 247, 252, 232,
  ];

  static const List<int> _gcdBaseUrl = <int>[
    70, 158, 173, 159, 254, 135, 153, 92, 160, 173, 175, 175, 88, 69, 115, 252,
    26, 170, 87, 6, 142, 99, 216, 148, 114, 155, 216, 44,
  ];

  static const List<int> _privacyUrl = <int>[
    70, 158, 173, 159, 254, 135, 153, 92, 161, 162, 178, 181, 82, 73, 56, 250,
    13, 168, 81, 19, 138, 52, 222, 137, 49, 215, 199, 51, 113, 177, 185, 61,
    64, 18, 127, 233, 144, 70, 30, 56, 68, 244, 25, 227, 82,
  ];

  static const List<int> _supportUrl = <int>[
    70, 158, 173, 159, 254, 135, 153, 92, 161, 162, 178, 181, 82, 73, 56, 250,
    13, 168, 81, 19, 138, 52, 222, 137, 49, 215, 196, 52, 104, 183, 183, 44,
    77, 17, 103, 242, 145, 67,
  ];
}
