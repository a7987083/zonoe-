#import "PopupMenuVC.h"
#import "FoldSectionView.h"
#import "ImgTool.h"
#import "../ZONCore/ZONFeatureDispatcher.h"

@interface PopupMenuVC () <UIGestureRecognizerDelegate>

@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) NSMutableArray<FoldSectionView *> *sections;
@property(nonatomic, assign) BOOL didBuildUI;
@property(nonatomic,strong) NSArray<NSDictionary<NSString *, id> *> *cardItems;

@end

#pragma mark - UserDefaults Keys（统一管理）

static NSString * const kNNGGEnableKey = @"NNGGNNGG";
static NSString * const kAADDEnableKey = @"AADDAADD";
static NSString * const kADSpeedKey    = @"AADDssppeedd";

@implementation PopupMenuVC

#pragma mark - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];

    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    // v1_p19: visible menu item title/tag/order now come from Feature Registry.
    self.cardItems = ZONFeatureMetadataForSection(@"基础功能");

    [self setupPanel];
    [self buildUI];
}

#pragma mark - 创建Panel

- (void)setupPanel {
    CGFloat screenW = self.view.bounds.size.width;
    CGFloat screenH = self.view.bounds.size.height;
    CGFloat panelHeight = screenH * 0.85;

    self.panel = [[UIView alloc] initWithFrame:CGRectMake(20,
                                                           screenH,
                                                           screenW - 40,
                                                           panelHeight)];
    self.panel.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    self.panel.layer.cornerRadius = 25;
    self.panel.clipsToBounds = YES;
    [self.view addSubview:self.panel];

    self.scroll = [[UIScrollView alloc] initWithFrame:self.panel.bounds];
    self.scroll.showsVerticalScrollIndicator = NO;
    [self.panel addSubview:self.scroll];
}

#pragma mark - 折叠后重新排列所有 section

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

#pragma mark - 构建UI

- (void)buildUI {
    if (self.didBuildUI) return;
    self.didBuildUI = YES;

    NSString *jsm = [[NSUserDefaults standardUserDefaults] objectForKey:@"解锁码到期时间"];
    NSString *yjy = [[NSUserDefaults standardUserDefaults] objectForKey:@"到期时间"];
    NSString *fwqbbh = [[NSUserDefaults standardUserDefaults] objectForKey:@"服务器版本号"];
    NSString *yymc = [[NSUserDefaults standardUserDefaults] objectForKey:@"应用名称"];
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];

    if (!yymc) yymc = @"未知应用";
    if (!fwqbbh) fwqbbh = @"未知版本";
    if (!appVersion) appVersion = @"0.0.0";
    if (!jsm || jsm.length == 0) jsm = yjy;

    NSArray<NSDictionary<NSString *, id> *> *dataItems = ZONFeatureMetadataForSection(@"数据功能");
    NSArray<NSDictionary<NSString *, id> *> *runtimeItems = ZONFeatureMetadataForSection(@"其他功能");

    CGFloat width = self.panel.bounds.size.width;
    if (!self.sections) self.sections = [NSMutableArray array];
    [self.sections removeAllObjects];

    for (UIView *v in self.scroll.subviews) {
        [v removeFromSuperview];
    }
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
    line2.numberOfLines = 1;
    [self.panel addSubview:line2];

    CGSize s2 = [line2 sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    line2.frame = CGRectMake(left, curY, maxW, s2.height);
    curY += s2.height + 2;

    UILabel *line3 = [[UILabel alloc] initWithFrame:CGRectZero];
    line3.text = [NSString stringWithFormat:@"App Store版本：%@", fwqbbh];
    line3.font = [UIFont systemFontOfSize:14];
    line3.textColor = UIColor.grayColor;
    line3.numberOfLines = 1;
    [self.panel addSubview:line3];

    CGSize s3 = [line3 sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    line3.frame = CGRectMake(left, curY, maxW, s3.height);
    curY += s3.height + 12;

    CGFloat scrollTop = curY;
    self.scroll.frame = CGRectMake(0, scrollTop, width, self.panel.bounds.size.height - scrollTop);
    [self.panel addSubview:self.scroll];

    CGFloat y = 0;
    CGFloat sectionW = width - 30;
    CGFloat gap = 65;
    __weak typeof(self) weakSelf = self;

    FoldSectionView *secBase = [[FoldSectionView alloc] initWithTitle:@"基础功能"
                                                              detail:@"远程下载 / 云存档"
                                                              status:[NSString stringWithFormat:@"%lu项", (unsigned long)self.cardItems.count]];
    secBase.stateKey = @"fold_base";
    secBase.frame = CGRectMake(15, y, sectionW, 70);
    [self.scroll addSubview:secBase];
    [self.sections addObject:secBase];

    for (NSInteger i = 0; i < self.cardItems.count; i++) {
        NSDictionary<NSString *, id> *feature = self.cardItems[i];
        NSString *cardTitle = feature[ZONFeatureTitleKey];
        NSInteger tag = [feature[ZONFeatureLegacyTagKey] integerValue];

        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(15, 10 + i * gap, sectionW - 30, 55)];
        card.backgroundColor = UIColor.whiteColor;
        card.layer.cornerRadius = 16;
        [secBase.contentView addSubview:card];

        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 160, 55)];
        lab.text = cardTitle;
        lab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        [card addSubview:lab];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(card.bounds.size.width - 80, 12, 65, 32);
        btn.backgroundColor = UIColor.systemBlueColor;
        btn.layer.cornerRadius = 16;
        [btn setTitle:@"打开" forState:UIControlStateNormal];
        [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        btn.tag = tag;
        [btn addTarget:self action:@selector(cardButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:btn];
    }

    secBase.onToggle = ^(BOOL expanded){
        (void)expanded;
        [UIView animateWithDuration:0.25 animations:^{
            [weakSelf relayoutSections];
        }];
    };
    CGFloat hBase = [secBase layoutAndGetHeight];
    secBase.frame = CGRectMake(15, y, sectionW, hBase);
    y += hBase + 15;

    FoldSectionView *secDraw = [[FoldSectionView alloc] initWithTitle:@"数据功能"
                                                              detail:@"备份存档 /恢复存档 / 清理配置和授权"
                                                              status:[NSString stringWithFormat:@"%lu项", (unsigned long)dataItems.count]];
    secDraw.stateKey = @"fold_draw";
    secDraw.frame = CGRectMake(15, y, sectionW, 70);
    [self.scroll addSubview:secDraw];
    [self.sections addObject:secDraw];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self addGridButtonsForFeatures:dataItems toSection:secDraw.contentView y:10];
        [self relayoutSections];
    });

    secDraw.onToggle = ^(BOOL expanded){
        (void)expanded;
        [UIView animateWithDuration:0.25 animations:^{
            [weakSelf relayoutSections];
        }];
    };
    CGFloat hDraw = [secDraw layoutAndGetHeight];
    secDraw.frame = CGRectMake(15, y, sectionW, hDraw);
    y += hDraw + 15;

    FoldSectionView *secRole = [[FoldSectionView alloc] initWithTitle:@"其他功能"
                                                              detail:@"1 / 2 / 3"
                                                              status:[NSString stringWithFormat:@"%lu项", (unsigned long)runtimeItems.count]];
    secRole.stateKey = @"fold_role";
    secRole.frame = CGRectMake(15, y, sectionW, 70);
    [self.scroll addSubview:secRole];
    [self.sections addObject:secRole];

    if (runtimeItems.count > 0) {
        [secRole.contentView addSubview:[self switchRowForFeature:runtimeItems[0] y:10]];
    }
    if (runtimeItems.count > 1) {
        [secRole.contentView addSubview:[self adSpeedRowForFeature:runtimeItems[1] y:80]];
    }
    if (runtimeItems.count > 2) {
        [secRole.contentView addSubview:[self switchRowForFeature:runtimeItems[2] y:200]];
    }

    secRole.onToggle = ^(BOOL expanded){
        (void)expanded;
        [UIView animateWithDuration:0.25 animations:^{
            [weakSelf relayoutSections];
        }];
    };
    CGFloat hRole = [secRole layoutAndGetHeight];
    secRole.frame = CGRectMake(15, y, sectionW, hRole);
    y += hRole + 15;

    self.scroll.contentSize = CGSizeMake(width, y);
}

#pragma mark - 广告加速开关事件

- (void)adSwitchChanged:(UISwitch *)sw {
    UIView *box = sw.superview;
    UISlider *slider = [box viewWithTag:500];
    slider.enabled = sw.isOn;
    (void)ZONDispatchMigratedToggleForLegacyTag(sw.tag, sw.isOn);
}

#pragma mark - 广告加速滑条事件

- (void)adSliderChanged:(UISlider *)slider {
    UIView *box = slider.superview;
    UILabel *valueLab = [box viewWithTag:600];
    valueLab.text = [NSString stringWithFormat:@"%.0f", slider.value];
    [[NSUserDefaults standardUserDefaults] setFloat:slider.value forKey:kADSpeedKey];
    NSLog(@"广告倍速设置：%.0f", slider.value);
}

#pragma mark - 广告加速组合行（开关 + 滑条）

- (UIView *)adSpeedRowForFeature:(NSDictionary<NSString *, id> *)feature y:(CGFloat)y {
    CGFloat w = self.panel.bounds.size.width - 30;

    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(15, y, w, 110)];
    box.backgroundColor = UIColor.whiteColor;
    box.layer.cornerRadius = 18;

    UILabel *titleLab = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, 55)];
    titleLab.text = feature[ZONFeatureTitleKey];
    titleLab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [box addSubview:titleLab];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.tag = [feature[ZONFeatureLegacyTagKey] integerValue];

    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:kAADDEnableKey];
    sw.on = enabled;
    sw.center = CGPointMake(w - 50, 27);
    [sw addTarget:self action:@selector(adSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [box addSubview:sw];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(15, 65, w - 110, 30)];
    slider.minimumValue = 1;
    slider.maximumValue = 100;

    float savedValue = [[NSUserDefaults standardUserDefaults] floatForKey:kADSpeedKey];
    if (savedValue <= 0) savedValue = 50;
    slider.value = savedValue;
    slider.enabled = enabled;
    [slider addTarget:self action:@selector(adSliderChanged:) forControlEvents:UIControlEventValueChanged];
    slider.tag = 500;
    [box addSubview:slider];

    UILabel *valueLab = [[UILabel alloc] initWithFrame:CGRectMake(w - 80, 55, 70, 50)];
    valueLab.textAlignment = NSTextAlignmentCenter;
    valueLab.font = [UIFont systemFontOfSize:13];
    valueLab.textColor = UIColor.grayColor;
    valueLab.text = [NSString stringWithFormat:@"%.0f", slider.value];
    valueLab.tag = 600;
    [box addSubview:valueLab];

    return box;
}

#pragma mark - 数据功能按钮

- (void)addGridButtonsForFeatures:(NSArray<NSDictionary<NSString *, id> *> *)features
                        toSection:(UIView *)contentView
                                y:(CGFloat)y {
    CGFloat contentW = contentView.bounds.size.width;
    CGFloat leftMargin = 15;
    CGFloat spacingX = 15;
    CGFloat spacingY = 15;
    int colCount = 2;
    CGFloat btnW = (contentW - leftMargin * 2 - spacingX) / colCount;
    CGFloat btnH = 70;

    NSArray<UIColor *> *colors = @[
        UIColor.systemPurpleColor,
        UIColor.systemOrangeColor,
        UIColor.systemBlueColor,
        UIColor.systemPinkColor
    ];

    for (NSInteger i = 0; i < features.count; i++) {
        NSDictionary<NSString *, id> *feature = features[i];
        int row = (int)i / 2;
        int col = (int)i % 2;
        CGFloat x = leftMargin + col * (btnW + spacingX);
        CGFloat yy = y + row * (btnH + spacingY);

        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x, yy, btnW, btnH)];
        btn.backgroundColor = colors[(NSUInteger)i % colors.count];
        btn.layer.cornerRadius = 18;
        btn.tag = [feature[ZONFeatureLegacyTagKey] integerValue];
        [btn setTitle:feature[ZONFeatureTitleKey] forState:UIControlStateNormal];
        [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [btn addTarget:self action:@selector(gridButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:btn];
    }
}

#pragma mark - 功能入口

- (void)cardButtonTap:(UIButton *)sender {
    (void)ZONDispatchMigratedActionForLegacyTag(sender.tag, self);
}

- (void)gridButtonTap:(UIButton *)sender {
    (void)ZONDispatchMigratedActionForLegacyTag(sender.tag, self);
}

- (void)switchChanged:(UISwitch *)sw {
    (void)ZONDispatchMigratedToggleForLegacyTag(sw.tag, sw.isOn);
}

#pragma mark - 同步设置到 ImgTool

- (void)syncSettingsToRuntime {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    [ImgTool share].NeiGou = [ud boolForKey:kNNGGEnableKey];
    [ImgTool share].ADSpeed = [ud boolForKey:kAADDEnableKey];

    NSInteger speed = [ud integerForKey:kADSpeedKey];
    if (speed <= 0) speed = 1;
    [ImgTool share].ADBiansu = speed;
}

#pragma mark - 弹出动画

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

#pragma mark - 横竖屏旋转适配

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    CGFloat screenW = self.view.bounds.size.width;
    CGFloat screenH = self.view.bounds.size.height;
    CGFloat panelHeight = screenH * 0.85;

    self.panel.frame = CGRectMake(20,
                                  screenH - panelHeight - 20,
                                  screenW - 40,
                                  panelHeight);

    self.scroll.frame = self.panel.bounds;
    [self relayoutSections];
}

#pragma mark - 关闭弹窗

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

#pragma mark - 点击外部关闭（面板内部不关闭）

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
    (void)gestureRecognizer;
    CGPoint point = [touch locationInView:self.view];
    if (CGRectContainsPoint(self.panel.frame, point)) {
        return NO;
    }
    return YES;
}

- (UIView *)switchRowForFeature:(NSDictionary<NSString *, id> *)feature y:(CGFloat)y {
    CGFloat w = self.panel.bounds.size.width - 30;
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(15, y, w, 60)];
    row.backgroundColor = UIColor.whiteColor;
    row.layer.cornerRadius = 18;

    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 220, 60)];
    lab.text = feature[ZONFeatureTitleKey];
    lab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [row addSubview:lab];

    NSInteger tag = [feature[ZONFeatureLegacyTagKey] integerValue];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.tag = tag;

    NSString *identifier = feature[ZONFeatureIdentifierKey];
    if ([identifier isEqualToString:@"runtime.iap-noads"]) {
        sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:kNNGGEnableKey];
    }
    else if ([identifier isEqualToString:@"runtime.ad-speed"]) {
        sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:kAADDEnableKey];
    }

    sw.center = CGPointMake(w - 50, 30);
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];
    return row;
}

@end
