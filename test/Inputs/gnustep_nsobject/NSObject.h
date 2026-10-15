// A stand-in for GNUstep's Foundation, which declares NSObject in
// Foundation/NSObject.h rather than in the Objective-C runtime's headers, so
// that NSObject and Protocol are not in the ObjectiveC module.  It is not
// named Foundation, so that tests do not load a Foundation overlay.

@class Protocol;

__attribute__((objc_root_class))
@interface NSObject
+ (instancetype)alloc;
- (instancetype)init;
@end

@protocol NSCoding
- (void)encodeWithCoder:(id)coder;
@end

int class_conformsToProtocol(Class cls, Protocol *protocol);
