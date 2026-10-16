// Objective-C code that sends messages to objects and looks their methods up
// in the Objective-C runtime, for tests of the methods Swift adds to classes.
// Its functions are compiled by the Clang that Swift embeds.

#import <NSObject.h>

typedef struct objc_method *Method;
typedef struct objc_property *objc_property_t;

SEL sel_registerName(const char *name);
Method class_getInstanceMethod(Class cls, SEL name);
Method class_getClassMethod(Class cls, SEL name);
Protocol *objc_getProtocol(const char *name);
objc_property_t class_getProperty(Class cls, const char *name);
const char *property_getAttributes(objc_property_t property);

@interface NSObject (Messages)
+ (Class)class;
- (unsigned char)respondsToSelector:(SEL)selector;
- (id)performSelector:(SEL)selector;
@end

@protocol Greeting
- (long)greeting;
@end

static inline int respondsToSelector(NSObject *object, const char *name) {
  return [object respondsToSelector:sel_registerName(name)] ? 1 : 0;
}

/// Whether -performSelector: with the named selector returns the receiver.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
static inline int performSelectorReturnsSelf(NSObject *object,
                                             const char *name) {
  return [object performSelector:sel_registerName(name)] == object;
}
#pragma clang diagnostic pop

static inline long sendGreeting(id<Greeting> object) {
  return [object greeting];
}

static inline int hasInstanceMethod(Class cls, const char *name) {
  return class_getInstanceMethod(cls, sel_registerName(name)) != 0;
}

static inline int hasClassMethod(Class cls, const char *name) {
  return class_getClassMethod(cls, sel_registerName(name)) != 0;
}

static inline int conformsToProtocol(Class cls, const char *name) {
  return class_conformsToProtocol(cls, objc_getProtocol(name));
}

/// The attributes of the named property of a class, or "none".
static inline const char *propertyAttributes(Class cls, const char *name) {
  objc_property_t property = class_getProperty(cls, name);
  return property ? property_getAttributes(property) : "none";
}
