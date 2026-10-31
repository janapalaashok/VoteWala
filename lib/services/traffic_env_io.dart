import 'dart:io';

import 'traffic_env.dart';

TrafficEnv readTrafficEnv() => TrafficEnv(
      platform: Platform.isIOS ? 'ios' : 'android',
      osName: Platform.isIOS ? 'iOS' : 'Android',
      timeZone: DateTime.now().timeZoneName,
      language: Platform.localeName,
    );
