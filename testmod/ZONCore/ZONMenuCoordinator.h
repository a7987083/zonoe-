#ifndef ZONMenuCoordinator_h
#define ZONMenuCoordinator_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONMenuCoordinator : NSObject <UIGestureRecognizerDelegate>

- (instancetype)initWithPresenter:(UIViewController *)presenter;

- (void)viewDidLoad;
- (void)viewDidAppear;
- (void)viewWillLayoutSubviews;

- (void)buildUI;
- (void)relayoutSections;
- (void)close;

- (void)cardButtonTap:(UIButton *)sender;
- (void)gridButtonTap:(UIButton *)sender;
- (void)switchChanged:(UISwitch *)sw;
- (void)adSwitchChanged:(UISwitch *)sw;
- (void)adSliderChanged:(UISlider *)slider;

@end

NS_ASSUME_NONNULL_END

#endif /* ZONMenuCoordinator_h */
