// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepNSObject

// Under the GNUstep runtime, Protocol descends from the root class Object,
// which has no methods, rather than from NSObject, and sending a protocol
// -class aborts.  Finding the dynamic type of a protocol object must not
// send it.

let proto: Protocol = NSCoding.self
let object: AnyObject = proto

// CHECK: Protocol
print(type(of: object))

// A cast from AnyObject finds the dynamic type of the object first.
// CHECK-NEXT: true
print((object as? Protocol) === proto)

// CHECK-NEXT: true
print((object as Any) is Protocol)
