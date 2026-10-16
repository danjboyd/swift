// Objective-C code that finds classes by name in the Objective-C runtime and
// refers to a class that Swift defines, for tests of the names under which
// Swift classes register.  Its functions are compiled by the Clang that
// Swift embeds.

#import <NSObject.h>

Class objc_lookUpClass(const char *name);
const char *class_getName(Class cls);
Class object_getClass(id object);

/// The name the runtime has for a class.
static inline const char *nameOfClass(Class cls) {
  return class_getName(cls);
}

/// The class registered under a name, or Nil.
static inline Class classNamed(const char *name) {
  return objc_lookUpClass(name);
}

@interface NSObject (ClassNames)
+ (id)self;
@end

/// A Swift class as Objective-C code sees it through a generated header:
/// declared under its Swift name, which Clang refers to it by.
@interface Exported : NSObject
@end

static inline Class exportedClass(void) {
  return (Class)[Exported self];
}
