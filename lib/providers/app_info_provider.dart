import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

// version is x.y.z where z is the commit count at the time this release
// was cut (see pubspec.yaml) - not live-computed, since a shipped app has
// no access to the build machine's git history.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
});
