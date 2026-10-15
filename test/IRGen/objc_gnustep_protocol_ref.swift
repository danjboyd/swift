// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-ir -parse-as-library -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=none -module-name objc_gnustep_protocol_ref -I %S/../Inputs/gnustep_nsobject %s -o %t/out.ll
// RUN: %FileCheck %s < %t/out.ll
// RUN: %FileCheck %s -check-prefix=NOLABEL < %t/out.ll

// REQUIRES: OS=linux-gnu

import GNUstepNSObject

// Under the GNUstep runtime, a reference to a protocol declared in
// Objective-C goes in __objc_protocol_refs, where the runtime replaces it
// with the protocol objc_getProtocol() returns when it loads the image.  It
// refers to the GNUstep protocol record Clang emits into __objc_protocols.
// The runtime does not read __objc_protolist, so there is no label there.

// NOLABEL-NOT: OBJC_LABEL_PROTOCOL
// CHECK-DAG: @"\01l_OBJC_PROTOCOL_REFERENCE_$_NSCoding" = weak hidden global ptr @._OBJC_PROTOCOL_NSCoding, section "__objc_protocol_refs", align 8
// CHECK-DAG: @._OBJC_PROTOCOL_NSCoding = {{.*}}section "__objc_protocols"

// The record emitted for a protocol declared in Swift is not registered by
// the runtime, so its reference is not given to the runtime to fix up.
// CHECK-DAG: @"\01l_OBJC_PROTOCOL_REFERENCE_$__TtP25objc_gnustep_protocol_ref5Local_" = weak hidden global ptr {{.*}}, section "__objc_protorefs", align 8

@objc public protocol Local {}

// CHECK-LABEL: define {{.*}} @"$s25objc_gnustep_protocol_ref10conversionSo8ProtocolCyF"()
// CHECK: load ptr, ptr @"\01l_OBJC_PROTOCOL_REFERENCE_$_NSCoding", align 8
public func conversion() -> Protocol {
  return NSCoding.self
}

// CHECK-LABEL: define {{.*}} @"$s25objc_gnustep_protocol_ref5localSo8ProtocolCyF"()
// CHECK: load ptr, ptr @"\01l_OBJC_PROTOCOL_REFERENCE_$__TtP25objc_gnustep_protocol_ref5Local_", align 8
public func local() -> Protocol {
  return Local.self
}
