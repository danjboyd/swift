// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-ir -parse-as-library -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=all -module-name objc_gnustep_class_names -I %S/Inputs/gnustep %s -o %t/out.ll
// RUN: %FileCheck %s < %t/out.ll

// REQUIRES: OS=linux-gnu

import GNUstepRoot

// Under the GNUstep runtime, a Swift class without an Objective-C name
// registers under the name Apple's runtime shows for it, which is what
// NSStringFromClass() returns and NSClassFromString() and keyed archives use:
// Module.Class for a top-level class, and the mangled name for any other.
// Its symbols keep the Swift name, which is the name the generated header
// declares the class under and so the name Clang refers to it by.

// CHECK-DAG: @[[SUB_NAME:[^ ]*]] = private unnamed_addr constant [29 x i8] c"objc_gnustep_class_names.Sub\00"
// CHECK-DAG: @._OBJC_CLASS_Sub = protected externally_initialized global %objc_class { ptr @._OBJC_METACLASS_Sub, ptr @._OBJC_CLASS_Root, ptr @[[SUB_NAME]],
// CHECK-DAG: @._OBJC_REF_CLASS_Sub = protected externally_initialized global ptr @._OBJC_CLASS_Sub, section "__objc_class_refs"
public class Sub: Root {}

// CHECK-DAG: @[[INNER_NAME:[^ ]*]] = private unnamed_addr constant [44 x i8] c"_TtCC24objc_gnustep_class_names5Outer5Inner\00"
// CHECK-DAG: @._OBJC_CLASS_Inner = protected externally_initialized global %objc_class { ptr @._OBJC_METACLASS_Inner, ptr @._OBJC_CLASS_Root, ptr @[[INNER_NAME]],
public class Outer: Root {
  public class Inner: Root {}
}

// A private class's mangled name has its file's discriminator.
// CHECK-DAG: @[[HIDDEN_NAME:[^ ]*]] = private unnamed_addr constant [{{[0-9]+}} x i8] c"_TtC24objc_gnustep_class_namesP33_{{[0-9A-F]+}}6Hidden\00"
// CHECK-DAG: @._OBJC_CLASS_Hidden = internal externally_initialized global %objc_class { ptr @._OBJC_METACLASS_Hidden, ptr @._OBJC_CLASS_Root, ptr @[[HIDDEN_NAME]],
private class Hidden: Root {}
public func makeHidden() -> AnyObject { return Hidden() }

// An Objective-C name is used as it is.
// CHECK-DAG: @[[RENAMED_NAME:[^ ]*]] = private unnamed_addr constant [8 x i8] c"Renamed\00"
// CHECK-DAG: @._OBJC_CLASS_Renamed = protected externally_initialized global %objc_class { ptr @._OBJC_METACLASS_Renamed, ptr @._OBJC_CLASS_Root, ptr @[[RENAMED_NAME]],
@objc(Renamed) public class SwiftNamed: Root {}

// So is the name of a class declared in Objective-C.
// CHECK-DAG: @._OBJC_REF_CLASS_Root = private externally_initialized global ptr @._OBJC_CLASS_Root, section "__objc_class_refs"
