#import <NSObject.h>

@protocol Tagged
- (long)tag;
@end

@protocol Kinded
+ (long)kind;
@end

Class object_getClass(id object);
Class class_getSuperclass(Class cls);
const char *class_getName(Class cls);
