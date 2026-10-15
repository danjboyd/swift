// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-ir -parse-as-library -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=none -module-name objc_gnustep_class_method_super -I %S/Inputs/gnustep %s -o %t/out.ll
// RUN: %FileCheck %s < %t/out.ll

// REQUIRES: OS=linux-gnu

import GNUstepRoot

// Under the GNUstep runtime, objc_msg_lookup_super starts the lookup at the
// class in the objc_super struct.  For a message to super from a class
// method, that is the metaclass of the superclass's class record, which is
// the record's isa.

public class Sub: Root {
  public override class func reset() { super.reset() }
}

// CHECK-LABEL: define {{.*}} @"$s31objc_gnustep_class_method_super3SubC5resetyyFZ"(ptr swiftself %0)
// CHECK: [[RECEIVER:%.*]] = call ptr @swift_getObjCClassFromMetadata(ptr %0)
// CHECK: [[ROOT:%.*]] = load ptr, ptr @._OBJC_REF_CLASS_Root
// CHECK: [[CLASS:%.*]] = call ptr @swift_getObjCClassFromMetadata(ptr [[ROOT]])
// CHECK: [[METACLASS:%.*]] = load ptr, ptr [[CLASS]]
// CHECK: store ptr [[RECEIVER]], ptr
// CHECK: store ptr [[METACLASS]], ptr
// CHECK: [[SEL:%.*]] = call ptr @sel_registerName(ptr @"\01L_selector_data(reset)")
// CHECK: call ptr @objc_msg_lookup_super(ptr %objc_super, ptr [[SEL]])

// The superclass may itself be a Swift class, whose class record is found
// through its Swift metadata.
public class SubSub: Sub {
  public override class func reset() { super.reset() }
}

// CHECK-LABEL: define {{.*}} @"$s31objc_gnustep_class_method_super03SubF0C5resetyyFZ"(ptr swiftself %0)
// CHECK-NOT: @._OBJC_REF_CLASS_Root
// CHECK: [[RECEIVER:%.*]] = call ptr @swift_getObjCClassFromMetadata(ptr %0)
// CHECK-NOT: @._OBJC_REF_CLASS_Root
// CHECK: [[RESPONSE:%.*]] = call swiftcc %swift.metadata_response @"$s31objc_gnustep_class_method_super3SubCMa"(
// CHECK: [[SUPER:%.*]] = extractvalue %swift.metadata_response [[RESPONSE]], 0
// CHECK: [[CLASS:%.*]] = call ptr @swift_getObjCClassFromMetadata(ptr [[SUPER]])
// CHECK: [[METACLASS:%.*]] = load ptr, ptr [[CLASS]]
// CHECK: store ptr [[RECEIVER]], ptr
// CHECK: store ptr [[METACLASS]], ptr
// CHECK: call ptr @objc_msg_lookup_super(ptr %objc_super,
