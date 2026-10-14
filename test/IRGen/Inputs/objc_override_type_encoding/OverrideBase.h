typedef unsigned long NSUInteger;
typedef struct _NSRange {
  NSUInteger location;
  NSUInteger length;
} NSRange;

__attribute__((objc_root_class))
@interface Base
+ (instancetype)alloc;
- (instancetype)init;
- (instancetype)initWithCapacity:(NSUInteger)capacity;
- (NSUInteger)textLength;
- (id)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRange *)range;
- (void)noResponderFor:(SEL)selector;
@property (readonly) NSUInteger count;
@property NSUInteger limit;
- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;
@end

@protocol Counting
- (NSUInteger)countForSelector:(SEL)selector;
@property (readonly) NSUInteger total;
@end
