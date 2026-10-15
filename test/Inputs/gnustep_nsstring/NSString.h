// A stand-in for the parts of GNUstep's Foundation that describe objects
// with strings.  It is not named Foundation, so that tests do not load a
// Foundation overlay, and String does not bridge to NSString.

#import <NSObject.h>

@interface NSObject (Description)
- (id)description;
- (id)debugDescription;
- (signed char)isKindOfClass:(Class)aClass;
@end

@interface NSString : NSObject
- (const char *)UTF8String;
@end
