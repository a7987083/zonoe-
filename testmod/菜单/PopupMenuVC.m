#import "PopupMenuVC.h"
#import "FoldSectionView.h"
#import "ImgTool.h"
#import "../ZONCore/ZONFeatureDispatcher.h"
#import "../ZONCore/ZONSectionRenderer.h"
#import "../ZONCore/ZONMenuChromeRenderer.h"
#import "../ZONCore/ZONMenuPanelController.h"

@interface PopupMenuVC () <UIGestureRecognizerDelegate>
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) NSMutableArray<FoldSectionView *> *sections;
@property(nonatomic, assign) BOOL didBuildUI;
@end

static NSString * const kNNGGEnableKey = @"NNGGNNGG";
static NSString * const kAADDEnableKey = @"AADDAADD";
static NSString * const kADSpeedKey = @"AADDssppeedd";

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
    UIView *box = sw.superview;
    UISlider *slider = [box viewWithTag:500];
    slider.enabled = sw.isOn;
    (void)ZONDispatchMigratedToggleForLegacyTag(sw.tag, sw.isOn);
}

- (void)adSliderChanged:(UISlider *)slider {
    UIView *box = slider.superview;
    UILabel *valueLab = [box viewWithTag:600];
    valueLab.text = [NSString stringWithFormat:@"%.0f", slider.value];
    [NSUserDefaults.standardUserDefaults setFloat:slider.value forKey:kADSpeedKey];
    NSLog(@"广告倍速设置：%.0f", slider.value);
}

- (void)cardButtonTap:(UIButton *)sender { (void)ZONDispatchMigratedActionForLegacyTag(sender.tag, self); }
- (void)gridButtonTap:(UIButton *)sender { (void)ZONDispatchMigratedActionForLegacyTag(sender.tag, self); }
- (void)switchChanged:(UISwitch *)sw { (void)ZONDispatchMigratedToggleForLegacyTag(sw.tag, sw.isOn); }

- (void)syncSettingsToRuntime {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    [ImgTool share].NeiGou = [ud boolForKey:kNNGGEnableKey];
    [ImgTool share].ADSpeed = [ud boolForKey:kAADDEnableKey];
    NSInteger speed = [ud integerForKey:kADSpeedKey];
    if (speed <= 0) speed = 1;
    [ImgTool share].ADBiansu = speed;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self syncSettingsToRuntime];
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
