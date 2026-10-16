// RUN: %empty-directory(%t)
// RUN: %target-build-swift %gnustep-objc-interop-flags -Xfrontend -disable-objc-attr-requires-foundation-module -I %S/../Inputs/gnustep_nsobject -I %S/../Inputs/gnustep_nsarray %s -o %t/a.out
// RUN: %target-codesign %t/a.out
// RUN: %target-run %t/a.out | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: objc_interop_gnustep

import GNUstepNSArray

// A Swift value given to Objective-C is boxed in a __SwiftValue.  libobjc2
// keeps the reference count of an object in the word before it, so the box
// must be allocated with that word, or retaining and releasing it changes
// the allocator's bookkeeping, and the box is never deallocated.

@_silgen_name("object_getRetainCount_np")
func retainCount(_ object: UnsafeMutableRawPointer) -> Int

@_silgen_name("objc_retain")
func objcRetain(_ object: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer

@_silgen_name("objc_release")
func objcRelease(_ object: UnsafeMutableRawPointer)

func address(_ object: AnyObject) -> UnsafeMutableRawPointer {
  return Unmanaged.passUnretained(object).toOpaque()
}

var deinits = 0

final class Tracker {
  let id: Int
  init(_ id: Int) { self.id = id }
  deinit { deinits += 1 }
}

struct Tracked {
  var tracker: Tracker
  var extra = 7
}

// CHECK: 1 2 1
do {
  let box = Tracked(tracker: Tracker(0)) as AnyObject
  let before = retainCount(address(box))
  _ = objcRetain(address(box))
  let retained = retainCount(address(box))
  objcRelease(address(box))
  print(before, retained, retainCount(address(box)))
}

// Releasing the last reference deallocates the box and destroys the value.
// CHECK-NEXT: deinits 1
print("deinits", deinits)

// A value with a 16-byte alignment is boxed at that alignment.
// CHECK-NEXT: 1 true true
do {
  let value = SIMD2<Double>(1.5, -2.5)
  let box = value as AnyObject
  print(retainCount(address(box)),
        Int(bitPattern: address(box)) % 16 == 0,
        box as? SIMD2<Double> == value)
}

// An Objective-C collection retains and releases the boxes it holds.
// CHECK-NEXT: 1000 true
// CHECK-NEXT: deinits 1001
do {
  let array = NSMutableArray()!
  for i in 0..<1000 {
    array.add(Tracked(tracker: Tracker(i)))
  }
  var intact = true
  for i in 0..<1000 {
    let value = array.object(at: UInt(i)) as? Tracked
    intact = intact && value?.tracker.id == i && value?.extra == 7
  }
  print(array.count(), intact)
  array.removeAllObjects()
}
print("deinits", deinits)
