typedef unsigned char BOOL;

__attribute__((objc_root_class))
@interface Flag
- (BOOL)isSet;
- (void)setSet:(BOOL)value;
@end
