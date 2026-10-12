// REQUIRES: OS=linux-gnu

// The symbols of Swift classes exposed to the GNUstep runtime are accounted
// for when validating the TBD against the IR.

// RUN: %target-swift-frontend -emit-ir -o /dev/null -parse-as-library -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=missing -I %S/../IRGen/Inputs/gnustep %s
// RUN: %target-swift-frontend -emit-ir -o /dev/null -parse-as-library -enable-objc-interop -objc-runtime=gnustep -disable-objc-attr-requires-foundation-module -validate-tbd-against-ir=all -I %S/../IRGen/Inputs/gnustep %s

import GNUstepRoot

public class Sub: Root {
  @objc public var count: Int = 0
  @objc public func hello() {}
}

class InternalSub: Root {
  @objc func hello() {}
}
