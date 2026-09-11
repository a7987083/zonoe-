#ifndef ZONMenuCoordinator_h
#define ZONMenuCoordinator_h

#import <UIKit/UIKit.h>
#import "ZONSectionRenderer.h"
#import "ZONMenuChromeRenderer.h"
#import "ZONMenuPanelController.h"
#import "ZONMenuEventBridge.h"

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

@interface ZONMenuCoordinator ()
@property(nonatomic, weak) UIViewController *presenter;
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UIScrollView *scroll;
@property(nonatomic, strong) NSMutableArray<FoldSectionView *> *sections;
@property(nonatomic, assign) BOOL didBuildUI;
@end

@implementation ZONMenuCoordinator

- (instancetype)initWithPresenter:(UIViewController *)presenter {
    self = [super init];
    if (self) {
        _presenter = presenter;
    }
    return self;
}

- (void)viewDidLoad {
    UIView *hostView = self.presenter.view;
    if (!hostView || self.panel) return;

    hostView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO;
    [hostView addGestureRecognizer:tap];

    self.panel = ZONCreateMenuPanel(hostView, &_scroll);
    [self buildUI];
}

- (void)buildUI {
    if (self.didBuildUI) return;
    self.didBuildUI = YES;

    if (!self.sections) self.sections = [NSMutableArray array];
    [self.sections removeAllObjects];
    for (UIView *v in self.scroll.subviews) [v removeFromSuperview];
    self.scroll.showsVerticalScrollIndicator = YES;

    ZONRenderMenuHeader(self.panel, self.scroll);

    __weak typeof(self) weakSelf = self;
    NSArray<FoldSectionView *> *rendered = ZONRenderRegisteredSections(self.scroll,
                                                                       self.panel.bounds.size.width,
                                                                       self,
                                                                       @selector(cardButtonTap:),
                                                                       @selector(gridButtonTap:),
                                                                       @selector(switchChanged:),
                                                                       @selector(adSwitchChanged:),
                                                                       @selector(adSliderChanged:),
                                                                       ^{
        [weakSelf relayoutSections];
    });
    [self.sections addObjectsFromArray:rendered];
}

- (void)relayoutSections {
    if (!self.panel || !self.scroll) return;
    ZONRelayoutMenuSections(self.panel, self.scroll, self.sections);
}

- (void)viewDidAppear {
    UIView *hostView = self.presenter.view;
    if (!hostView || !self.panel) return;
    ZONMenuSyncSettingsToRuntime();
    ZONShowMenuPanel(hostView, self.panel);
}

- (void)viewWillLayoutSubviews {
    UIView *hostView = self.presenter.view;
    if (!hostView || !self.panel || !self.scroll) return;
    ZONLayoutVisibleMenuPanel(hostView, self.panel, self.scroll);
    [self relayoutSections];
}

- (void)close {
    UIViewController *presenter = self.presenter;
    UIView *hostView = presenter.view;
    if (!presenter || !hostView || !self.panel) return;

    __weak UIViewController *weakPresenter = presenter;
    ZONHideMenuPanel(hostView, self.panel, ^{
        [weakPresenter dismissViewControllerAnimated:NO completion:nil];
    });
}

- (void)adSwitchChanged:(UISwitch *)sw {
    ZONMenuHandleAdSwitch(sw);
}

- (void)adSliderChanged:(UISlider *)slider {
    ZONMenuHandleAdSlider(slider);
}

- (void)cardButtonTap:(UIButton *)sender {
    UIViewController *presenter = self.presenter;
    if (!presenter) return;
    ZONMenuHandleAction(sender.tag, presenter);
}

- (void)gridButtonTap:(UIButton *)sender {
    UIViewController *presenter = self.presenter;
    if (!presenter) return;
    ZONMenuHandleAction(sender.tag, presenter);
}

- (void)switchChanged:(UISwitch *)sw {
    ZONMenuHandleToggle(sw.tag, sw.isOn);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    (void)gestureRecognizer;
    UIView *hostView = self.presenter.view;
    if (!hostView || !self.panel) return YES;
    return !ZONMenuPanelContainsTouch(hostView, self.panel, touch);
}

@end

NS_ASSUME_NONNULL_END

#endif /* ZONMenuCoordinator_h */
