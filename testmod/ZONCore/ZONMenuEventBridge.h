#ifndef ZONMenuEventBridge_h
#define ZONMenuEventBridge_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

void ZONMenuHandleAction(NSInteger legacyTag, UIViewController *presenter);
void ZONMenuHandleToggle(NSInteger legacyTag, BOOL enabled);
void ZONMenuHandleAdSwitch(UISwitch *sw);
void ZONMenuHandleAdSlider(UISlider *slider);
void ZONMenuSyncSettingsToRuntime(void);

NS_ASSUME_NONNULL_END

#endif /* ZONMenuEventBridge_h */
