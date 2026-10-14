// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-ir -enable-objc-interop -disable-objc-attr-requires-foundation-module -I %S/Inputs/objc_override_type_encoding %s -o %t/apple.ll
// RUN: %FileCheck %s < %t/apple.ll
// RUN: %FileCheck %s -check-prefix=NEGATIVE < %t/apple.ll
// RUN: %if OS=linux-gnu %{ %target-swift-frontend -emit-ir -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=none -I %S/Inputs/objc_override_type_encoding %s -o %t/gnustep.ll %}
// RUN: %if OS=linux-gnu %{ %FileCheck %s -check-prefixes=CHECK,GNUSTEP < %t/gnustep.ll %}
// RUN: %if OS=linux-gnu %{ %FileCheck %s -check-prefix=NEGATIVE < %t/gnustep.ll %}

// REQUIRES: objc_codegen
// REQUIRES: PTRSIZE=64

// An @objc method that overrides an Objective-C method, or satisfies a
// requirement of an Objective-C protocol, takes its type encoding from the
// Objective-C declaration rather than from its Swift type, so that it
// matches the signature Objective-C callers send.  NSUInteger is imported as
// Int but encoded as 'Q', and SEL, imported here as OpaquePointer, as ':'.

import OverrideBase

// CHECK-DAG: [[INIT:@[^ ]+]] = private unnamed_addr constant [11 x i8] c"@24@0:8Q16\00"
// CHECK-DAG: [[GETTER:@[^ ]+]] = private unnamed_addr constant [8 x i8] c"Q16@0:8\00"
// CHECK-DAG: [[ATTRIBUTES:@[^ ]+]] = private unnamed_addr constant [27 x i8] c"@32@0:8Q16^{_NSRange=QQ}24\00"
// CHECK-DAG: [[SEL_ARG:@[^ ]+]] = private unnamed_addr constant [11 x i8] c"v24@0:8:16\00"
// CHECK-DAG: [[SETTER:@[^ ]+]] = private unnamed_addr constant [11 x i8] c"v24@0:8Q16\00"
// CHECK-DAG: [[SET_SUBSCRIPT:@[^ ]+]] = private unnamed_addr constant [14 x i8] c"v32@0:8@16Q24\00"
// CHECK-DAG: [[COUNT_FOR:@[^ ]+]] = private unnamed_addr constant [11 x i8] c"Q24@0:8:16\00"
// A method with no Objective-C counterpart keeps the encoding of its Swift
// type.
// CHECK-DAG: [[OWN:@[^ ]+]] = private unnamed_addr constant [11 x i8] c"v24@0:8q16\00"

// Under the GNUstep runtime, which dispatches on typed selectors, the
// method's selector record carries the same encoding.
// GNUSTEP-DAG: @"\01L_gnustep_selector(textLength)" = {{.*}} { ptr @"\01L_selector_data(textLength)", ptr [[GETTER]] }
// GNUSTEP-DAG: @"\01L_gnustep_selector(noResponderFor:)" = {{.*}} { ptr @"\01L_selector_data(noResponderFor:)", ptr [[SEL_ARG]] }
// GNUSTEP-DAG: @"\01L_gnustep_selector(countForSelector:)" = {{.*}} { ptr @"\01L_selector_data(countForSelector:)", ptr [[COUNT_FOR]] }

// NEGATIVE-NOT: c"q16@0:8\00"
// NEGATIVE-NOT: ^v16

// CHECK-LABEL: @_INSTANCE_METHODS_{{(_TtC27objc_override_type_encoding3)?}}Sub =
// CHECK-SAME: (initWithCapacity:)", ptr [[INIT]]
// CHECK-SAME: (textLength)", ptr [[GETTER]]
// CHECK-SAME: (attributesAtIndex:effectiveRange:)", ptr [[ATTRIBUTES]]
// CHECK-SAME: (noResponderFor:)", ptr [[SEL_ARG]]
// CHECK-SAME: (count)", ptr [[GETTER]]
// CHECK-SAME: (limit)", ptr [[GETTER]]
// CHECK-SAME: (setLimit:)", ptr [[SETTER]]
// CHECK-SAME: (objectAtIndexedSubscript:)", ptr [[INIT]]
// CHECK-SAME: (setObject:atIndexedSubscript:)", ptr [[SET_SUBSCRIPT]]
// CHECK-SAME: (countForSelector:)", ptr [[COUNT_FOR]]
// CHECK-SAME: (total)", ptr [[GETTER]]
// CHECK-SAME: (own:)", ptr [[OWN]]

// A further override of a Swift override uses the Objective-C encoding too.
// The GNUstep runtime gives each class its own selector records, so the
// selector name may carry a uniquing suffix.
// CHECK-LABEL: @_INSTANCE_METHODS_{{(_TtC27objc_override_type_encoding6)?}}SubSub =
// CHECK-SAME: (textLength){{(\.[0-9]+)?}}", ptr [[GETTER]]

class Sub: Base, Counting {
  override init() { super.init() }
  override init(capacity: Int) { super.init(capacity: capacity) }
  override func textLength() -> Int { return 3 }
  override func attributes(
    at index: Int, effectiveRange range: UnsafeMutablePointer<NSRange>!
  ) -> Any! {
    return nil
  }
  override func noResponder(for selector: OpaquePointer!) {}
  override var count: Int { return 3 }
  override var limit: Int {
    get { return 3 }
    set {}
  }
  override subscript(index: Int) -> Any! {
    get { return nil }
    set {}
  }
  func count(for selector: OpaquePointer!) -> Int { return 3 }
  var total: Int { return 3 }
  @objc func own(_ value: Int) {}
}

class SubSub: Sub {
  override func textLength() -> Int { return 4 }
}
