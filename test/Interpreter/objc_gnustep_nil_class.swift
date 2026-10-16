// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_nil_class %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepNSObject
import GNUstepNilClass

// The dynamic type of an Objective-C object is the class it answers to
// -class.  An object may answer Nil to hide what it is, as GNUstep's
// services listener does; its dynamic type is then its isa.  Null type
// metadata would make an Any holding the object read as nil.

// An `id` result is imported as `Any!`, and the object goes into the Any
// with its dynamic type.
let any: Any! = makeNilClassObject()
// CHECK: true
print(any != nil)
// CHECK-NEXT: NilClassObject
print(type(of: any!))

let object: AnyObject = makeNilClassObject() as AnyObject
// CHECK-NEXT: NilClassObject
print(type(of: object))
// CHECK-NEXT: true
print(object is NSObject)
// CHECK-NEXT: true
print((object as Any) is NSObject)
