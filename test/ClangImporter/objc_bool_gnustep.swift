// REQUIRES: OS=linux-gnu

// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -o %t/ObjectiveC.swiftmodule -module-name ObjectiveC -parse-as-library -enable-objc-interop -objc-runtime=gnustep %S/Inputs/gnustep_bool/ObjectiveC.swift
// RUN: %target-swift-frontend -emit-silgen -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -I %t -I %S/Inputs/gnustep_bool %s | %FileCheck %s
// RUN: %target-swift-frontend -emit-ir -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=none -I %t -I %S/Inputs/gnustep_bool %s | %FileCheck %s -check-prefix=IR

// GNUstep's BOOL is unsigned char.  It imports as Bool, crosses into
// Objective-C as ObjCBool, and ObjCBool lowers back to unsigned char.

import ObjectiveC
import GNUstepBool

// CHECK-LABEL: sil hidden [ossa] @$s17objc_bool_gnustep5checkySbSo4FlagCF
// CHECK: function_ref @$s10ObjectiveC22_convertBoolToObjCBoolyAA0eF0VSbF
// CHECK: objc_method {{%.*}}, #Flag.setSet!foreign : (Flag) -> (Bool) -> (), $@convention(objc_method) (ObjCBool, Flag) -> ()
// CHECK: objc_method {{%.*}}, #Flag.isSet!foreign : (Flag) -> () -> Bool, $@convention(objc_method) (Flag) -> ObjCBool
// CHECK: function_ref @$s10ObjectiveC22_convertObjCBoolToBoolySbAA0cD0VF
func check(_ flag: Flag) -> Bool {
  flag.setSet(true)
  return flag.isSet()
}

// A Swift method returning Bool is encoded as returning GNUstep's BOOL.
// IR: c"C16@0:8\00"
class Sub: Flag {
  @objc func isReady() -> Bool { return true }
}
