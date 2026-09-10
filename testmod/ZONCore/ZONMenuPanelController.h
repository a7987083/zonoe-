#ifndef ZONMenuPanelController_h
#define ZONMenuPanelController_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZONMenuPanelCompletionBlock)(void);

static inline UIView *ZONCreateMenuPanel(UIView *hostView, UIScrollView * __strong _Nullable * _Nullable outScrollView)
{
    CGFloat screenW = hostView.bounds.size.width;
    CGFloat screenH = hostView.bounds.size.height;
    CGFloat panelHeight = screenH * 0.85;

    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(20, screenH, screenW - 40, panelHeight)];
    panel.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    panel.layer.cornerRadius = 25;
    panel.clipsToBounds = YES;
    [hostView addSubview:panel];

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:panel.bounds];
    scroll.showsVerticalScrollIndicator = NO;
    [panel addSubview:scroll];

    if (outScrollView) *outScrollView = scroll;
    return panel;
}

static inline void ZONLayoutVisibleMenuPanel(UIView *hostView, UIView *panel, UIScrollView *scroll)
{
    CGFloat screenW = hostView.bounds.size.width;
    CGFloat screenH = hostView.bounds.size.height;
    CGFloat panelHeight = screenH * 0.85;

    panel.frame = CGRectMake(20, screenH - panelHeight - 20, screenW - 40, panelHeight);
    scroll.frame = panel.bounds;
}

static inline void ZONShowMenuPanel(UIView *hostView, UIView *panel)
{
    CGFloat screenH = hostView.bounds.size.height;
    [UIView animateWithDuration:0.25 animations:^{
        CGRect frame = panel.frame;
        frame.origin.y = screenH - frame.size.height - 20;
        panel.frame = frame;
    }];
}

static inline void ZONHideMenuPanel(UIView *hostView,
                                    UIView *panel,
                                    ZONMenuPanelCompletionBlock _Nullable completion)
{
    CGFloat screenH = hostView.bounds.size.height;
    [UIView animateWithDuration:0.25 animations:^{
        CGRect frame = panel.frame;
        frame.origin.y = screenH;
        panel.frame = frame;
    } completion:^(BOOL finished) {
        (void)finished;
        if (completion) completion();
    }];
}

static inline BOOL ZONMenuPanelContainsTouch(UIView *hostView, UIView *panel, UITouch *touch)
{
    CGPoint point = [touch locationInView:hostView];
    return CGRectContainsPoint(panel.frame, point);
}

NS_ASSUME_NONNULL_END

#endif /* ZONMenuPanelController_h */
