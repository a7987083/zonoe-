#import "ZONFeatureRenderer.h"
#import "ZONFeatureRegistry.h"

static NSString * const ZONRendererNNGGEnableKey = @"NNGGNNGG";
static NSString * const ZONRendererAADDEnableKey = @"AADDAADD";
static NSString * const ZONRendererADSpeedKey = @"AADDssppeedd";

void ZONRenderCardFeatures(NSArray<NSDictionary<NSString *, id> *> *features,
                           UIView *contentView,
                           CGFloat sectionWidth,
                           id target,
                           SEL action)
{
    CGFloat gap = 65;
    for (NSInteger i = 0; i < features.count; i++) {
        NSDictionary<NSString *, id> *feature = features[i];
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(15, 10 + i * gap, sectionWidth - 30, 55)];
        card.backgroundColor = UIColor.whiteColor;
        card.layer.cornerRadius = 16;
        [contentView addSubview:card];

        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 160, 55)];
        lab.text = feature[ZONFeatureTitleKey];
        lab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        [card addSubview:lab];

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(card.bounds.size.width - 80, 12, 65, 32);
        btn.backgroundColor = UIColor.systemBlueColor;
        btn.layer.cornerRadius = 16;
        [btn setTitle:@"打开" forState:UIControlStateNormal];
        [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        btn.tag = [feature[ZONFeatureLegacyTagKey] integerValue];
        [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:btn];
    }
}

void ZONRenderGridFeatures(NSArray<NSDictionary<NSString *, id> *> *features,
                           UIView *contentView,
                           CGFloat y,
                           id target,
                           SEL action)
{
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
        [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:btn];
    }
}

UIView *ZONRenderSwitchRow(NSDictionary<NSString *, id> *feature,
                           CGFloat y,
                           CGFloat panelWidth,
                           id target,
                           SEL action)
{
    CGFloat w = panelWidth - 30;
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
        sw.on = [NSUserDefaults.standardUserDefaults boolForKey:ZONRendererNNGGEnableKey];
    } else if ([identifier isEqualToString:@"runtime.ad-speed"]) {
        sw.on = [NSUserDefaults.standardUserDefaults boolForKey:ZONRendererAADDEnableKey];
    }
    sw.center = CGPointMake(w - 50, 30);
    [sw addTarget:target action:action forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];
    return row;
}

UIView *ZONRenderAdSpeedRow(NSDictionary<NSString *, id> *feature,
                            CGFloat y,
                            CGFloat panelWidth,
                            id target,
                            SEL switchAction,
                            SEL sliderAction)
{
    CGFloat w = panelWidth - 30;
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(15, y, w, 110)];
    box.backgroundColor = UIColor.whiteColor;
    box.layer.cornerRadius = 18;

    UILabel *titleLab = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, 55)];
    titleLab.text = feature[ZONFeatureTitleKey];
    titleLab.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [box addSubview:titleLab];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.tag = [feature[ZONFeatureLegacyTagKey] integerValue];
    BOOL enabled = [NSUserDefaults.standardUserDefaults boolForKey:ZONRendererAADDEnableKey];
    sw.on = enabled;
    sw.center = CGPointMake(w - 50, 27);
    [sw addTarget:target action:switchAction forControlEvents:UIControlEventValueChanged];
    [box addSubview:sw];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(15, 65, w - 110, 30)];
    slider.minimumValue = 1;
    slider.maximumValue = 100;
    float savedValue = [NSUserDefaults.standardUserDefaults floatForKey:ZONRendererADSpeedKey];
    if (savedValue <= 0) savedValue = 50;
    slider.value = savedValue;
    slider.enabled = enabled;
    [slider addTarget:target action:sliderAction forControlEvents:UIControlEventValueChanged];
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

void ZONRenderRuntimeFeatures(NSArray<NSDictionary<NSString *, id> *> *features,
                              UIView *contentView,
                              CGFloat panelWidth,
                              id target,
                              SEL switchAction,
                              SEL adSwitchAction,
                              SEL adSliderAction)
{
    for (NSDictionary<NSString *, id> *feature in features) {
        NSString *identifier = feature[ZONFeatureIdentifierKey];
        if ([identifier isEqualToString:@"runtime.iap-noads"]) {
            [contentView addSubview:ZONRenderSwitchRow(feature, 10, panelWidth, target, switchAction)];
        } else if ([identifier isEqualToString:@"runtime.ad-speed"]) {
            [contentView addSubview:ZONRenderAdSpeedRow(feature, 80, panelWidth, target, adSwitchAction, adSliderAction)];
        } else if ([identifier isEqualToString:@"runtime.placeholder-203"]) {
            [contentView addSubview:ZONRenderSwitchRow(feature, 200, panelWidth, target, switchAction)];
        }
    }
}
