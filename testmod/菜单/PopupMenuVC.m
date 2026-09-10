#import "PopupMenuVC.h"
#import "FoldSectionView.h"
#import "ImgTool.h"
#import "../ZONCore/ZONFeatureDispatcher.h"
#import "../ZONCore/ZONSectionRenderer.h"
#import "../ZONCore/ZONMenuChromeRenderer.h"

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

    [self setupPanel];
    [self buildUI];
}

- (void)setupPanel {
    CGFloat screenW = self.view.bounds.size.width;
    CGFloat screenH = self.view.bounds.size.height;
    CGFloat panelHeight = screenH * 0.85;

    self.panel = [[UIView alloc] initWithFrame:CGRectMake(20, screenH, screenW - 40, panelHeight)];
    self.panel.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    self.panel.layer.cornerRadius = 25;
    self.panel.clipsToBounds = YES;
    [self.view addSubview:self.panel];

    self.scroll = [[UIScrollView alloc] initWithFrame:self.panel.bounds];
    self.scroll.showsVerticalScrollIndicator = NO;
    [self.panel addSubview:self.scroll];
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
    [self showPanel];
}

- (void)showPanel {
    CGFloat screenH = self.view.bounds.size.height;
    [UIView animateWithDuration:0.25 animations:^{
        CGRect f = self.panel.frame;
        f.origin.y = screenH - f.size.height - 20;
        self.panel.frame = f;
    }];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat screenW = self.view.bounds.size.width;
    CGFloat screenH = self.view.bounds.size.height;
    CGFloat panelHeight = screenH * 0.85;
    self.panel.frame = CGRectMake(20, screenH - panelHeight - 20, screenW - 40, panelHeight);
    self.scroll.frame = self.panel.bounds;
    [self relayoutSections];
}

- (void)close {
    CGFloat screenH = self.view.bounds.size.height;
    [UIView animateWithDuration:0.25 animations:^{
        CGRect f = self.panel.frame;
        f.origin.y = screenH;
        self.panel.frame = f;
    } completion:^(BOOL finished) {
        (void)finished;
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    (void)gestureRecognizer;
    CGPoint point = [touch locationInView:self.view];
    return !CGRectContainsPoint(self.panel.frame, point);
}

@end
