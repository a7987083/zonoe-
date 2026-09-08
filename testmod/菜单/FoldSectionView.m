#import "FoldSectionView.h"

@interface FoldSectionView ()
@property(nonatomic,strong) UILabel *titleLab;
@property(nonatomic,strong) UILabel *detailLab;
@property(nonatomic,strong) UILabel *statusLab;
@property(nonatomic,strong) UIButton *arrowBtn;
 
@end

@implementation FoldSectionView

- (instancetype)initWithTitle:(NSString *)title
                       detail:(NSString *)detail
                       status:(NSString *)status {

    self = [super initWithFrame:CGRectZero];
    if(self){

        self.backgroundColor = UIColor.clearColor;
        self.expanded = YES;

        // 外层白卡
        self.layer.cornerRadius = 22;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85];

        // Header
        self.header = [[UIView alloc] initWithFrame:CGRectZero];
        self.header.backgroundColor = [UIColor colorWithWhite:1 alpha:0.55];
        [self addSubview:self.header];

        self.titleLab = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLab.text = title;
        self.titleLab.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        [self.header addSubview:self.titleLab];

        self.detailLab = [[UILabel alloc] initWithFrame:CGRectZero];
        self.detailLab.text = detail;
        self.detailLab.font = [UIFont systemFontOfSize:13];
        self.detailLab.textColor = UIColor.grayColor;
        [self.header addSubview:self.detailLab];

        self.statusLab = [[UILabel alloc] initWithFrame:CGRectZero];
        self.statusLab.text = status;
        self.statusLab.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        self.statusLab.textColor = UIColor.systemGreenColor;
        [self.header addSubview:self.statusLab];

        self.arrowBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.arrowBtn setTitle:@"⌃" forState:UIControlStateNormal];
        self.arrowBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        [self.header addSubview:self.arrowBtn];

        // 内容区
        self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
        self.contentView.backgroundColor = UIColor.clearColor;
        [self addSubview:self.contentView];

        // 点击Header折叠
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggle)];
        [self.header addGestureRecognizer:tap];
        [self.arrowBtn addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)toggle {

    self.expanded = !self.expanded;

    // ⭐保存状态
    if (self.stateKey.length > 0) {
        [[NSUserDefaults standardUserDefaults]
            setBool:self.expanded
            forKey:self.stateKey];
    }

    self.contentView.hidden = !self.expanded;

    self.arrowBtn.transform =
        self.expanded ? CGAffineTransformIdentity
                      : CGAffineTransformMakeRotation(M_PI);

    [self layoutAndGetHeight];

    if (self.onToggle) {
        self.onToggle(self.expanded);
    }
}



- (CGFloat)layoutAndGetHeight {

    CGFloat w = self.bounds.size.width;

    // header 高度
    CGFloat headerH = 70;
    self.header.frame = CGRectMake(0, 0, w, headerH);

    self.titleLab.frame  = CGRectMake(18, 12, w - 120, 26);
    self.detailLab.frame = CGRectMake(18, 40, w - 120, 20);

    self.statusLab.frame = CGRectMake(w - 100, 18, 70, 18);
    self.arrowBtn.frame  = CGRectMake(w - 40, 20, 30, 30);

    // content
    CGFloat contentY = headerH;
    CGFloat contentH = 0;

    if(self.expanded){
        // 让外部布局 contentView 的 subviews 后再调用一次也行
        // 这里先按 contentView 内最后一个控件底部来算高度
        CGFloat maxBottom = 0;
        for(UIView *v in self.contentView.subviews){
            CGFloat b = CGRectGetMaxY(v.frame);
            if(b > maxBottom) maxBottom = b;
        }
        contentH = maxBottom + 15;
        self.contentView.frame = CGRectMake(0, contentY, w, contentH);
    }else{
        self.contentView.frame = CGRectMake(0, contentY, w, 0);
    }

    return headerH + contentH;
}
- (void)setStateKey:(NSString *)stateKey {
    _stateKey = stateKey;

    // 如果之前存过状态，则恢复
    if (stateKey.length > 0 &&
        [[NSUserDefaults standardUserDefaults] objectForKey:stateKey] != nil) {

        self.expanded =
        [[NSUserDefaults standardUserDefaults] boolForKey:stateKey];
    }

    // 同步 UI
    self.contentView.hidden = !self.expanded;
    self.arrowBtn.transform =
        self.expanded ? CGAffineTransformIdentity
                      : CGAffineTransformMakeRotation(M_PI);
}

@end
