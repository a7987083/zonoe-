#import <UIKit/UIKit.h>

@interface CSJPlayableWebVM : NSObject

@property(nonatomic) BOOL hasSendReward;
@property(nonatomic) BOOL didSendIsVerifyRewardJSB;
@property(retain, nonatomic) id playableAd;

- (void)sendPlayableReward;
- (double)getCloseDelayTime;
- (id)jsCallNative_getSendRewardStatus;

@end
