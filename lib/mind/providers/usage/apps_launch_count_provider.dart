/*
 *
 *  * Copyright (c) 2024 ManoDhyan (https://github.com/techerrorNR)
 *  * Author : Rakesh Yadav (https://github.com/techerrorNR/Manodhyan)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manodhyan/mind/core/services/method_channel_service.dart';

/// Apps launch counts mapped to their package names provider
final appsLaunchCountProvider = FutureProvider.autoDispose<Map<String, int>>(
  (ref) async => await MethodChannelService.instance.getAppsLaunchCount(),
);
