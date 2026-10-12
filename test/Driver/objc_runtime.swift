// The driver passes -objc-runtime= through to the frontend unchanged; it does
// not change whether Objective-C interop is enabled.

// RUN: %swiftc_driver -driver-print-jobs -c -target x86_64-unknown-linux-gnu -objc-runtime=gnustep %s 2>&1 | %FileCheck %s -check-prefix=GNUSTEP
// GNUSTEP: -frontend
// GNUSTEP-SAME: -disable-objc-interop
// GNUSTEP-SAME: -objc-runtime=gnustep

// RUN: %swiftc_driver -driver-print-jobs -c -target x86_64-unknown-linux-gnu %s 2>&1 | %FileCheck %s -check-prefix=DEFAULT
// DEFAULT: -frontend
// DEFAULT-NOT: -objc-runtime=
