// REQUIRES: OS=linux-gnu

// The Clang importer parses Objective-C for the runtime that Objective-C
// interop targets.

// RUN: %target-swift-frontend -typecheck -parse-stdlib -enable-objc-interop -disable-objc-attr-requires-foundation-module -dump-clang-diagnostics %s 2>&1 | %FileCheck %s -check-prefix=APPLE
// APPLE: clang importer driver args:{{.*}}'-fobjc-runtime=ios-7.0'

// RUN: %target-swift-frontend -typecheck -parse-stdlib -enable-objc-interop -disable-objc-attr-requires-foundation-module -objc-runtime=gnustep -dump-clang-diagnostics %s 2>&1 | %FileCheck %s -check-prefix=GNUSTEP
// GNUSTEP: clang importer driver args:{{.*}}'-fobjc-runtime=gnustep-2.0'
// GNUSTEP-NOT: -fobjc-runtime=ios-7.0

@objc protocol P {}
