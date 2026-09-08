// SandboxBrowserVC.h
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SandboxBrowserVC : UIViewController <UITableViewDelegate, UITableViewDataSource>

// 可选初始路径，默认显示 Documents
@property (nonatomic, strong, nullable) NSString *startPath;

@end

NS_ASSUME_NONNULL_END
