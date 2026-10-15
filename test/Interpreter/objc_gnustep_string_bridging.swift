// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_nsstring %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepNSString

// Under the GNUstep runtime, the standard library's string classes cannot
// stand in for NSString, so a String bridges to a GNUstep NSString.

func isNSString(_ object: AnyObject) -> Bool {
  return object.isKind!(of: NSString.self) != 0
}

func utf8(_ object: AnyObject) -> String {
  return String(cString: object.utf8String!())
}

let small = "abc"._bridgeToObjectiveCImpl()
// CHECK: true abc
print(isNSString(small), utf8(small))

let large = String(repeating: "a longer string ", count: 4) + "\u{E9}"
let bridgedLarge = large._bridgeToObjectiveCImpl()
// CHECK-NEXT: true true
print(isNSString(bridgedLarge), utf8(bridgedLarge) == large)

let empty = ""._bridgeToObjectiveCImpl()
// CHECK-NEXT: true true
print(isNSString(empty), utf8(empty).isEmpty)

// A leading byte order mark is part of the string, and is kept.
let withBOM = "\u{FEFF}abc"._bridgeToObjectiveCImpl()
// CHECK-NEXT: true true
print(isNSString(withBOM), utf8(withBOM) == "\u{FEFF}abc")
let onlyBOM = "\u{FEFF}"._bridgeToObjectiveCImpl()
// CHECK-NEXT: true true
print(isNSString(onlyBOM), utf8(onlyBOM) == "\u{FEFF}")

// A Swift value given to Objective-C is boxed, and the box describes the
// value with an NSString.
struct Point { var x: Int; var y: Int }

let box = Point(x: 1, y: 2) as AnyObject
let description = box.description!() as AnyObject
// CHECK-NEXT: true {{.*}}Point(x: 1, y: 2)
print(isNSString(description), utf8(description))
let debugDescription = box.debugDescription!() as AnyObject
// CHECK-NEXT: true {{.*}}Point(x: 1, y: 2)
print(isNSString(debugDescription), utf8(debugDescription))
