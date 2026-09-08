#import "PopupMenuVC.h"
#import "PubgLoad.h"
#import "WX_NongShiFu123.h"
#import "YYYPicker.h"
#import "daochucd.h"
#import "FoldSectionView.h"
#import "ImgTool.h"
#import "SandboxBrowserVC.h"
#import "SVProgressHUD.h"

@interface PopupMenuVC () <UIGestureRecognizerDelegate>

@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) NSMutableArray<FoldSectionView *> *sections;
@property(nonatomic, assign) BOOL didBuildUI;

/* 数据源 */
@property(nonatomic,strong) NSArray *cardItems;

@end
#pragma mark - UserDefaults Keys（统一管理）

static NSString * const kNNGGKey        = @"NNGG";          // 内购 int
static NSString * const kNNGGEnableKey = @"NNGGNNGG";      // 内购 bool

static NSString * const kAADDKey        = @"AADD";          // 广告加速 int
static NSString * const kAADDEnableKey = @"AADDAADD";      // 广告加速 bool
static NSString * const kADSpeedKey    = @"AADDssppeedd";  // 广告倍速


@implementation PopupMenuVC

#pragma mark - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];

    // 半透明背景
    self.view.backgroundColor =
    [[UIColor blackColor] colorWithAlphaComponent:0.35];

    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];

    tap.delegate = self;               // ⭐关键：让我们能判断点击区域
    tap.cancelsTouchesInView = NO;     // ⭐按钮不会被抢走点击

    [self.view addGestureRecognizer:tap];


    // 卡片数据源（以后你可以随便加）
    self.cardItems = @[
        @{@"title":@"远程下载", @"btn":@"打开", @"tag":@(1)},
        @{@"title":@"VIP云存档", @"btn":@"打开", @"tag":@(2)},
        @{@"title":@"浏览本地文件", @"btn":@"打开", @"tag":@(3)}
    ];
//    你后续怎么扩展？
//    加一行卡片只需要：
//    self.cardItems = @[
//        @{@"title":@"打开绘图", @"btn":@"打开", @"tag":@(1)},
//        @{@"title":@"打开游戏", @"btn":@"打开", @"tag":@(2)},
//        @{@"title":@"漏洞设置", @"btn":@"设置", @"tag":@(3)},
//        @{@"title":@"存档管理", @"btn":@"进入", @"tag":@(4)}
//    ];

    
    // 创建面板
    [self setupPanel];
    [self buildUI];      // ⭐只调用一次

}

#pragma mark - 创建Panel

- (void)setupPanel {

    CGFloat screenW = self.view.bounds.size.width;
    CGFloat screenH = self.view.bounds.size.height;

    // 动态高度（横屏自动变矮）
    CGFloat panelHeight = screenH * 0.85;

    self.panel = [[UIView alloc] initWithFrame:CGRectMake(
        20,
        screenH,
        screenW - 40,
        panelHeight
    )];

    self.panel.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    self.panel.layer.cornerRadius = 25;
    self.panel.clipsToBounds = YES;

    [self.view addSubview:self.panel];

    // ScrollView
    self.scroll = [[UIScrollView alloc] initWithFrame:self.panel.bounds];
    self.scroll.showsVerticalScrollIndicator = NO;
    [self.panel addSubview:self.scroll];

   
}
#pragma mark - 折叠后重新排列所有 section
- (void)relayoutSections {
    CGFloat sectionW = self.panel.bounds.size.width - 30;

    // 1. 查找 line3（或者顶部文字的最后一个控件）
    // 如果 line3 不是成员变量，可以通过 tag 找，或者遍历 subviews
//    CGFloat startY = 10;
//    for (UIView *v in self.scroll.subviews) {
//        // 假设给 line3 设置了 tag = 999，或者根据类型判断
//        // 这里我们简单演示：累加到你顶部文字结束的那个位置
//        // 更好的做法是将 line3 设为属性 @property UILabel *line3;
//    }
    
    // 如果你不想改动太多，最简单的方法是直接硬编码或通过属性传入
    // 假设顶部三个 Label 加起来大概是 100 像素
    CGFloat y = 110; // 这里改为标题文字的总高度 + 间距

    for (FoldSectionView *sec in self.sections) {
        CGFloat h = [sec layoutAndGetHeight];
        sec.frame = CGRectMake(15, y, sectionW, h);
        y += h + 15;
    }

    self.scroll.contentSize = CGSizeMake(self.panel.bounds.size.width, y + 20);
}


#pragma mark - 构建UI
- (void)buildUI {
    if (self.didBuildUI) return; // ✅只创建一次
    self.didBuildUI = YES;

    // ======================
    // 读取信息
    // ======================
    NSString *jsm = [[NSUserDefaults standardUserDefaults] objectForKey:@"解锁码到期时间"];
    NSString *yjy = [[NSUserDefaults standardUserDefaults] objectForKey:@"到期时间"];
    NSString *fwqbbh = [[NSUserDefaults standardUserDefaults] objectForKey:@"服务器版本号"];
    NSString *yymc = [[NSUserDefaults standardUserDefaults] objectForKey:@"应用名称"];
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];

    if (!yymc) yymc = @"未知应用";
    if (!fwqbbh) fwqbbh = @"未知版本";
    if (!appVersion) appVersion = @"0.0.0";
    if (!jsm || jsm.length == 0) jsm = yjy; // 优先使用解锁码到期时间

    CGFloat width = self.panel.bounds.size.width;
    if (!self.sections) self.sections = [NSMutableArray array];
    [self.sections removeAllObjects];

    // ======================
    // 清空 scroll 子视图
    // ======================
    for (UIView *v in self.scroll.subviews) {
        [v removeFromSuperview];
    }
    self.scroll.showsVerticalScrollIndicator = YES; // 可以滚动

    CGFloat left = 20;
    CGFloat top = 10;
    CGFloat maxW = width - 40;

    // ======================
    // 固定标题部分（panel 上）
    // ======================
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

    // ======================
    // scroll frame 下移到标题底部
    // ======================
    CGFloat scrollTop = curY;
    self.scroll.frame = CGRectMake(0, scrollTop, width, self.panel.bounds.size.height - scrollTop);
    [self.panel addSubview:self.scroll];

    CGFloat y = 0; // scroll 内部坐标从 0 开始
    CGFloat sectionW = width - 30;
    CGFloat gap = 65;

    __weak typeof(self) weakSelf = self;

    // ======================
    // 基础功能部分
    // ======================
    FoldSectionView *secBase = [[FoldSectionView alloc] initWithTitle:@"基础功能"
                                                              detail:@"远程下载 / 云存档"
                                                              status:[NSString stringWithFormat:@"%lu项", (unsigned long)self.cardItems.count]];
    secBase.stateKey = @"fold_base";
    secBase.frame = CGRectMake(15, y, sectionW, 70);
    [self.scroll addSubview:secBase];
    [self.sections addObject:secBase];

    for (int i = 0; i < self.cardItems.count; i++) {
        NSDictionary *item = self.cardItems[i];
        NSString *cardTitle = item[@"title"];
        NSString *btnTitle  = item[@"btn"];
        NSInteger tag       = [item[@"tag"] integerValue];

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
        [btn setTitle:btnTitle forState:UIControlStateNormal];
        [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        btn.tag = tag;
        [btn addTarget:self action:@selector(cardButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:btn];
    }

    secBase.onToggle = ^(BOOL expanded){
        [UIView animateWithDuration:0.25 animations:^{
            [weakSelf relayoutSections];
        }];
    };
    CGFloat hBase = [secBase layoutAndGetHeight];
    secBase.frame = CGRectMake(15, y, sectionW, hBase);
    y += hBase + 15;

    // ======================
    // 数据功能部分
    // ======================
    FoldSectionView *secDraw = [[FoldSectionView alloc] initWithTitle:@"数据功能"
                                                              detail:@"备份存档 /恢复存档 / 清理配置和授权"
                                                              status:@"4项"];
    secDraw.stateKey = @"fold_draw";
    secDraw.frame = CGRectMake(15, y, sectionW, 70);
    [self.scroll addSubview:secDraw];
    [self.sections addObject:secDraw];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self addGridButtonsToSection:secDraw.contentView y:10];
        [self relayoutSections];
    });

    secDraw.onToggle = ^(BOOL expanded){
        [UIView animateWithDuration:0.25 animations:^{
            [weakSelf relayoutSections];
        }];
    };
    CGFloat hDraw = [secDraw layoutAndGetHeight];
    secDraw.frame = CGRectMake(15, y, sectionW, hDraw);
    y += hDraw + 15;

    // ======================
    // 其他功能部分
    // ======================
    FoldSectionView *secRole = [[FoldSectionView alloc] initWithTitle:@"其他功能"
                                                              detail:@"1 / 2 / 3"
                                                              status:@"3项"];
    secRole.stateKey = @"fold_role";
    secRole.frame = CGRectMake(15, y, sectionW, 70);
    [self.scroll addSubview:secRole];
    [self.sections addObject:secRole];

    // 开关行
    [secRole.contentView addSubview:[self switchRow:@"内购破解+ iGameGod去广告" tag:201 y:10]];
    [secRole.contentView addSubview:[self adSpeedRowY:80]];
    [secRole.contentView addSubview:[self switchRow:@"暂无" tag:203 y:200]];

    secRole.onToggle = ^(BOOL expanded){
        [UIView animateWithDuration:0.25 animations:^{
            [weakSelf relayoutSections];
        }];
    };
    CGFloat hRole = [secRole layoutAndGetHeight];
    secRole.frame = CGRectMake(15, y, sectionW, hRole);
    y += hRole + 15;

    // ======================
    // 更新 scroll 内容高度
    // ======================
    self.scroll.contentSize = CGSizeMake(width, y);
}


- (void)sliderChanged:(UISlider *)slider {

    UIView *row = slider.superview;
    UILabel *valueLab = [row viewWithTag:600];

    valueLab.text = [NSString stringWithFormat:@"%.0f", slider.value];

    [[NSUserDefaults standardUserDefaults]
     setFloat:slider.value forKey:@"AADDssppeedd"];
}
- (UIView *)sliderRow:(NSString *)title
                  key:(NSString *)saveKey
                   y:(CGFloat)y {

    CGFloat w = self.panel.bounds.size.width - 60;

    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 60)];

    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 100, 60)];
    lab.text = title;
    lab.font = [UIFont systemFontOfSize:14];
    [row addSubview:lab];

    UISlider *slider =
    [[UISlider alloc] initWithFrame:CGRectMake(110, 15, w - 200, 30)];

    slider.minimumValue = 1;
    slider.maximumValue = 100;
    slider.value = [[NSUserDefaults standardUserDefaults] floatForKey:saveKey];

    [slider addTarget:self action:@selector(sliderChanged:)
     forControlEvents:UIControlEventValueChanged];

    slider.tag = 500; // 用tag识别
    [row addSubview:slider];

    UILabel *valueLab =
    [[UILabel alloc] initWithFrame:CGRectMake(w - 80, 0, 70, 60)];

    valueLab.textAlignment = NSTextAlignmentCenter;
    valueLab.font = [UIFont systemFontOfSize:12];
    valueLab.textColor = UIColor.grayColor;
    valueLab.text = [NSString stringWithFormat:@"%.0f", slider.value];
    valueLab.tag = 600;

    [row addSubview:valueLab];

    return row;
}
#pragma mark - 广告加速开关事件
- (void)adSwitchChanged:(UISwitch *)sw {

    UIView *box = sw.superview;
    UISlider *slider = [box viewWithTag:500];

    slider.enabled = sw.isOn;

    [self saveSwitch:sw
              intKey:kAADDKey
             boolKey:kAADDEnableKey
          applyBlock:^(BOOL on) {
        [ImgTool share].ADSpeed = on;
    }];
}

//- (void)adSwitchChanged:(UISwitch *)sw {
//
//    UIView *box = sw.superview;
//
//    UISlider *slider = [box viewWithTag:500];
//
//    slider.enabled = sw.isOn;
//
//    [[NSUserDefaults standardUserDefaults]
//     setBool:sw.isOn forKey:@"AADDAADD"];
//
//    [ImgTool share].ADSpeed = sw.isOn;
//}
#pragma mark - 广告加速滑条事件

- (void)adSliderChanged:(UISlider *)slider {

    UIView *box = slider.superview;
    UILabel *valueLab = [box viewWithTag:600];

    valueLab.text = [NSString stringWithFormat:@"%.0f", slider.value];

    [[NSUserDefaults standardUserDefaults]
     setFloat:slider.value forKey:@"AADDssppeedd"];

    NSLog(@"广告倍速设置：%.0f", slider.value);
}

#pragma mark - 广告加速组合行（开关 + 滑条）

- (UIView *)adSpeedRowY:(CGFloat)y {

    CGFloat w = self.panel.bounds.size.width - 30;

    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(15, y, w, 110)];
    box.backgroundColor = UIColor.whiteColor;
    box.layer.cornerRadius = 18;

    // 标题
    UILabel *titleLab = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, 55)];
    titleLab.text = @"广告加速";
    titleLab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [box addSubview:titleLab];

    // 开关
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.tag = 202;

    BOOL enabled =
    [[NSUserDefaults standardUserDefaults] boolForKey:@"AADDAADD"];
    sw.on = enabled;

    sw.center = CGPointMake(w - 50, 27);
    [sw addTarget:self action:@selector(adSwitchChanged:)
  forControlEvents:UIControlEventValueChanged];

    [box addSubview:sw];

    // 滑条
    UISlider *slider =
    [[UISlider alloc] initWithFrame:CGRectMake(15, 65, w - 110, 30)];

    slider.minimumValue = 1;
    slider.maximumValue = 100;

    float savedValue =
    [[NSUserDefaults standardUserDefaults] floatForKey:@"AADDssppeedd"];

    if (savedValue <= 0) savedValue = 50;
    slider.value = savedValue;

    slider.enabled = enabled; // ✅开关控制滑条

    [slider addTarget:self action:@selector(adSliderChanged:)
     forControlEvents:UIControlEventValueChanged];

    slider.tag = 500;
    [box addSubview:slider];

    // 数值显示
    UILabel *valueLab =
    [[UILabel alloc] initWithFrame:CGRectMake(w - 80, 55, 70, 50)];

    valueLab.textAlignment = NSTextAlignmentCenter;
    valueLab.font = [UIFont systemFontOfSize:13];
    valueLab.textColor = UIColor.grayColor;
    valueLab.text = [NSString stringWithFormat:@"%.0f", slider.value];
    valueLab.tag = 600;

    [box addSubview:valueLab];

    return box;
}

- (void)addGridButtonsToSection:(UIView *)contentView y:(CGFloat)y {

    // ⭐关键：必须用 contentView 的宽度
    CGFloat contentW = contentView.bounds.size.width;

    CGFloat leftMargin = 15;
    CGFloat spacingX   = 15;
    CGFloat spacingY   = 15;

    int colCount = 2;

    // ⭐按钮宽度自动计算（不会出界）
    CGFloat btnW = (contentW - leftMargin * 2 - spacingX) / colCount;
    CGFloat btnH = 70;

    NSArray *titles = @[@"备份存档", @"恢复存档",
                        @"清除游戏数据", @"清除授权记录"];

    NSArray *colors = @[
        UIColor.systemPurpleColor,
        UIColor.systemOrangeColor,
        UIColor.systemBlueColor,
        UIColor.systemPinkColor
    ];

    for (int i = 0; i < titles.count; i++) {

        int row = i / 2;
        int col = i % 2;

        CGFloat x = leftMargin + col * (btnW + spacingX);
        CGFloat yy = y + row * (btnH + spacingY);

        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x, yy, btnW, btnH)];

        btn.backgroundColor = colors[i];
        btn.layer.cornerRadius = 18;
        btn.tag = 100 + i;

        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];

        [btn addTarget:self action:@selector(gridButtonTap:)
      forControlEvents:UIControlEventTouchUpInside];

        [contentView addSubview:btn];
    }
}







#pragma mark - 卡片按钮点击事件（空）

- (void)cardButtonTap:(UIButton *)sender {

    // ⚠️你以后在这里补功能即可
    // sender.tag 对应 cardItems 里的 tag

    /*
    if(sender.tag == 1){
         打开绘图
    }
    */
    
    if (sender.tag == 1) {
        [[PubgLoad alloc] yuanchengdwon];
        // TODO：绘图功能

    } else if (sender.tag == 2) {

        // ✅打开游戏功能写这里
//             [self openGame];

        // ✅打开游戏功能写这里
        [[PubgLoad alloc] checkCloudSaveStatus];

    } else if (sender.tag == 3) {
        SandboxBrowserVC *vc = [[SandboxBrowserVC alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];

        // iOS 13+ 半屏模式
        if (@available(iOS 13.0, *)) {
            nav.modalPresentationStyle = UIModalPresentationPageSheet; // 半屏
        } else {
            nav.modalPresentationStyle = UIModalPresentationFullScreen; // 兼容旧系统
        }

        [self presentViewController:nav animated:YES completion:nil];


       

//        [[YYYPicker alloc] addBtnAction];

        // TODO：设置功能

    }

}
//- (void)openGame {
//
////    NSLog(@"这里执行打开游戏逻辑");
//
//    // ⚠️你以后补你自己的代码，比如：
//    // 启动某个界面
//    // 执行外挂功能
//    // 弹出新的控制器
//}

 


#pragma mark - 彩色按钮点击事件（空）

- (void)gridButtonTap:(UIButton *)sender {
   
    // ⚠️你以后补功能即可
    // sender.tag = 100,101,102,103
//    if(sender.tag == 102){
//          // 自瞄功能
//      }
    if (sender.tag == 100) {
        [[daochucd alloc]backupasd];
        // TODO：绘图功能

    } else if (sender.tag == 101) {

        // ✅打开游戏功能写这里
//             [self openGame];
        [[YYYPicker alloc] addBtnAction];

    } else if (sender.tag == 102) {
        [self showConfirmAlert:@"清除游戏数据"
                         message:@"此操作会清除本地游戏数据，且不可恢复。\n确定要继续吗？"
                      onConfirm:^{
            [SVProgressHUD showWithStatus:@"处理中..."];
               [self qcshuju];

           }];

    }else if (sender.tag == 103) {
        [self showConfirmAlert:@"清除授权记录"
                         message:@"此操作会删除授权信息，删除后需要重新授权。\n确定继续吗？"
                      onConfirm:^{

               [[WX_NongShiFu123 alloc] deletekm];

               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                              dispatch_get_main_queue(), ^{
                   exit(0);
               });

           }];

            }
    

}
#pragma mark - 二次确认弹窗（防误触）

- (void)showConfirmAlert:(NSString *)title
                 message:(NSString *)message
              onConfirm:(void (^)(void))confirmBlock {

    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];

    // 取消按钮
    UIAlertAction *cancel =
    [UIAlertAction actionWithTitle:@"取消"
                             style:UIAlertActionStyleCancel
                           handler:nil];

    // 确认按钮（红色危险）
    UIAlertAction *confirm =
    [UIAlertAction actionWithTitle:@"确定"
                             style:UIAlertActionStyleDestructive
                           handler:^(UIAlertAction * _Nonnull action) {

        if (confirmBlock) {
            confirmBlock();
        }

    }];

    [alert addAction:cancel];
    [alert addAction:confirm];

    // 弹出
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)qcshuju {

   

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSFileManager *Manager = [NSFileManager defaultManager];

        NSString *dataFile = [NSHomeDirectory() stringByAppendingString:@"/tmp/"];
        NSString *imageDir = [NSString stringWithFormat:@"%@",dataFile];
        NSLog(@"✈️删除tmp, %@", imageDir);
        [Manager removeItemAtPath:imageDir error:nil];
        
        NSString *dataFilez = [NSHomeDirectory() stringByAppendingString:@"/Documents/"];
        NSString *imageDirz = [NSString stringWithFormat:@"%@",dataFilez];
        NSLog(@"✈️删除tmp, %@", imageDirz);
        [Manager removeItemAtPath:imageDirz error:nil];
        
        NSString *dataFilex = [NSHomeDirectory() stringByAppendingString:@"/Library/"];
        NSString *imageDirx = [NSString stringWithFormat:@"%@",dataFilex];
        NSLog(@"✈️删除tmp, %@", imageDirx);
        [Manager removeItemAtPath:imageDirx error:nil];
        //清空plist
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
        
        
        NSString *DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:DocumentsPath];
        
        for (NSString *fileName in enumerator) {
            
            [[NSFileManager defaultManager] removeItemAtPath:[DocumentsPath stringByAppendingPathComponent:fileName] error:nil];
            
        }
        
        NSString *LibraryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
        
        NSDirectoryEnumerator *enumerator1 = [[NSFileManager defaultManager] enumeratorAtPath:LibraryPath];
        
        for (NSString *fileName in enumerator1) {
            
            [[NSFileManager defaultManager] removeItemAtPath:[LibraryPath stringByAppendingPathComponent:fileName] error:nil];
        }
        
       

        
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

//- (void)switchChanged:(UISwitch *)sw {
//
//    if (sw.tag == 201) {
//           [[NSUserDefaults standardUserDefaults]
//            setBool:sw.isOn forKey:@"NNGGNNGG"];
//
//           [ImgTool share].NeiGou = sw.isOn;
//       }
//
//       if (sw.tag == 202) {
//           [[NSUserDefaults standardUserDefaults]
//            setBool:sw.isOn forKey:@"AADDAADD"];
//
//           [ImgTool share].ADSpeed = sw.isOn;
//       }
//
//    if(sw.tag == 203){
//        NSLog(@"人物血量");
//    }
//}

- (void)switchChanged:(UISwitch *)sw {

    if (sw.tag == 201) { // 内购
        [self saveSwitch:sw
                  intKey:kNNGGKey
                 boolKey:kNNGGEnableKey
              applyBlock:^(BOOL on) {
            [ImgTool share].NeiGou = on;
        }];
    }

    else if (sw.tag == 202) { // 广告加速
        [self saveSwitch:sw
                  intKey:kAADDKey
                 boolKey:kAADDEnableKey
              applyBlock:^(BOOL on) {
            [ImgTool share].ADSpeed = on;
        }];
    }

    else if (sw.tag == 203) {
        NSLog(@"人物血量");
    }
}
#pragma mark - 同步设置到 ImgTool

- (void)syncSettingsToRuntime {

    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;

    [ImgTool share].NeiGou   = [ud boolForKey:kNNGGEnableKey];
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

    // ✅只更新 panel 大小
    self.panel.frame = CGRectMake(
        20,
        screenH - panelHeight - 20,
        screenW - 40,
        panelHeight
    );

    self.scroll.frame = self.panel.bounds;

    // ✅重新排列 section（不重建）
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

        [self dismissViewControllerAnimated:NO completion:nil];

    }];
}
#pragma mark - 点击外部关闭（面板内部不关闭）

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {

    CGPoint point = [touch locationInView:self.view];

    // 如果点击在 panel 内部 → 不关闭
    if (CGRectContainsPoint(self.panel.frame, point)) {
        return NO;
    }

    // 点击外部空白 → 允许 close
    return YES;
}
//红色大按钮
- (UIButton *)bigRedButton:(NSString *)title tag:(NSInteger)tag y:(CGFloat)y {

    CGFloat w = self.panel.bounds.size.width - 30;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(15, y, w, 55);
    btn.layer.cornerRadius = 25;
    btn.backgroundColor = UIColor.systemRedColor;

    btn.tag = tag;

    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];

    [btn addTarget:self action:@selector(redButtonTap:) forControlEvents:UIControlEventTouchUpInside];

    return btn;
}

- (UIView *)switchRow:(NSString *)title tag:(NSInteger)tag y:(CGFloat)y {

    CGFloat w = self.panel.bounds.size.width - 30;

    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(15, y, w, 60)];
    row.backgroundColor = UIColor.whiteColor;
    row.layer.cornerRadius = 18;

    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 220, 60)];
    lab.text = title;
    lab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [row addSubview:lab];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.tag = tag;

    // ✅从保存状态读取
    if (tag == 201) {
        sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"NNGGNNGG"];
    }
    else if (tag == 202) {
        sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"AADDAADD"];
    }

    sw.center = CGPointMake(w - 50, 30);

    [sw addTarget:self action:@selector(switchChanged:)
         forControlEvents:UIControlEventValueChanged];

    [row addSubview:sw];

    return row;
}
#pragma mark - 通用 Switch 存储

- (void)saveSwitch:(UISwitch *)sw
            intKey:(NSString *)intKey
           boolKey:(NSString *)boolKey
        applyBlock:(void (^)(BOOL on))apply {

    BOOL on = sw.isOn;
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;

    if (intKey)  [ud setInteger:on forKey:intKey];
    if (boolKey) [ud setBool:on forKey:boolKey];

    [ud synchronize]; // ✅立即写入，保证 Hook 读取到最新值

    if (apply) {
        apply(on); // ✅立即生效
    }
}


@end
