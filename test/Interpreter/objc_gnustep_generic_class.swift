// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_generic_class %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepGenericClass

// Under the GNUstep runtime, each instantiation of a generic class with
// Objective-C ancestry gets a class record when its metadata is
// initialized, as a non-generic class gets one from the compiler, so it can
// be allocated and messaged.  So does a non-generic subclass of one.

class Holder<Value>: NSObject, Tagged, Kinded {
  var value: Value
  var count: Int = 1

  init(_ value: Value) {
    self.value = value
    super.init()
  }

  @objc func tag() -> Int { return 42 }
  @objc class func kind() -> Int { return 7 }

  deinit { print("deinit \(value)") }
}

final class Derived<Value>: Holder<Value> {
  var extra: Int = 5
  // NSObject's ivar is called isa too.
  var isa: Int = 9
  override func tag() -> Int { return super.tag() + extra }
}

final class IntHolder: Holder<Int> {
  var factor: Int = 10
  override func tag() -> Int { return value * factor }
}

// More stored properties than the runtime keeps names for inline.
final class Wide<Value>: NSObject {
  var a = 1, b = 2, c = 3, d = 4, e = 5
  var f = 6, g = 7, h = 8, i = 9
  var value: Value
  init(_ value: Value) { self.value = value; super.init() }
}

func name(_ cls: AnyClass?) -> String {
  return String(cString: class_getName(cls))
}

// CHECK: 3 1
let number = Holder(3)
print(number.value, number.count)

// Messages from Objective-C reach the instance and class methods.
// CHECK-NEXT: 42 7
print((number as Tagged).tag(), (Holder<Int>.self as Kinded.Type).kind())

// Each instantiation has its own class record, below NSObject's, which
// conforms to the class's protocols.
// CHECK-NEXT: {{_TtGC[0-9]+[A-Za-z_]+6HolderSi_}} {{_TtGC[0-9]+[A-Za-z_]+6HolderSS_}} NSObject 1
let text = Holder("a string that is not small")
print(name(object_getClass(number)), name(object_getClass(text)),
      name(class_getSuperclass(object_getClass(number))),
      class_conformsToProtocol(object_getClass(text), Tagged.self))

// Stored properties do not overlap.
text.count = 2
text.value += "!"
// CHECK-NEXT: a string that is not small! 2
print(text.value, text.count)

// A generic subclass of a generic class, with an ivar whose name an
// ancestor's ivar has.
// CHECK-NEXT: 47 5 9 x
let derived = Derived("x")
print((derived as Tagged).tag(), derived.extra, derived.isa, derived.value)
// CHECK-NEXT: true
print(name(class_getSuperclass(object_getClass(derived))) ==
      name(object_getClass(text)))

// A non-generic subclass of an instantiation.
// CHECK-NEXT: 40 10 4 true
let intHolder = IntHolder(4)
print((intHolder as Tagged).tag(), intHolder.factor, intHolder.value,
      name(class_getSuperclass(object_getClass(intHolder))) ==
        name(object_getClass(number)))

// CHECK-NEXT: 1 5 9 w
let wide = Wide("w")
print(wide.a, wide.e, wide.i, wide.value)

// CHECK-NEXT: deinit 3
// CHECK-NEXT: done
do {
  let temporary = Holder(3)
  _ = temporary.tag()
}
print("done")
