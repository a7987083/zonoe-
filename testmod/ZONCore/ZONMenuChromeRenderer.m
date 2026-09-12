#import "ZONMenuChromeRenderer.h"
#import "../菜单/FoldSectionView.h"

CGFloat ZONRenderMenuHeader(UIView *panel, UIScrollView *scroll)
{
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

    CGFloat width = panel.bounds.size.width;
    CGFloat left = 20;
    CGFloat top = 10;
    CGFloat maxW = width - 40;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.text = [NSString stringWithFormat:@"zonoe源++ %@ 解锁码到期：%@", yymc, jsm];
    title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    title.textColor = UIColor.blackColor;
    title.numberOfLines = 0;
    [panel addSubview:title];
    CGSize s1 = [title sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    title.frame = CGRectMake(left, top, maxW, s1.height);
    CGFloat curY = top + s1.height + 6;

    UILabel *line2 = [[UILabel alloc] initWithFrame:CGRectZero];
    line2.text = [NSString stringWithFormat:@"当前版本：%@", appVersion];
    line2.font = [UIFont systemFontOfSize:14];
    line2.textColor = UIColor.grayColor;
    [panel addSubview:line2];
    CGSize s2 = [line2 sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    line2.frame = CGRectMake(left, curY, maxW, s2.height);
    curY += s2.height + 2;

    UILabel *line3 = [[UILabel alloc] initWithFrame:CGRectZero];
    line3.text = [NSString stringWithFormat:@"App Store版本：%@", fwqbbh];
    line3.font = [UIFont systemFontOfSize:14];
    line3.textColor = UIColor.grayColor;
    [panel addSubview:line3];
    CGSize s3 = [line3 sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    line3.frame = CGRectMake(left, curY, maxW, s3.height);
    curY += s3.height + 12;

    scroll.frame = CGRectMake(0, curY, width, panel.bounds.size.height - curY);
    [panel addSubview:scroll];
    return curY;
}

void ZONRelayoutMenuSections(UIView *panel,
                             UIScrollView *scroll,
                             NSArray<FoldSectionView *> *sections)
{
    CGFloat sectionW = panel.bounds.size.width - 30;
    CGFloat y = 110;
    for (FoldSectionView *sec in sections) {
        CGFloat h = [sec layoutAndGetHeight];
        sec.frame = CGRectMake(15, y, sectionW, h);
        y += h + 15;
    }
    scroll.contentSize = CGSizeMake(panel.bounds.size.width, y + 20);
}
