// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_runtime_functions %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepRuntimeFunctions

// Under the GNUstep runtime, an @objc protocol declared in Swift has a
// protocol record that the runtime loads with the image, under the
// protocol's unmangled name.  Protocol names are global at run time, as
// in Objective-C.

@objc protocol Pinging {
  func ping() -> Int
}

final class Pinger: NSObject, Pinging {
  func ping() -> Int { return 1 }
}

// The image loaded: the runtime accepted the protocol record.
// CHECK: main
print("main")

// CHECK-NEXT: Pinging true
let found = objc_getProtocol("Pinging")
print(String(cString: protocol_getName(found)),
      found === (Pinging.self as Protocol))

// CHECK-NEXT: 1 1
print(class_conformsToProtocol(Pinger.self, Pinging.self),
      (Pinger() as Pinging).ping())
