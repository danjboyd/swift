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
// be allocated and messaged.

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
  override func tag() -> Int { return super.tag() + extra }
}

// CHECK: 3 1
let number = Holder(3)
print(number.value, number.count)

// Messages from Objective-C reach the instance and class methods.
// CHECK-NEXT: 42 7
print((number as Tagged).tag(), (Holder<Int>.self as Kinded.Type).kind())

// Each instantiation has its own class record, which conforms to the
// class's protocols.
// CHECK-NEXT: false 1
let text = Holder("a string that is not small")
print((Holder<Int>.self as AnyObject) === (Holder<String>.self as AnyObject),
      class_conformsToProtocol(Holder<String>.self, Tagged.self))

// Stored properties do not overlap.
text.count = 2
text.value += "!"
// CHECK-NEXT: a string that is not small! 2
print(text.value, text.count)

// A generic subclass of a generic class.
// CHECK-NEXT: 47 5 x
let derived = Derived("x")
print((derived as Tagged).tag(), derived.extra, derived.value)

// CHECK-NEXT: deinit 3
// CHECK-NEXT: done
do {
  let temporary = Holder(3)
  _ = temporary.tag()
}
print("done")
