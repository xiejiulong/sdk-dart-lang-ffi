// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.expectation;

/// An expectation represents the expected outcome of a test (or if it should
/// be skipped).
///
/// An expectation belongs to a group, for example, [ExpectationGroup.Fail].
///
/// Each expectation group has a canonical expectation, defined below. You can
/// use the canonical expectation instead of a more specific one. Note this
/// isn't implemented yet.
class Expectation {
  static const Expectation Pass = Expectation("Pass", ExpectationGroup.Pass);

  static const Expectation Crash = Expectation("Crash", ExpectationGroup.Crash);

  static const Expectation Timeout =
      Expectation("Timeout", ExpectationGroup.Timeout);

  static const Expectation Fail = Expectation("Fail", ExpectationGroup.Fail);

  static const Expectation Skip = Expectation("Skip", ExpectationGroup.Skip);

  final String name;

  final ExpectationGroup group;

  const Expectation(this.name, this.group);

  const Expectation.fail(this.name) : group = ExpectationGroup.Fail;

  /// Returns the canonical expectation representing [group]. That is, one of
  /// the above expectations (except for `Meta` which returns `this`).
  Expectation get canonical => fromGroup(group) ?? this;

  String toString() => name;

  static Expectation? fromGroup(ExpectationGroup group) {
    switch (group) {
      case ExpectationGroup.Crash:
        return Expectation.Crash;
      case ExpectationGroup.Fail:
        return Expectation.Fail;
      case ExpectationGroup.Meta:
        return null;
      case ExpectationGroup.Pass:
        return Expectation.Pass;
      case ExpectationGroup.Skip:
        return Expectation.Skip;
      case ExpectationGroup.Timeout:
        return Expectation.Timeout;
    }
  }
}

class ExpectationSet {
  static const ExpectationSet Default = ExpectationSet(<String, Expectation>{
    "pass": Expectation.Pass,
    "crash": Expectation.Crash,
    "timeout": Expectation.Timeout,
    "fail": Expectation.Fail,
    "skip": Expectation.Skip,
    "missingcompiletimeerror":
        Expectation("MissingCompileTimeError", ExpectationGroup.Fail),
    "missingruntimeerror":
        Expectation("MissingRuntimeError", ExpectationGroup.Fail),
    "runtimeerror": Expectation("RuntimeError", ExpectationGroup.Fail),
  });

  final Map<String, Expectation> internalMap;

  const ExpectationSet(this.internalMap);

  Expectation operator [](String name) {
    return internalMap[name.toLowerCase()] ??
        (throw "No expectation named: '$name'.");
  }

  factory ExpectationSet.fromJsonList(List data) {
    Map<String, Expectation> internalMap =
        Map<String, Expectation>.from(Default.internalMap);
    for (Map map in data) {
      String? name;
      String? group;
      map.forEach((_key, _value) {
        String key = _key;
        String value = _value;
        switch (key) {
          case "name":
            name = value;
            break;

          case "group":
            group = value;
            break;

          default:
            throw "Unrecoginized key: '$key' in '$map'.";
        }
      });
      if (name == null) {
        throw "No name provided in '$map'";
      }
      if (group == null) {
        throw "No group provided in '$map'";
      }
      Expectation expectation = Expectation(name!, groupFromString(group!));
      name = name!.toLowerCase();
      if (internalMap.containsKey(name)) {
        throw "Duplicated expectation name: '$name'.";
      }
      internalMap[name!] = expectation;
    }
    return ExpectationSet(internalMap);
  }
}

enum ExpectationGroup {
  Crash,
  Fail,
  Meta,
  Pass,
  Skip,
  Timeout,
}

ExpectationGroup groupFromString(String name) {
  switch (name) {
    case "Crash":
      return ExpectationGroup.Crash;
    case "Fail":
      return ExpectationGroup.Fail;
    case "Meta":
      return ExpectationGroup.Meta;
    case "Pass":
      return ExpectationGroup.Pass;
    case "Skip":
      return ExpectationGroup.Skip;
    case "Timeout":
      return ExpectationGroup.Timeout;
    default:
      throw "Unrecognized group: '$name'.";
  }
}
