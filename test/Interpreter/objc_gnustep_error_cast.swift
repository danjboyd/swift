// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_nsstring -I %S/../Inputs/gnustep_nserror -parse-as-library -emit-module -emit-library -module-name Foundation %S/Inputs/objc_gnustep_error_bridging_foundation.swift -o %t/%target-library-name(Foundation)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_nsstring -I %S/../Inputs/gnustep_nserror -I %t -L %t -lFoundation %s -o %t/a.out %target-rpath(%t)
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out %t/%target-library-name(Foundation) | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import Foundation

// Under the GNUstep runtime an NSError casts to a Swift error type as with
// Apple's runtime: the NSError that stands for a Swift error casts back to
// that error, through the Foundation overlay's _convertNSErrorToError, and
// any other NSError casts to an _ObjectiveCBridgeableError type that
// accepts it, through _bridgeNSErrorToError.

enum Failure: Error, Equatable {
  case first
  case second
}

final class Thrown: Error {}

struct StoredError: _BridgedStoredNSError {
  static var errorDomain: String { return "StoredDomain" }
  let _nsError: NSError
  init(_nsError error: NSError) { _nsError = error }
}

func makeNSError(_ domain: String, _ code: Int) -> NSError {
  return NSError(domain: domain._bridgeToObjectiveCImpl(), code: code,
                 userInfo: nil)!
}

// A Swift error made into an NSError casts back to itself.
let failure = (Failure.second as Error) as! NSError
// CHECK: Failure 1
print(failure._domain.split(separator: ".").last!, failure.code())
// CHECK-NEXT: true true true true
print((failure as Error) as? Failure == .second,
      (failure as Any) as? Failure == .second,
      (failure as AnyObject) as? Failure == .second,
      (failure as Error) as? Thrown == nil)

let thrown = Thrown()
let thrownNSError = (thrown as Error) as! NSError
// CHECK-NEXT: true
print((thrownNSError as Error) as? Thrown === thrown)

// catch matches the Swift error inside the NSError.
func catchFailure(_ error: Error) -> String {
  do {
    throw error
  } catch Failure.first {
    return "first"
  } catch Failure.second {
    return "second"
  } catch {
    return "other"
  }
}
// CHECK-NEXT: second
print(catchFailure(failure))

// Any other NSError casts to a bridgeable error type that accepts it.
let stored = makeNSError("StoredDomain", 3)
let other = makeNSError("OtherDomain", 3)
// CHECK-NEXT: true 3 true true
print(((stored as Error) as? StoredError)?._nsError === stored,
      ((stored as Any) as? StoredError)?._nsError.code() ?? 0,
      (other as Error) as? StoredError == nil,
      (stored as Error) as? Failure == nil)

func castGeneric<T>(_ value: AnyObject, to: T.Type) -> T? {
  return value as? T
}
// CHECK-NEXT: true
print(castGeneric(stored, to: StoredError.self)?._nsError === stored)

// The compiler puts a stored-NSError error into an Error as its NSError,
// which casts back to the error type.
let erased: Error = StoredError(_nsError: stored)
// CHECK-NEXT: true true
print((erased as AnyObject) === stored,
      (erased as? StoredError)?._nsError === stored)

func catchStored() -> Int {
  do {
    throw StoredError(_nsError: stored)
  } catch let error as StoredError {
    return error._nsError.code()
  } catch {
    return 0
  }
}
// CHECK-NEXT: 3
print(catchStored())

// An error's user info is Foundation's _getErrorDefaultUserInfo.
func describeUserInfo(_ error: Error) -> String {
  guard let userInfo = error._userInfo else {
    return "nil"
  }
  return String(cString: (userInfo as! NSString).utf8String())
}
// CHECK-NEXT: Failure
print(describeUserInfo(Failure.first).split(separator: ".").last!)
