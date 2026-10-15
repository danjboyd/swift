// RUN: %target-swift-emit-silgen -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -module-name objc_gnustep_protocol_class -I %S/../Inputs/gnustep_nsobject %s | %FileCheck %s

// REQUIRES: OS=linux-gnu

import GNUstepNSObject

// GNUstep declares NSObject in Foundation rather than in the Objective-C
// runtime's headers, so the Protocol class the Clang importer declares next
// to it is not in the ObjectiveC module.  A single @objc protocol metatype
// still converts to it.

// CHECK-LABEL: sil [ossa] @$s27objc_gnustep_protocol_class10conversionSo8ProtocolCyF : $@convention(thin) () -> @owned Protocol
// CHECK: [[PROTO:%.*]] = objc_protocol #NSCoding : $Protocol
// CHECK: [[COPY:%.*]] = copy_value [[PROTO]]
// CHECK: return [[COPY]]
public func conversion() -> Protocol {
  return NSCoding.self
}

// CHECK-LABEL: sil [ossa] @$s27objc_gnustep_protocol_class8coercionSo8ProtocolCyF : $@convention(thin) () -> @owned Protocol
// CHECK: objc_protocol #NSCoding : $Protocol
public func coercion() -> Protocol {
  return NSCoding.self as Protocol
}

// CHECK-LABEL: sil [ossa] @$s27objc_gnustep_protocol_class8argument{{.*}} : $@convention(thin)
// CHECK-DAG: objc_protocol #NSCoding : $Protocol
// CHECK-DAG: function_ref @$sSo24class_conformsToProtocol{{.*}}FTo : $@convention(c)
// CHECK: } // end sil function
public func argument(_ cls: AnyClass) -> Int32 {
  return class_conformsToProtocol(cls, NSCoding.self)
}
