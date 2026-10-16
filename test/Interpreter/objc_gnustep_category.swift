// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_objc_messages %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepObjCMessages

// Under the GNUstep runtime, the @objc members of an extension of a class
// are in a category that the runtime attaches to the class when it loads
// the image, so Objective-C code finds them like the methods of a category
// implemented in Objective-C.  That holds both for a class declared in
// Objective-C, whose class object is in another image, and for a class
// declared in Swift.

extension NSObject: @retroactive Greeting {
  @objc public func greeting() -> Int { return 1 }
  @objc public func echo() -> NSObject { return self }
  @objc public class func make() -> Int { return 2 }
  @objc public var answer: Int { return 42 }
}

class Sub: NSObject {
  @objc var count: Int = 0
}

extension Sub {
  override func greeting() -> Int { return 10 }
  @objc func extra() -> NSObject { return self }
  @objc class func classExtra() {}
  @objc var label: Int { return 7 }
}

// CHECK: 1 1 1
print(respondsToSelector(NSObject(), "greeting"),
      respondsToSelector(NSObject(), "echo"),
      performSelectorReturnsSelf(NSObject(), "echo"))

// CHECK-NEXT: 1 1 0
print(hasInstanceMethod(NSObject.self, "greeting"),
      hasClassMethod(NSObject.self, "make"),
      hasInstanceMethod(NSObject.self, "extra"))

// The protocol conformance the extension declares is in the category, too.
// CHECK-NEXT: 1 1
print(conformsToProtocol(NSObject.self, "Greeting"),
      sendGreeting(NSObject()))

// CHECK-NEXT: 1 1 1 1
print(respondsToSelector(Sub(), "extra"),
      performSelectorReturnsSelf(Sub(), "extra"),
      hasInstanceMethod(Sub.self, "extra"),
      hasClassMethod(Sub.self, "classExtra"))

// CHECK-NEXT: 10 10
print(sendGreeting(Sub()), Sub().greeting())

// So are the properties.  The runtime links the property list of a category
// to the class's list, so the class's own properties are still found.
// CHECK-NEXT: Tq,N,R Tq,N,R Tq,N,Vcount
print(String(cString: propertyAttributes(NSObject.self, "answer")),
      String(cString: propertyAttributes(Sub.self, "label")),
      String(cString: propertyAttributes(Sub.self, "count")))
