#ifndef ZONMenuEventBridge_h
#define ZONMenuEventBridge_h

#import <UIKit/UIKit.h>
#import "ZONFeatureDispatcher.h"
#import "ImgTool.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const ZONMenuNNGGEnableKey = @"NNGGNNGG";
static NSString * const ZONMenuAADDEnableKey = @"AADDAADD";
static NSString * const ZONMenuADSpeedKey = @"AADDssppeedd";

static inline void ZONMenuHandleAction(NSInteger legacyTag, UIViewController *presenter)
{
    (void)ZONDispatchMigratedActionForLegacyTag(legacyTag, presenter);
}

static inline void ZONMenuHandleToggle(NSInteger legacyTag, BOOL enabled)
{
    (void)ZONDispatchMigratedToggleForLegacyTag(legacyTag, enabled);
}

static inline void ZONMenuHandleAdSwitch(UISwitch *sw)
{
    UIView *box = sw.superview;
    UISlider *slider = [box viewWithTag:500];
    slider.enabled = sw.isOn;
    ZONMenuHandleToggle(sw.tag, sw.isOn);
}

static inline void ZONMenuHandleAdSlider(UISlider *slider)
{
    UIView *box = slider.superview;
    UILabel *valueLab = [box viewWithTag:600];
    valueLab.text = [NSString stringWithFormat:@"%.0f", slider.value];
    [NSUserDefaults.standardUserDefaults setFloat:slider.value forKey:ZONMenuADSpeedKey];
    NSLog(@"广告倍速设置：%.0f", slider.value);
}

static inline void ZONMenuSyncSettingsToRuntime(void)
{
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    [ImgTool share].NeiGou = [ud boolForKey:ZONMenuNNGGEnableKey];
    [ImgTool share].ADSpeed = [ud boolForKey:ZONMenuAADDEnableKey];
    NSInteger speed = [ud integerForKey:ZONMenuADSpeedKey];
    if (speed <= 0) speed = 1;
    [ImgTool share].ADBiansu = speed;
}

NS_ASSUME_NONNULL_END

#endif /* ZONMenuEventBridge_h */
