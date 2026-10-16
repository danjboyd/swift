// An object whose -class answers Nil, as the listener of GNUstep's services
// manager (GSListener in libs-gui) does to hide what it is.  The class is
// made at run time, since the Clang that Swift embeds compiles only the
// inline functions of a header.

#import <NSObject.h>

typedef id (*IMP)(id, SEL, ...);

SEL sel_registerName(const char *name);
Class objc_getClass(const char *name);
Class objc_allocateClassPair(Class superclass, const char *name,
                             unsigned long extraBytes);
void objc_registerClassPair(Class cls);
unsigned char class_addMethod(Class cls, SEL name, IMP imp, const char *types);

static id nilClass(id self, SEL _cmd) { return (id)0; }

/// A new instance of NilClassObject, a subclass of NSObject whose -class
/// answers Nil.  The result is `id`, which Swift imports as `Any!`.
static inline id makeNilClassObject(void) {
  static Class cls;
  if (!cls) {
    cls = objc_allocateClassPair(objc_getClass("NSObject"), "NilClassObject",
                                 0);
    class_addMethod(cls, sel_registerName("class"), (IMP)nilClass, "#@:");
    objc_registerClassPair(cls);
  }
  return [[(id)cls alloc] init];
}
