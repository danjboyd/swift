// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-ir -parse-as-library -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=none -module-name objc_gnustep_class_object -I %S/Inputs/gnustep %s -o %t/out.ll
// RUN: %FileCheck %s < %t/out.ll
// RUN: %FileCheck %s -check-prefix=THUNK < %t/out.ll

// REQUIRES: OS=linux-gnu

import GNUstepRoot

// Under the GNUstep runtime, the Objective-C class object of a Swift class
// is its GNUstep class record, not its Swift metadata.  An @objc metatype of
// a Swift class holds the class record, which the Swift runtime finds for
// the metadata.

public class Sub: Root {
  @objc public dynamic class func make() -> Sub { return Sub() }
}

// Converting the metatype to an object yields the class record, the object
// Objective-C code has for the class.
// CHECK-LABEL: define {{.*}} @"$s25objc_gnustep_class_object8asObjectyXlyF"()
// CHECK: [[RESPONSE:%.*]] = call swiftcc %swift.metadata_response @"$s25objc_gnustep_class_object3SubCMa"(
// CHECK: [[METADATA:%.*]] = extractvalue %swift.metadata_response [[RESPONSE]], 0
// CHECK: [[CLASS:%.*]] = call ptr @swift_getObjCClassFromMetadata(ptr [[METADATA]])
// CHECK: ret ptr [[CLASS]]
public func asObject() -> AnyObject {
  return Sub.self as AnyObject
}

// Messages to the class go to the class record.
// CHECK-LABEL: define {{.*}} @"$s25objc_gnustep_class_object15callClassMethodAA3SubCyF"()
// CHECK: [[RESPONSE:%.*]] = call swiftcc %swift.metadata_response @"$s25objc_gnustep_class_object3SubCMa"(
// CHECK: [[METADATA:%.*]] = extractvalue %swift.metadata_response [[RESPONSE]], 0
// CHECK: [[CLASS:%.*]] = call ptr @swift_getObjCClassFromMetadata(ptr [[METADATA]])
// CHECK: call ptr @objc_msgSend(ptr [[CLASS]],
public func callClassMethod() -> Sub {
  return Sub.make()
}

// So does a cast of the metatype to an object.
// CHECK-LABEL: define {{.*}} @"$s25objc_gnustep_class_object12castToObjectyyXlSgAA3SubCmF"(ptr %0)
// CHECK: call ptr @swift_getObjCClassFromMetadata(ptr %0)
public func castToObject(_ c: Sub.Type) -> AnyObject? {
  return c as? AnyObject
}

// Converting a class record back to a metatype maps it to the metadata.
// The thunk is emitted with the class, ahead of the functions above.
// THUNK-LABEL: define internal ptr @"$s25objc_gnustep_class_object3SubC4makeACyFZTo"(ptr %0, ptr %1)
// THUNK: call ptr @swift_getObjCClassMetadata(ptr %0)
