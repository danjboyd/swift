// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_nsstring -I %S/../Inputs/gnustep_nserror -parse-as-library -emit-module -emit-library -module-name Foundation %S/Inputs/objc_gnustep_error_bridging_foundation.swift -o %t/%target-library-name(Foundation)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_nsstring -I %S/../Inputs/gnustep_nserror -I %t -L %t -lFoundation %s -o %t/a.out %target-rpath(%t)
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out %t/%target-library-name(Foundation) | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import Foundation

// Under the GNUstep runtime every Swift error becomes an NSError through
// the Foundation overlay's _convertErrorToNSError, as Apple's runtime makes
// every error an NSError.  The compiler takes `catch let error as NSError`
// to catch every error, so the cast must not fail.

enum Failure: Error {
  case first
  case second
}

struct Coded: Error {
  var _domain: String { return "CodedDomain" }
  var _code: Int { return 42 }
}

final class Thrown: Error {}

func describe(_ error: NSError) -> String {
  let domain = error.domain() as! NSString
  return "\(String(cString: domain.utf8String())) \(error.code())"
}

// CHECK: Failure 1
do {
  throw Failure.second
} catch let error as NSError {
  print(describe(error).split(separator: ".").last!)
}

// Inside a function the catch is the same.
func catchCoded() -> String {
  do {
    throw Coded()
  } catch let error as NSError {
    return describe(error)
  }
}
// CHECK-NEXT: CodedDomain 42
print(catchCoded())

func catchThrown() -> String {
  do {
    throw Thrown()
  } catch let error as NSError {
    return describe(error)
  }
}
// CHECK-NEXT: Thrown 1
print(catchThrown().split(separator: ".").last!)

// Conditional casts from an Error, from Any and from a generic value.
let error: Error = Failure.first
let any: Any = Failure.second
func castGeneric<T>(_ value: T) -> NSError? { return value as? NSError }
// CHECK-NEXT: true true true true
print((error as? NSError) != nil, (any as? NSError)?.code() == 1,
      (any as? NSObject) != nil, castGeneric(Coded())?.code() == 42)

// A Swift error given to Objective-C is an NSError.
// CHECK-NEXT: true
print((Failure.first as AnyObject) is NSError)

// An NSError in an Error is itself.
let nsError = NSError(domain: "Domain"._bridgeToObjectiveCImpl(), code: 7,
                      userInfo: nil)!
let wrapped: Error = nsError
// CHECK-NEXT: true
print((wrapped as? NSError) === nsError)
