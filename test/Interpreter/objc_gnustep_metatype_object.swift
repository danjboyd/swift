// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s
// RUN: %target-build-swift -O %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject %s -o %t/a.opt.out
// RUN: %target-codesign %t/a.opt.out
// RUN: %target-run %t/a.opt.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepNSObject

// Under the GNUstep runtime, the class object of a Swift class exposed to
// Objective-C is its GNUstep class record, which is separate from its Swift
// metadata.  A class metatype that the runtime converts to an object, from
// an Any or through a cast, must give the class record, as a conversion that
// IRGen emits does, and a conformance check on the metatype must ask the
// class record rather than message the metadata.

class Plain: NSObject {}
class Coding: NSObject, NSCoding {
  func encode(withCoder coder: Any) {}
}

// A class with no Objective-C ancestry has no class record; its class object
// is its metadata, which the runtime must neither retain nor release through
// libobjc2 nor message.
class Pure {}
class PureSub: Pure {}

let record: AnyClass = objc_lookUpClass("Plain")!
let instanceClass: AnyClass = object_getClass(Plain())!

@inline(never)
func object(_ value: Any) -> AnyObject {
  return value as AnyObject
}

@inline(never)
func conditionalObject(_ value: Any) -> AnyObject? {
  return value as? AnyObject
}

@inline(never)
func forcedObject(_ value: Any) -> AnyObject {
  return value as! AnyObject
}

@inline(never)
func codingType(_ value: Any) -> NSCoding.Type? {
  return value as? NSCoding.Type
}

@inline(never)
func codingClass(_ value: AnyClass) -> NSCoding.Type? {
  return value as? NSCoding.Type
}

// CHECK: true
print(instanceClass === record)
// CHECK-NEXT: true
print(Plain.self as AnyObject === record)

// CHECK-NEXT: true
print(object(Plain.self) === record)
// CHECK-NEXT: true
print(conditionalObject(Plain.self) === record)
// CHECK-NEXT: true
print(forcedObject(Plain.self) === record)
// CHECK-NEXT: true
print(ObjectIdentifier(object(Plain.self)) == ObjectIdentifier(record as AnyObject))
// CHECK-NEXT: true
print(object(NSObject.self) === objc_lookUpClass("NSObject")!)

// The class record converts back to the metatype.
// CHECK-NEXT: true
print((object(Plain.self) as? Plain.Type).map { $0 == Plain.self } ?? false)
// CHECK-NEXT: true
print(((record as Any) as? Plain.Type).map { $0 == Plain.self } ?? false)

// CHECK-NEXT: true
print(codingType(Coding.self) != nil)
// CHECK-NEXT: true
print(codingClass(Coding.self) != nil)
// CHECK-NEXT: false
print(codingType(Plain.self) != nil)

// CHECK-NEXT: true
print(object(Pure.self) === Pure.self as AnyObject)
// CHECK-NEXT: true
print(conditionalObject(Pure.self) === object(Pure.self))
// CHECK-NEXT: true
print(forcedObject(Pure.self) === object(Pure.self))
// CHECK-NEXT: true
print(object(Pure.self as AnyClass) === object(Pure.self))
// CHECK-NEXT: false
print(object(Pure.self) === object(PureSub.self))

@inline(never)
func retainAndRelease(_ value: Any, times: Int) -> Int {
  var objects: [AnyObject] = []
  for _ in 0..<times {
    objects.append(object(value))
  }
  return objects.filter { $0 === objects[0] }.count
}
// CHECK-NEXT: 1000
print(retainAndRelease(Pure.self, times: 1000))
// CHECK-NEXT: 1000
print(retainAndRelease(PureSub.self, times: 1000))

// The object converts back to the metatype.
// CHECK-NEXT: true
print((object(Pure.self) as? Pure.Type).map { $0 == Pure.self } ?? false)
// CHECK-NEXT: true
print((object(PureSub.self) as? Pure.Type).map { $0 == PureSub.self } ?? false)
// CHECK-NEXT: false
print(object(Pure.self) is PureSub.Type)
// CHECK-NEXT: false
print(object(Pure.self) is Plain.Type)
// CHECK-NEXT: false
print(String(describing: object(Pure.self)).isEmpty)
