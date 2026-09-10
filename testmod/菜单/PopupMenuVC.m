#import "PopupMenuVC.h"
#import "FoldSectionView.h"
#import "../ZONCore/ZONSectionRenderer.h"
#import "../ZONCore/ZONMenuChromeRenderer.h"
#import "../ZONCore/ZONMenuPanelController.h"
#import "../ZONCore/ZONMenuEventBridge.h"

@interface PopupMenuVC () <UIGestureRecognizerDelegate>
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) NSMutableArray<FoldSectionView *> *sections;
@property(nonatomic, assign) BOOL didBuildUI;
@end

@implementation PopupMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    self.panel = ZONCreateMenuPanel(self.view, &_scroll);
    [self buildUI];
}

- (void)relayoutSections {
    ZONRelayoutMenuSections(self.panel, self.scroll, self.sections);
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

- (void)adSwitchChanged:(UISwitch *)sw {
    ZONMenuHandleAdSwitch(sw);
}

- (void)adSliderChanged:(UISlider *)slider {
    ZONMenuHandleAdSlider(slider);
}

- (void)cardButtonTap:(UIButton *)sender {
    ZONMenuHandleAction(sender.tag, self);
}

- (void)gridButtonTap:(UIButton *)sender {
    ZONMenuHandleAction(sender.tag, self);
}

- (void)switchChanged:(UISwitch *)sw {
    ZONMenuHandleToggle(sw.tag, sw.isOn);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    ZONMenuSyncSettingsToRuntime();
    ZONShowMenuPanel(self.view, self.panel);
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    ZONLayoutVisibleMenuPanel(self.view, self.panel, self.scroll);
    [self relayoutSections];
}

- (void)close {
    __weak typeof(self) weakSelf = self;
    ZONHideMenuPanel(self.view, self.panel, ^{
        [weakSelf dismissViewControllerAnimated:NO completion:nil];
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    (void)gestureRecognizer;
    return !ZONMenuPanelContainsTouch(self.view, self.panel, touch);
}

@end
