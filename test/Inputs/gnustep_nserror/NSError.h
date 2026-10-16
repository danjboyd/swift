// A stand-in for GNUstep's NSError.  The class itself is gnustep-base's.

#import <NSObject.h>

@interface NSError : NSObject
- (instancetype)initWithDomain:(id)domain code:(long)code userInfo:(id)dict;
- (id)domain;
- (long)code;
@end
