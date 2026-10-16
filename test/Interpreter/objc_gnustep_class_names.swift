// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -module-name ClassNames -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_class_names %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepClassNames

// Under the GNUstep runtime, a Swift class without an Objective-C name
// registers under the name Apple's runtime shows for it: Module.Class for a
// top-level class and the mangled name for any other.  So the runtime finds
// a class by the module-qualified name that NSClassFromString() callers,
// keyed archives and nibs built for Cocoa use, and not by its bare name.

class Plain: NSObject {}

class Outer: NSObject {
  class Inner: NSObject {}
}

private class Hidden: NSObject {}

@objc(Renamed) class SwiftNamed: NSObject {}

class Exported: NSObject {}

func name(_ cls: AnyClass) -> String {
  return String(cString: nameOfClass(cls))
}

func found(_ name: String, _ cls: AnyClass) -> Bool {
  return classNamed(name).map { ObjectIdentifier($0) } == ObjectIdentifier(cls)
}

// CHECK: ClassNames.Plain true false
print(name(Plain.self), found("ClassNames.Plain", Plain.self),
      classNamed("Plain") != nil)

// CHECK-NEXT: _TtCC10ClassNames5Outer5Inner true
print(name(Outer.Inner.self),
      found("_TtCC10ClassNames5Outer5Inner", Outer.Inner.self))

// CHECK-NEXT: _TtC10ClassNamesP33_{{[0-9A-F]+}}6Hidden
print(name(Hidden.self))

// CHECK-NEXT: Renamed true
print(name(SwiftNamed.self), found("Renamed", SwiftNamed.self))

// Objective-C code still refers to a Swift class by the name the generated
// header declares it under, and gets the same class.
// CHECK-NEXT: ClassNames.Exported true
print(name(exportedClass()),
      ObjectIdentifier(exportedClass()) == ObjectIdentifier(Exported.self))

// Instances answer the class.
// CHECK-NEXT: ClassNames.Plain
print(name(object_getClass(Plain())!))
