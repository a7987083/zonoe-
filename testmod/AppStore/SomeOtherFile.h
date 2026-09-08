#import <Foundation/Foundation.h> // 通常引入 Foundation 框架，提供 NSObject 等基础类

@interface SomeOtherFile : NSObject

// 声明一个方法，用于触发展示 App Store 产品页面的逻辑
// 这个方法可以被其他类调用
- (void)userClickedPromoteButton;

@end
