@protocol Greeting
- (void)greet;
@end

__attribute__((objc_root_class))
@interface Root <Greeting>
+ (instancetype)alloc;
- (instancetype)init;
- (void)greet;
@end

@protocol Named
- (const char *)name;
@end
