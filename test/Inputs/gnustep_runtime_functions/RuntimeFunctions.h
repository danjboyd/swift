// Parts of GNUstep's NSObject and of the Objective-C runtime that tests
// check Swift classes and protocols with.

#import <NSObject.h>

@interface NSObject (ClassMethods)
+ (Class)superclass;
@end

Protocol *objc_getProtocol(const char *name);
const char *protocol_getName(Protocol *protocol);
const char *class_getName(Class cls);
