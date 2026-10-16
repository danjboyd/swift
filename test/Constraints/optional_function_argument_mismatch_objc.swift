// RUN: %empty-directory(%t)
// RUN: split-file %s %t
// RUN: %target-typecheck-verify-swift -enable-objc-interop -disable-objc-attr-requires-foundation-module -I %t/Inputs

// An optional protocol requirement, and a method found through AnyObject
// lookup, is bound to an optional function type.  Diagnosing an optional
// argument that does not match an optional parameter of such a method used
// to assume a plain function type and crash.

//--- Inputs/module.modulemap
module OptionalRequirements {
  header "OptionalRequirements.h"
}

//--- Inputs/OptionalRequirements.h
__attribute__((objc_root_class))
@interface Note
@end

__attribute__((objc_root_class))
@interface Other
@end

@protocol NoteObserver
@optional
- (void)noteWillPost:(Note *)note;
@end

//--- main.swift
import OptionalRequirements

@objc class A {}
@objc class B {}

@objc protocol P {
  @objc optional func take(_ a: A?)
}

class C {
  @objc func takeAny(_ x: Any?) {}
  @objc func takeA(_ a: A?) {}
}

func testOptionalRequirement(p: P, b: B?) {
  p.take?(b) // expected-error {{cannot convert value of type 'B?' to expected argument type 'A?'}}
  // expected-note@-1 {{arguments to generic parameter 'Wrapped' ('B' and 'A') are expected to be equal}}
  p.take!(b) // expected-error {{cannot convert value of type 'B?' to expected argument type 'A?'}}
  // expected-note@-1 {{arguments to generic parameter 'Wrapped' ('B' and 'A') are expected to be equal}}
}

func testDynamicLookup(o: AnyObject, b: B?) {
  o.takeA(b) // expected-error {{cannot convert value of type 'B?' to expected argument type 'A?'}}
  // expected-note@-1 {{arguments to generic parameter 'Wrapped' ('B' and 'A') are expected to be equal}}
  o.takeA?(b) // expected-error {{cannot convert value of type 'B?' to expected argument type 'A?'}}
  // expected-note@-1 {{arguments to generic parameter 'Wrapped' ('B' and 'A') are expected to be equal}}
}

// The argument matches; the mismatch is only explored while fixing the
// unrelated error.
func testDynamicLookupWhileFixing(i: Int, o: AnyObject, a: A?) {
  _ = (i(), o.takeAny(a)) // expected-error {{cannot call value of non-function type 'Int'}}
}

func testImportedOptionalRequirement(observer: NoteObserver, other: Other?) {
  observer.noteWillPost?(other) // expected-error {{cannot convert value of type 'Other?' to expected argument type 'Note?'}}
  // expected-note@-1 {{arguments to generic parameter 'Wrapped' ('Other' and 'Note') are expected to be equal}}
}
