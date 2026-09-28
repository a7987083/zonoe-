#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef UIViewController * _Nullable (^ZONPresentationBuilder)(dispatch_block_t finish);

@interface ZONPresentationCoordinator : NSObject
+ (instancetype)sharedCoordinator;
- (void)enqueueWithKey:(NSString *)key builder:(ZONPresentationBuilder)builder;
- (void)enqueueWithKey:(NSString *)key
             onFailure:(nullable dispatch_block_t)onFailure
               builder:(ZONPresentationBuilder)builder;
- (void)cancelPendingWithKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
