import 'dart:async';
import 'dart:convert';

import '../config/rookery_config.dart';
import '../models/dispatch_reply.dart';
import 'debug_flock.dart';
import 'talon_agent.dart';

/// POST the flat AppsFlyer + device body to the config endpoint and
/// normalise the response into a `DispatchReply`.
class DispatchRelay {
  const DispatchRelay();

  Future<DispatchReply> send(Map<String, dynamic> body) async {
    final ua = await TalonAgent.instance.userAgent();
    final uri = Uri.parse(RookeryConfig.configEndpoint);
    flockLog(() => '[FEG.dispatch] POST $uri body=$body');
    try {
      final resp = await TalonAgent.instance.client
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': ua,
            },
            body: jsonEncode(body),
          )
          .timeout(RookeryConfig.configTimeout);
      flockLog(() =>
          '[FEG.dispatch] status=${resp.statusCode} body=${resp.body}');
      if (resp.statusCode != 200) return const DispatchReply.denied();
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map) return const DispatchReply.denied();
      final ok = decoded['ok'] == true;
      if (!ok) return const DispatchReply.denied();
      final url = decoded['url']?.toString();
      if (url == null || url.isEmpty) return const DispatchReply.denied();
      final expiresRaw = decoded['expires'];
      final expires = expiresRaw is int
          ? expiresRaw
          : int.tryParse(expiresRaw?.toString() ?? '');
      return DispatchReply.granted(url, expiresAt: expires);
    } on TimeoutException {
      flockLog(() => '[FEG.dispatch] timeout');
      return const DispatchReply.denied();
    } catch (e) {
      flockLog(() => '[FEG.dispatch] error=$e');
      return const DispatchReply.denied();
    }
  }
}
