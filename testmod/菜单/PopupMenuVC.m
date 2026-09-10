#import "PopupMenuVC.h"
#import "FoldSectionView.h"
#import "ImgTool.h"
#import "../ZONCore/ZONFeatureDispatcher.h"
#import "../ZONCore/ZONSectionRenderer.h"

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
    CGFloat sectionW = self.panel.bounds.size.width - 30;
    CGFloat y = 110;
    for (FoldSectionView *sec in self.sections) {
        CGFloat h = [sec layoutAndGetHeight];
        sec.frame = CGRectMake(15, y, sectionW, h);
        y += h + 15;
    }
    self.scroll.contentSize = CGSizeMake(self.panel.bounds.size.width, y + 20);
}

- (void)buildUI {
    if (self.didBuildUI) return;
    self.didBuildUI = YES;

    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    NSString *jsm = [ud objectForKey:@"解锁码到期时间"];
    NSString *yjy = [ud objectForKey:@"到期时间"];
    NSString *fwqbbh = [ud objectForKey:@"服务器版本号"];
    NSString *yymc = [ud objectForKey:@"应用名称"];
    NSString *appVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    if (!yymc) yymc = @"未知应用";
    if (!fwqbbh) fwqbbh = @"未知版本";
    if (!appVersion) appVersion = @"0.0.0";
    if (!jsm || jsm.length == 0) jsm = yjy;

    CGFloat width = self.panel.bounds.size.width;
    if (!self.sections) self.sections = [NSMutableArray array];
    [self.sections removeAllObjects];
    for (UIView *v in self.scroll.subviews) [v removeFromSuperview];
    self.scroll.showsVerticalScrollIndicator = YES;

    CGFloat left = 20;
    CGFloat top = 10;
    CGFloat maxW = width - 40;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.text = [NSString stringWithFormat:@"zonoe源++ %@ 解锁码到期：%@", yymc, jsm];
    title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    title.textColor = UIColor.blackColor;
    title.numberOfLines = 0;
    [self.panel addSubview:title];
    CGSize s1 = [title sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    title.frame = CGRectMake(left, top, maxW, s1.height);
    CGFloat curY = top + s1.height + 6;

    UILabel *line2 = [[UILabel alloc] initWithFrame:CGRectZero];
    line2.text = [NSString stringWithFormat:@"当前版本：%@", appVersion];
    line2.font = [UIFont systemFontOfSize:14];
    line2.textColor = UIColor.grayColor;
    [self.panel addSubview:line2];
    CGSize s2 = [line2 sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    line2.frame = CGRectMake(left, curY, maxW, s2.height);
    curY += s2.height + 2;

    UILabel *line3 = [[UILabel alloc] initWithFrame:CGRectZero];
    line3.text = [NSString stringWithFormat:@"App Store版本：%@", fwqbbh];
    line3.font = [UIFont systemFontOfSize:14];
    line3.textColor = UIColor.grayColor;
    [self.panel addSubview:line3];
    CGSize s3 = [line3 sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    line3.frame = CGRectMake(left, curY, maxW, s3.height);
    curY += s3.height + 12;

    CGFloat scrollTop = curY;
    self.scroll.frame = CGRectMake(0, scrollTop, width, self.panel.bounds.size.height - scrollTop);
    [self.panel addSubview:self.scroll];

    __weak typeof(self) weakSelf = self;
    NSArray<FoldSectionView *> *rendered = ZONRenderRegisteredSections(self.scroll,
                                                                       width,
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
