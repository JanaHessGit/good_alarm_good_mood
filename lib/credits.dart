import 'package:flutter/foundation.dart';

import 'surprise/song_player.dart';

/// Shown on the "About & licences" page. Keep in sync with pubspec.yaml.
const appVersion = '0.1.0';

/// Adds the app's own notes to Flutter's licence page. The licences of all
/// packages (Flutter, alarm, audioplayers, ...) are added by Flutter itself.
void registerCredits() {
  LicenseRegistry.addLicense(() async* {
    final stations = SongPlayer.stations.map((s) => s.text).join(', ');
    yield LicenseEntryWithLineBreaks(
      ['Rise & Surprise'],
      'Alarm sounds, the wake-up song "Sunny Side Up" and the waiting music '
      'were made for Rise & Surprise.\n\n'
      'Radio streams are provided by the stations ($stations). '
      'All rights to the programmes belong to the stations.\n\n'
      'The spoken voice is the text-to-speech engine installed on the phone.',
    );
    yield const LicenseEntryWithLineBreaks(
      ['alarm (modified copy)'],
      'Rise & Surprise contains a modified copy of the alarm package, '
      'version 5.15.0, by Gautier de Lataillade (MIT licence). '
      'The changes are described in packages/alarm/DAWNBOX.md.',
    );
  });
}
