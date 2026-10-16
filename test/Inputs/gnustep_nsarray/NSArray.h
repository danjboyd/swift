// A stand-in for GNUstep's NSMutableArray, which retains the objects it
// holds and releases them when it is emptied.  It is not named Foundation,
// so that tests do not load a Foundation overlay.

#import <NSObject.h>

@interface NSMutableArray : NSObject
- (void)addObject:(id)object;
- (id)objectAtIndex:(unsigned long)index;
- (unsigned long)count;
- (void)removeAllObjects;
@end
