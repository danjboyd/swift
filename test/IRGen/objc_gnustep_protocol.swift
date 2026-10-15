// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-ir -parse-as-library -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=none -module-name objc_gnustep_protocol -I %S/../Inputs/gnustep_nsobject %s -o %t/out.ll
// RUN: %FileCheck %s < %t/out.ll
// RUN: %FileCheck %s -check-prefix=NEGATIVE < %t/out.ll

// REQUIRES: OS=linux-gnu

import GNUstepNSObject

// Under the GNUstep runtime, an @objc protocol declared in Swift gets the
// runtime's gnustep-2.0 protocol record, the layout Clang emits for a
// protocol declared in Objective-C:
//
//   { isa, name, protocol_list, instance_methods, class_methods,
//     optional_instance_methods, optional_class_methods, properties,
//     optional_properties, class_properties, optional_class_properties }
//
// Its isa is protocol_version_gsv2 (4), which the runtime replaces with the
// Protocol class when it registers the record from __objc_protocols.

// CHECK-DAG: $_PROTOCOL_Pinging = comdat any
// CHECK-DAG: @_PROTOCOL_Pinging = weak hidden externally_initialized global { ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr } { ptr inttoptr (i64 4 to ptr), ptr @{{[^,]*}}Pinging{{[^,]*}}, ptr @_PROTOCOL_PROTOCOLS_Pinging, ptr @_PROTOCOL_INSTANCE_METHODS_Pinging, ptr @_PROTOCOL_CLASS_METHODS_Pinging, ptr @_PROTOCOL_INSTANCE_METHODS_OPT_Pinging, ptr null, ptr @_PROTOCOL_PROPERTIES_Pinging, ptr @_PROTOCOL_PROPERTIES_OPT_Pinging, ptr @_PROTOCOL_CLASS_PROPERTIES_Pinging, ptr null }, section "__objc_protocols", comdat, align 8

// The protocol list has the layout of a class's, { next, count, protocols[] }.
// CHECK-DAG: @_PROTOCOL_PROTOCOLS_Pinging = {{.*}} { ptr, i64, [1 x ptr] } { ptr null, i64 1, [1 x ptr] [ptr @._OBJC_PROTOCOL_NSCoding] }

// Method lists are { count, size, { selector, types }[] }, with typed
// selector records, which the runtime registers, and extended type
// encodings.  Property accessors are methods of the protocol too.
// CHECK-DAG: @_PROTOCOL_INSTANCE_METHODS_Pinging = {{.*}} { i32, i32, [3 x { ptr, ptr }] } { i32 3, i32 16, [3 x { ptr, ptr }] [{ ptr, ptr } { ptr @"\01L_gnustep_selector(ping){{(\.[0-9]+)?}}", ptr @".str.7.q16@0:8" }, { ptr, ptr } { ptr @"\01L_gnustep_selector(count){{(\.[0-9]+)?}}", ptr @".str.7.q16@0:8" }, { ptr, ptr } { ptr @"\01L_gnustep_selector(setCount:){{(\.[0-9]+)?}}", ptr @".str.10.v24@0:8q16" }] }
// CHECK-DAG: @_PROTOCOL_CLASS_METHODS_Pinging = {{.*}} { i32, i32, [2 x { ptr, ptr }] } { i32 2, i32 16, [2 x { ptr, ptr }] [{ ptr, ptr } { ptr @"\01L_gnustep_selector(reset){{(\.[0-9]+)?}}", ptr @".str.7.v16@0:8" }, { ptr, ptr } { ptr @"\01L_gnustep_selector(shared){{(\.[0-9]+)?}}", ptr @".str.7.q16@0:8" }] }
// CHECK-DAG: @_PROTOCOL_INSTANCE_METHODS_OPT_Pinging = {{.*}} { i32, i32, [2 x { ptr, ptr }] } { i32 2, i32 16, [2 x { ptr, ptr }] [{ ptr, ptr } { ptr @"\01L_gnustep_selector(pong:){{(\.[0-9]+)?}}", ptr @".str.10.v24@0:8q16" }, { ptr, ptr } { ptr @"\01L_gnustep_selector(label){{(\.[0-9]+)?}}", ptr @".str.7.q16@0:8" }] }
// CHECK-DAG: @"\01L_gnustep_selector(ping){{(\.[0-9]+)?}}" = private externally_initialized global { ptr, ptr } { ptr @"\01L_selector_data(ping)", ptr @".str.7.q16@0:8" }, section "__objc_selectors"

// Property lists are { count, size, next, { name, attributes, type, getter,
// setter }[] }, split into required and optional, instance and class
// properties.
// CHECK-DAG: @_PROTOCOL_PROPERTIES_Pinging = {{.*}} { i32, i32, ptr, [1 x { ptr, ptr, ptr, ptr, ptr }] } { i32 1, i32 40, ptr null, [1 x { ptr, ptr, ptr, ptr, ptr }] [{ ptr, ptr, ptr, ptr, ptr } { ptr @.str.5.count, ptr @".str.4.Tq,N", ptr @.str.1.q, ptr @"\01L_gnustep_selector(count){{(\.[0-9]+)?}}", ptr @"\01L_gnustep_selector(setCount:){{(\.[0-9]+)?}}" }] }
// CHECK-DAG: @_PROTOCOL_PROPERTIES_OPT_Pinging = {{.*}} { i32, i32, ptr, [1 x { ptr, ptr, ptr, ptr, ptr }] } { i32 1, i32 40, ptr null, [1 x { ptr, ptr, ptr, ptr, ptr }] [{ ptr, ptr, ptr, ptr, ptr } { ptr @.str.5.label, ptr @".str.6.Tq,N,R", ptr @.str.1.q, ptr @"\01L_gnustep_selector(label){{(\.[0-9]+)?}}", ptr null }] }
// CHECK-DAG: @_PROTOCOL_CLASS_PROPERTIES_Pinging = {{.*}} { i32, i32, ptr, [1 x { ptr, ptr, ptr, ptr, ptr }] } { i32 1, i32 40, ptr null, [1 x { ptr, ptr, ptr, ptr, ptr }] [{ ptr, ptr, ptr, ptr, ptr } { ptr @.str.6.shared, ptr @".str.6.Tq,N,R", ptr @.str.1.q, ptr @"\01L_gnustep_selector(shared){{(\.[0-9]+)?}}", ptr null }] }

// A class adopting the protocol lists the record, which the runtime has
// registered by the time it loads the class.
// CHECK-DAG: @_PROTOCOLS_Pinger = internal constant { ptr, i64, [1 x ptr] } { ptr null, i64 1, [1 x ptr] [ptr @_PROTOCOL_Pinging] }

// References to the protocol are fixed up by the runtime.
// CHECK-DAG: @"\01l_OBJC_PROTOCOL_REFERENCE_$_Pinging" = weak hidden global ptr @_PROTOCOL_Pinging, section "__objc_protocol_refs", align 8

// There is nothing in the Apple runtime's protocol sections, and no record
// has the Apple runtime's extended method types or flags.
// NEGATIVE-NOT: __objc_protolist
// NEGATIVE-NOT: __objc_protorefs
// NEGATIVE-NOT: _PROTOCOL_METHOD_TYPES_

@objc public protocol Pinging: NSCoding {
  func ping() -> Int
  @objc optional func pong(_ value: Int)
  static func reset()
  var count: Int { get set }
  @objc optional var label: Int { get }
  static var shared: Int { get }
}

public class Pinger: NSObject, Pinging {
  public func encode(withCoder coder: Any) {}
  public func ping() -> Int { return 1 }
  public static func reset() {}
  public var count: Int = 0
  public static var shared: Int { return 2 }
}

// CHECK-LABEL: define {{.*}} @"$s21objc_gnustep_protocol{{.*}}ObjectSo8ProtocolCyF"()
// CHECK: load ptr, ptr @"\01l_OBJC_PROTOCOL_REFERENCE_$_Pinging", align 8
public func protocolObject() -> Protocol {
  return Pinging.self
}
