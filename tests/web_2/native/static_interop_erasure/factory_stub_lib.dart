// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@JS()
library factory_stub_lib;

import 'package:js/js.dart';

import 'factory_stub_test.dart';

@JS('NativeClass')
@staticInterop
class StaticNativeClassCopy {
  external StaticNativeClassCopy();
  factory StaticNativeClassCopy.nestedFactory() {
    StaticNativeClass.nestedFactory();
    return StaticNativeClassCopy();
  }
}
