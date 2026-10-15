// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepNSObject

// Under the GNUstep runtime, a Swift class exposed to Objective-C has a class
// record that is separate from its Swift metadata.  Casting the metatype of
// such a class to the metatype of an Objective-C class must not message the
// metadata, which libobjc2 cannot interpret as a class.

class Base: NSObject {}
final class Derived: Base {}
final class Unrelated {}

let derived: AnyClass = Derived.self
let unrelated: AnyClass = Unrelated.self

// CHECK: true
print(derived is NSObject.Type)
// CHECK-NEXT: true
print(derived is Base.Type)
// CHECK-NEXT: false
print(unrelated is NSObject.Type)
// CHECK-NEXT: false
print((Base.self as AnyClass) is Derived.Type)

// The cast gives back the class it was given.
// CHECK-NEXT: true
let conditional = derived as? NSObject.Type
print(conditional.map { ObjectIdentifier($0) == ObjectIdentifier(Derived.self) } ?? false)
// CHECK-NEXT: true
let forced = derived as! NSObject.Type
print(ObjectIdentifier(forced) == ObjectIdentifier(Derived.self))
