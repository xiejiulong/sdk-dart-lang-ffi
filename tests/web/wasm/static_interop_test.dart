// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
external void eval(String code);

@JS('JSClass')
@staticInterop
class StaticJSClass {
  external factory StaticJSClass.factory(String foo);
}

extension StaticJSClassMethods on StaticJSClass {
  external String foo;
  external String sum(String a, String? b, String c);
  external void doublifyNumbers();
  external set nonNullableInt(int d);
  external int get nonNullableInt;
  external set nullableInt(int? d);
  external int? get nullableInt;
  external int nonNullableIntReturnMethod();
  external int? nullableIntReturnMethod(bool returnNull);
  external String doSum1Or2(String a, [String? b]);
  external String doSumUpTo2([String? a, String? b]);
  external String doSum1Or2NonNull(String a, [String b = 'bar']);
  external String doSumUpTo2NonNull([String a = 'foo', String b = 'bar']);
}

void createClassTest() {
  eval(r'''
    globalThis.JSClass = function(foo) {
      this.foo = foo;
      this.nonNullableInt = 6;
      this.nonNullableIntReturnMethod = function() {
        return 7;
      }
      this.nullableIntReturnMethod = function(returnNull) {
        if (returnNull) {
          return null;
        } else {
          return 8;
        }
      }
      this.sum = function(a, b, c) {
        if (b == null) b = ' ';
        return a + b + c;
      }
      this.doublifyNumbers = function() {
        this.nonNullableInt = 60.5;
        this.nullableInt = 100.5;
      }
      this.doSum1Or2 = function(a, b) {
        return a + (b ?? 'bar');
      }
      this.doSumUpTo2 = function(a, b) {
        return (a ?? 'foo') + (b ?? 'bar');
      }
      this.doSum1Or2NonNull = function(a, b) {
        return a + b;
      }
      this.doSumUpTo2NonNull = function(a, b) {
        return a + b;
      }
    }
  ''');
  final foo = StaticJSClass.factory('foo');
  Expect.equals('foo', foo.foo);
  foo.foo = 'bar';
  Expect.equals('bar', foo.foo);
  Expect.equals('hello world!!', foo.sum('hello', null, 'world!!'));
  Expect.equals(null, foo.nullableInt);
  foo.nullableInt = 5;
  Expect.equals(5, foo.nullableInt);
  Expect.equals(6, foo.nonNullableInt);
  foo.nonNullableInt = 16;
  Expect.equals(16, foo.nonNullableInt);
  Expect.equals(7, foo.nonNullableIntReturnMethod());
  Expect.equals(8, foo.nullableIntReturnMethod(false));
  Expect.equals(null, foo.nullableIntReturnMethod(true));
  foo.doublifyNumbers();
  Expect.equals(100, foo.nullableInt);
  Expect.equals(60, foo.nonNullableInt);

  Expect.equals('foobar', foo.doSum1Or2('foo'));
  Expect.equals('foobar', foo.doSum1Or2('foo', 'bar'));
  Expect.equals('foobar', foo.doSumUpTo2());
  Expect.equals('foobar', foo.doSumUpTo2('foo'));
  Expect.equals('foobar', foo.doSumUpTo2('foo', 'bar'));

  Expect.equals('foobar', foo.doSum1Or2NonNull('foo'));
  Expect.equals('foobar', foo.doSum1Or2NonNull('foo', 'bar'));
  Expect.equals('foobar', foo.doSumUpTo2NonNull());
  Expect.equals('foobar', foo.doSumUpTo2NonNull('foo'));
  Expect.equals('foobar', foo.doSumUpTo2NonNull('foo', 'bar'));
}

@JS('JSClass.NestedJSClass')
@staticInterop
class NestedJSClass {
  external factory NestedJSClass.factory(String foo);
}

extension NestedJSClassMethods on NestedJSClass {
  external String foo;
}

void createClassWithNestedJSNameTest() {
  eval(r'''
    globalThis.JSClass = {};
    globalThis.JSClass.NestedJSClass = function(foo) {
      this.foo = foo;
    };
  ''');
  final foo = NestedJSClass.factory('foo');
  Expect.equals(foo.foo, 'foo');
}

@JS('JSParent')
@staticInterop
class StaticJSParent {
  external factory StaticJSParent.factory();
}

extension StaticJSParentMethods on StaticJSParent {
  external set child(StaticJSChild child);
  external String childsFoo();
}

@JS('JSChild')
@staticInterop
class StaticJSChild {
  external factory StaticJSChild.factory();
}

extension StaticJSChildMethods on StaticJSChild {
  external set foo(String s);
}

void setInteropPropertyTest() {
  eval(r'''
    globalThis.JSParent = function() {
      this.child = null;
      this.childsFoo = () => {
        return this.child.foo;
      }
    }

    globalThis.JSChild = function() {
      this.foo = null;
    }
  ''');

  final parent = StaticJSParent.factory();
  final child = StaticJSChild.factory();
  parent.child = child;
  child.foo = 'boo';
  Expect.equals('boo', parent.childsFoo());
}

class DartObject {
  final int x;

  DartObject(this.x);
}

@JS('JSHolder')
@staticInterop
class StaticJSHolder {
  external factory StaticJSHolder.factory(DartObject object);
}

extension StaticJSHolderMethods on StaticJSHolder {
  external DartObject foo;
}

void setDartObjectPropertyTest() {
  eval(r'''
    globalThis.JSHolder = function(foo) {
      this.foo = foo;
    }
  ''');
  final traveler = DartObject(4);
  final holder = StaticJSHolder.factory(traveler);
  Expect.equals(traveler, holder.foo);
}

@JS()
external String get foo;

@JS()
external String? get blu;

@JS('')
external void set baz(String);

@JS('boo.bar')
external String get bam;

@JS('bar')
external String fooBar(String);

void topLevelMethodsTest() {
  eval(r'''
    globalThis.foo = 'bar';
    globalThis.baz = null;
    globalThis.boo = {
      'bar': 'jam'
    }
    globalThis.bar = function(string) {
      return string + ' ' + globalThis.baz;
    }
  ''');

  Expect.equals(foo, 'bar');
  Expect.equals(blu, null);
  Expect.equals(bam, 'jam');
  baz = 'world!';
  Expect.equals(fooBar('hello'), 'hello world!');
}

@JS()
@anonymous
@staticInterop
class AnonymousJSClass {
  external factory AnonymousJSClass.factory(
      {String? foo, String bar = 'baz', String? bleep});
}

extension AnonymousJSClassExtension on AnonymousJSClass {
  external String? get foo;
  external String get bar;
  external String? get bleep;
}

void anonymousTest() {
  final anonymousJSClass = AnonymousJSClass.factory(foo: 'boo');
  Expect.equals('boo', anonymousJSClass.foo);
  Expect.equals('baz', anonymousJSClass.bar);
  Expect.equals(null, anonymousJSClass.bleep);
}

void main() {
  createClassTest();
  createClassWithNestedJSNameTest();
  setInteropPropertyTest();
  setDartObjectPropertyTest();
  topLevelMethodsTest();
  anonymousTest();
}
