// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-ir -parse-as-library -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=none -module-name objc_gnustep_category -I %S/../Inputs/gnustep_nsobject %s -o %t/out.ll
// RUN: %FileCheck %s < %t/out.ll
// RUN: %FileCheck %s -check-prefix=NEGATIVE < %t/out.ll

// REQUIRES: OS=linux-gnu

import GNUstepNSObject

// Under the GNUstep runtime, an extension of a class that adds @objc members
// or Objective-C protocol conformances gets the runtime's gnustep-2.0
// category record, the layout Clang emits for a category implemented in
// Objective-C:
//
//   { name, class_name, instance_methods, class_methods, protocols,
//     properties, class_properties }
//
// The record is in __objc_cats, which the runtime walks as an array of
// records, and names its class, which the runtime looks up when it loads
// the record.

// CHECK-DAG: @"_CATEGORY_NSObject_$_objc_gnustep_category" = internal global { ptr, ptr, ptr, ptr, ptr, ptr, ptr } { ptr [[CATEGORY_NAME:@[^,]*objc_gnustep_category]], ptr [[NSOBJECT_NAME:@[^,]*NSObject]], ptr @"_CATEGORY_INSTANCE_METHODS_NSObject_$_objc_gnustep_category", ptr @"_CATEGORY_CLASS_METHODS_NSObject_$_objc_gnustep_category", ptr @"_CATEGORY_PROTOCOLS_NSObject_$_objc_gnustep_category", ptr @"_CATEGORY_PROPERTIES_NSObject_$_objc_gnustep_category", ptr @"_CATEGORY_CLASS_PROPERTIES_NSObject_$_objc_gnustep_category" }, section "__objc_cats", align 8
// CHECK-DAG: [[CATEGORY_NAME]] = {{.*}} c"objc_gnustep_category\00"
// CHECK-DAG: [[NSOBJECT_NAME]] = {{.*}} c"NSObject\00"

// Method lists have the layout of a class's, { next, count, size,
// { IMP, selector, types }[] }, with typed selector records.  Property
// accessors are methods of the category too.
// CHECK-DAG: @"_CATEGORY_INSTANCE_METHODS_NSObject_$_objc_gnustep_category" = internal {{.*}} { ptr, i32, i64, [2 x { ptr, ptr, ptr }] } { ptr null, i32 2, i64 24, [2 x { ptr, ptr, ptr }] [{ ptr, ptr, ptr } { ptr @"$sSo8NSObjectC21objc_gnustep_categoryE8greetingSiyFTo", ptr @"\01L_gnustep_selector(greeting){{(\.[0-9]+)?}}", ptr @".str.7.q16@0:8" }, { ptr, ptr, ptr } { ptr @"$sSo8NSObjectC21objc_gnustep_categoryE6answerSivgTo", ptr @"\01L_gnustep_selector(answer){{(\.[0-9]+)?}}", ptr @".str.7.q16@0:8" }] }
// CHECK-DAG: @"_CATEGORY_CLASS_METHODS_NSObject_$_objc_gnustep_category" = internal {{.*}} { ptr, i32, i64, [3 x { ptr, ptr, ptr }] } { ptr null, i32 3, i64 24, [3 x { ptr, ptr, ptr }] [{ ptr, ptr, ptr } { ptr @"$sSo8NSObjectC21objc_gnustep_categoryE4makeSiyFZTo", ptr @"\01L_gnustep_selector(make){{(\.[0-9]+)?}}", ptr @".str.7.q16@0:8" }, { ptr, ptr, ptr } { ptr @"$sSo8NSObjectC21objc_gnustep_categoryE6sharedSivgZTo", ptr @"\01L_gnustep_selector(shared){{(\.[0-9]+)?}}", ptr @".str.7.q16@0:8" }, { ptr, ptr, ptr } { ptr @"$sSo8NSObjectC21objc_gnustep_categoryE6sharedSivsZTo", ptr @"\01L_gnustep_selector(setShared:){{(\.[0-9]+)?}}", ptr @".str.10.v24@0:8q16" }] }

// The protocol list has the layout of a class's, { next, count,
// protocols[] }.
// CHECK-DAG: @"_CATEGORY_PROTOCOLS_NSObject_$_objc_gnustep_category" = internal {{.*}} { ptr, i64, [1 x ptr] } { ptr null, i64 1, [1 x ptr] [ptr @_PROTOCOL_Greeting] }

// Property lists are { count, size, next, { name, attributes, type, getter,
// setter }[] }, which the runtime links to the class's list through next.
// CHECK-DAG: @"_CATEGORY_PROPERTIES_NSObject_$_objc_gnustep_category" = internal {{.*}} { i32, i32, ptr, [1 x { ptr, ptr, ptr, ptr, ptr }] } { i32 1, i32 40, ptr null, [1 x { ptr, ptr, ptr, ptr, ptr }] [{ ptr, ptr, ptr, ptr, ptr } { ptr @.str.6.answer, ptr @".str.6.Tq,N,R", ptr @.str.1.q, ptr @"\01L_gnustep_selector(answer){{(\.[0-9]+)?}}", ptr null }] }
// CHECK-DAG: @"_CATEGORY_CLASS_PROPERTIES_NSObject_$_objc_gnustep_category" = internal {{.*}} { i32, i32, ptr, [1 x { ptr, ptr, ptr, ptr, ptr }] } { i32 1, i32 40, ptr null, [1 x { ptr, ptr, ptr, ptr, ptr }] [{ ptr, ptr, ptr, ptr, ptr } { ptr @.str.6.shared, ptr @".str.4.Tq,N", ptr @.str.1.q, ptr @"\01L_gnustep_selector(shared){{(\.[0-9]+)?}}", ptr @"\01L_gnustep_selector(setShared:){{(\.[0-9]+)?}}" }] }

// The properties of a class have the same layout.
// CHECK-DAG: @_PROPERTIES_objc_gnustep_category.Sub = internal {{.*}} { i32, i32, ptr, [1 x { ptr, ptr, ptr, ptr, ptr }] } { i32 1, i32 40, ptr null, [1 x { ptr, ptr, ptr, ptr, ptr }] [{ ptr, ptr, ptr, ptr, ptr } { ptr @.str.5.count, ptr @".str.11.Tq,N,Vcount", ptr @.str.1.q, ptr @"\01L_gnustep_selector(count){{(\.[0-9]+)?}}", ptr @"\01L_gnustep_selector(setCount:){{(\.[0-9]+)?}}" }] }
// CHECK-DAG: @._OBJC_CLASS_Sub = {{.*}}, ptr @_PROPERTIES_objc_gnustep_category.Sub }

// A class declared in Swift is named by its runtime name, the name of its
// class record.  Each extension gets its own category.
// CHECK-DAG: @"_CATEGORY_objc_gnustep_category.Sub_$_objc_gnustep_category" = internal global { ptr, ptr, ptr, ptr, ptr, ptr, ptr } { ptr [[CATEGORY_NAME]], ptr [[SUB_NAME:@[^,]*Sub]], ptr @"_CATEGORY_INSTANCE_METHODS_objc_gnustep_category.Sub_$_objc_gnustep_category", ptr null, ptr null, ptr null, ptr null }, section "__objc_cats", align 8
// CHECK-DAG: @"_CATEGORY_objc_gnustep_category.Sub_$_objc_gnustep_category1" = internal global { ptr, ptr, ptr, ptr, ptr, ptr, ptr } { ptr {{@[^,]*objc_gnustep_category1}}, ptr [[SUB_NAME]], ptr @"_CATEGORY_INSTANCE_METHODS_objc_gnustep_category.Sub_$_objc_gnustep_category1", ptr null, ptr @"_CATEGORY_PROTOCOLS_objc_gnustep_category.Sub_$_objc_gnustep_category1", ptr null, ptr null }, section "__objc_cats", align 8
// CHECK-DAG: [[SUB_NAME]] = {{.*}} c"objc_gnustep_category.Sub\00"
// CHECK-DAG: @"_CATEGORY_PROTOCOLS_objc_gnustep_category.Sub_$_objc_gnustep_category1" = internal {{.*}} { ptr, i64, [1 x ptr] } { ptr null, i64 1, [1 x ptr] [ptr @._OBJC_PROTOCOL_NSCoding] }

// No list refers to the records, so they are kept by being used.
// CHECK-DAG: @llvm.used = appending global [{{[0-9]+}} x ptr] [{{.*}}ptr @"_CATEGORY_NSObject_$_objc_gnustep_category"{{.*}}ptr @"_CATEGORY_objc_gnustep_category.Sub_$_objc_gnustep_category"{{.*}}ptr @"_CATEGORY_objc_gnustep_category.Sub_$_objc_gnustep_category1"{{.*}}]

// There is nothing in the Apple runtime's category lists, and no record
// has the Apple runtime's layout, which refers to the class object.
// NEGATIVE-NOT: __objc_catlist
// NEGATIVE-NOT: objc_categories

@objc public protocol Greeting {
  func greeting() -> Int
}

extension NSObject: Greeting {
  @objc public func greeting() -> Int { return 1 }
  @objc public class func make() -> Int { return 2 }
  @objc public var answer: Int { return 42 }
  @objc public static var shared: Int { get { return 3 } set {} }
}

public class Sub: NSObject {
  @objc public var count: Int = 0
}

extension Sub {
  @objc public func extra() {}
}

extension Sub: NSCoding {
  public func encode(withCoder coder: Any) {}
}
