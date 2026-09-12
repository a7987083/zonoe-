#ifndef ZONMenuPanelController_h
#define ZONMenuPanelController_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZONMenuPanelCompletionBlock)(void);

UIView *ZONCreateMenuPanel(UIView *hostView,
                           UIScrollView * __strong _Nullable * _Nullable outScrollView);
void ZONLayoutVisibleMenuPanel(UIView *hostView, UIView *panel, UIScrollView *scroll);
void ZONShowMenuPanel(UIView *hostView, UIView *panel);
void ZONHideMenuPanel(UIView *hostView,
                      UIView *panel,
                      ZONMenuPanelCompletionBlock _Nullable completion);
BOOL ZONMenuPanelContainsTouch(UIView *hostView, UIView *panel, UITouch *touch);

NS_ASSUME_NONNULL_END

#endif /* ZONMenuPanelController_h */
