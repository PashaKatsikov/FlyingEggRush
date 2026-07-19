/// Response from the config endpoint after normalisation.
///
/// Three terminal states:
/// * [granted] `true`  — server returned `{"ok":true, "url":...}`.
/// * [granted] `false` + [transportFailed] `false` — server responded, told us
///   there is no URL (organic → game).
/// * [transportFailed] `true` — the request never reached the server (DNS,
///   TCP, TLS, timeout). We MUST NOT commit `mode=game` on this state: a
///   flaky first-launch network must keep the install `fresh` and show the
///   NoWind screen instead (see gray_flow_lessons.md invariant #2/§Fresh).
class DispatchReply {
  final bool granted;
  final String? destination;
  final int? expiresAt;
  final bool transportFailed;

  const DispatchReply.granted(String url, {this.expiresAt})
      : granted = true,
        destination = url,
        transportFailed = false;

  const DispatchReply.denied()
      : granted = false,
        destination = null,
        expiresAt = null,
        transportFailed = false;

  const DispatchReply.transportError()
      : granted = false,
        destination = null,
        expiresAt = null,
        transportFailed = true;

  bool get hasDestination => granted && (destination?.isNotEmpty ?? false);
}
