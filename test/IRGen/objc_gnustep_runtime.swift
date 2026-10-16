// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-ir -parse-as-library -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=none -module-name objc_gnustep_runtime -I %S/Inputs/gnustep %s -o %t/out.ll
// RUN: %FileCheck %s < %t/out.ll
// RUN: %FileCheck %s -check-prefix=SUPER < %t/out.ll
// RUN: %FileCheck %s -check-prefix=THUNK < %t/out.ll

// REQUIRES: OS=linux-gnu

import GNUstepRoot

// Objective-C class symbols use the name Clang gives the class after the
// prefix Clang uses for the GNUstep runtime, and class references go in the
// GNUstep runtime's __objc_class_refs section.
// CHECK-DAG: @._OBJC_REF_CLASS_Root = private externally_initialized global ptr @._OBJC_CLASS_Root, section "__objc_class_refs"

// Class objects have the GNUstep runtime's struct objc_class layout, and
// metaclasses are left for the runtime to link when it loads the class.
// CHECK-DAG: %objc_class = type { ptr, ptr, ptr, i64, i64, i64, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, i64, ptr }
// CHECK-DAG: @._OBJC_METACLASS_Sub = {{.*}}global %objc_class { ptr @._OBJC_METACLASS_Sub, ptr null, ptr @{{.*}}, i64 0, i64 1, i64 0,

// Method lists use the GNUstep layout: a next pointer, the count, the size
// of a method record, then { IMP, selector, type encoding } records whose
// selectors are typed selector records that the runtime registers.
// CHECK-DAG: @"\01L_gnustep_selector(hello)" = private externally_initialized global { ptr, ptr } { ptr @"\01L_selector_data(hello)", ptr @{{.*}} }, section "__objc_selectors"
// CHECK-DAG: @_INSTANCE_METHODS_objc_gnustep_runtime.Sub = internal constant { ptr, i32, i64, [6 x { ptr, ptr, ptr }] } { ptr null, i32 6, i64 24,

// Protocol lists use the GNUstep layout, { next, count, protocols[] }, and
// refer to the protocol records Clang emits for the GNUstep runtime.
// CHECK-DAG: @._OBJC_PROTOCOL_Named = {{.*}}global {
// CHECK-DAG: @_PROTOCOLS_objc_gnustep_runtime.Sub = internal constant { ptr, i64, [1 x ptr] } { ptr null, i64 1, [1 x ptr] [ptr @._OBJC_PROTOCOL_Named] }

// Each class also gets an ivar list in the GNUstep layout,
// { count, sizeof(struct objc_ivar), { name, type, offset, size, flags }[] },
// whose offset pointers receive the ivars' final offsets.
// CHECK-DAG: @_GNUSTEP_IVARS_objc_gnustep_runtime.Sub = internal constant { i32, i64, [1 x { ptr, ptr, ptr, i32, i32 }] } { i32 1, i64 32,

// Swift classes exposed to Objective-C get a GNUstep class record, which is
// what the runtime loads and Objective-C code sees.  Its negative instance
// size has the runtime lay out the ivars after the superclass's.  The record
// goes in the runtime's class list, and a module constructor tells the Swift
// runtime which Swift metadata belongs to it.
// CHECK-DAG: @._OBJC_CLASS_Sub = protected externally_initialized global %objc_class { ptr @._OBJC_METACLASS_Sub, ptr @._OBJC_CLASS_Root, ptr @{{.*}}, i64 0, i64 0, i64 -8, ptr @_GNUSTEP_IVARS_objc_gnustep_runtime.Sub, ptr @_INSTANCE_METHODS_objc_gnustep_runtime.Sub,
// CHECK-DAG: @._OBJC_REF_CLASS_Sub = protected externally_initialized global ptr @._OBJC_CLASS_Sub, section "__objc_class_refs"
// CHECK-DAG: @gnustep_objc_classes = internal global [1 x ptr] [ptr @._OBJC_CLASS_Sub], section "__objc_classes"
// CHECK-DAG: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 60000, ptr @_swift_gnustep_objc_class_metadata_registration, ptr null }]
// CHECK-DAG: call void @swift_registerGNUstepObjCClassMetadata(ptr @._OBJC_CLASS_Sub, ptr @"$s20objc_gnustep_runtime3SubCN")

public class Sub: Root, Named {
  @objc public var count: Int = 0
  @objc public func hello() {}
  public override func greet() { super.greet() }
  public func name() -> UnsafePointer<CChar> {
    return UnsafePointer(bitPattern: 1)!
  }
}

// Selectors come from sel_registerName, and messages to super go through
// objc_msg_lookup_super with the superclass's class record.
// SUPER-LABEL: define {{.*}} @"$s20objc_gnustep_runtime3SubC5greetyyF"(
// SUPER: [[ROOT:%.*]] = load ptr, ptr @._OBJC_REF_CLASS_Root
// SUPER: [[SUPERCLASS:%.*]] = call ptr @swift_getObjCClassFromMetadata(ptr [[ROOT]])
// SUPER: store ptr [[SUPERCLASS]], ptr
// SUPER: [[SEL:%.*]] = call ptr @sel_registerName(ptr @"\01L_selector_data(greet)")
// SUPER: call ptr @objc_msg_lookup_super(ptr %objc_super, ptr [[SEL]])

// The @objc thunks find self's class through the Swift runtime, which also
// knows the classes of Swift objects without a class record, and map the
// class record to its Swift metadata.
// THUNK-LABEL: define internal void @"$s20objc_gnustep_runtime3SubC5helloyyFTo"(
// THUNK: [[CLASS:%.*]] = call ptr @swift_gnustep_getObjectClass(ptr %0)
// THUNK: call ptr @swift_getObjCClassMetadata(ptr [[CLASS]])

// Isa loads are never masked.
// CHECK-NOT: swift_isaMask
