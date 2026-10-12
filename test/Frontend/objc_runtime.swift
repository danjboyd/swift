// REQUIRES: OS=linux-gnu

// RUN: %target-swift-frontend -typecheck -parse-stdlib -enable-objc-interop -disable-objc-attr-requires-foundation-module -objc-runtime=gnustep %s
// RUN: %target-swift-frontend -typecheck -parse-stdlib -enable-objc-interop -disable-objc-attr-requires-foundation-module -objc-runtime=apple %s

// RUN: not %target-swift-frontend -typecheck -parse-stdlib -disable-objc-interop -objc-runtime=gnustep %s 2>&1 | %FileCheck %s -check-prefix=NO-INTEROP
// NO-INTEROP: error: '-objc-runtime=gnustep' requires Objective-C interop; pass '-enable-objc-interop'

// RUN: not %target-swift-frontend -typecheck -parse-stdlib -enable-objc-interop -objc-runtime=objfw %s 2>&1 | %FileCheck %s -check-prefix=INVALID
// INVALID: error: invalid value 'objfw' in '-objc-runtime='

// RUN: not %swift_frontend_plain -typecheck -parse-stdlib -target arm64-apple-macos13 -objc-runtime=gnustep %s 2>&1 | %FileCheck %s -check-prefix=UNSUPPORTED
// UNSUPPORTED: error: unsupported option '-objc-runtime=gnustep' for target 'arm64-apple-macos13'

@objc protocol P {}
