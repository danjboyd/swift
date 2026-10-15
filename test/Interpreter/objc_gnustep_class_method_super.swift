// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_runtime_functions %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepRuntimeFunctions

// Under the GNUstep runtime, a message to super from a class method looks
// the method up from the metaclass of the superclass's class record.

class Base: NSObject {
  // The superclass's implementation, from NSObject, answers for the
  // receiver, Base.
  override class func superclass() -> AnyClass! {
    return super.superclass()
  }

  @objc dynamic class func value() -> Int { return 1 }
}

final class Sub: Base {
  override class func value() -> Int { return super.value() + 10 }
}

// CHECK: NSObject
print(String(cString: class_getName(Base.superclass())))

// CHECK-NEXT: 11
print(Sub.value())
