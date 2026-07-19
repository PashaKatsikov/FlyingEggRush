/// Response from the config endpoint after normalisation.
///
/// [granted] is true only when the server returned `{"ok": true}` AND a
/// non-empty `url`. Any transport or format failure yields a negative reply
/// (see the "Response — failure" invariant in gray_flow_guide.md).
class DispatchReply {
  final bool granted;
  final String? destination;
  final int? expiresAt;

  const DispatchReply.granted(String url, {this.expiresAt})
      : granted = true,
        destination = url;

  const DispatchReply.denied()
      : granted = false,
        destination = null,
        expiresAt = null;

  bool get hasDestination => granted && (destination?.isNotEmpty ?? false);
}
