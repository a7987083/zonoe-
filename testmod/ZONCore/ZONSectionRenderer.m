#import "ZONSectionRenderer.h"
#import "ZONFeatureRegistry.h"
#import "ZONFeatureRenderer.h"
#import "../菜单/FoldSectionView.h"

NSArray<FoldSectionView *> *ZONRenderRegisteredSections(UIScrollView *scrollView,
                                                         CGFloat panelWidth,
                                                         id target,
                                                         SEL cardAction,
                                                         SEL gridAction,
                                                         SEL switchAction,
                                                         SEL adSwitchAction,
                                                         SEL adSliderAction,
                                                         ZONSectionRelayoutBlock relayout)
{
    NSMutableArray<FoldSectionView *> *renderedSections = [NSMutableArray array];
    CGFloat y = 0;
    CGFloat sectionW = panelWidth - 30;

    for (NSDictionary<NSString *, id> *sectionMeta in ZONBuiltInSectionMetadata()) {
        NSString *sectionTitle = sectionMeta[ZONSectionTitleKey];
        NSString *detail = sectionMeta[ZONSectionDetailKey];
        NSString *stateKey = sectionMeta[ZONSectionStateKey];
        NSString *renderer = sectionMeta[ZONSectionRendererKey];
        NSArray<NSDictionary<NSString *, id> *> *features = ZONFeatureMetadataForSection(sectionTitle);

        FoldSectionView *section = [[FoldSectionView alloc] initWithTitle:sectionTitle
                                                                   detail:detail
                                                                   status:[NSString stringWithFormat:@"%lu项", (unsigned long)features.count]];
        section.stateKey = stateKey;
        section.frame = CGRectMake(15, y, sectionW, 70);
        [scrollView addSubview:section];
        [renderedSections addObject:section];

        if ([renderer isEqualToString:@"cards"]) {
            ZONRenderCardFeatures(features, section.contentView, sectionW, target, cardAction);
        } else if ([renderer isEqualToString:@"grid"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ZONRenderGridFeatures(features, section.contentView, 10, target, gridAction);
                if (relayout) relayout();
            });
        } else if ([renderer isEqualToString:@"runtime"]) {
            ZONRenderRuntimeFeatures(features,
                                     section.contentView,
                                     panelWidth,
                                     target,
                                     switchAction,
                                     adSwitchAction,
                                     adSliderAction);
        }

        section.onToggle = ^(BOOL expanded){
            (void)expanded;
            [UIView animateWithDuration:0.25 animations:^{
                if (relayout) relayout();
            }];
        };

        CGFloat h = [section layoutAndGetHeight];
        section.frame = CGRectMake(15, y, sectionW, h);
        y += h + 15;
    }

    scrollView.contentSize = CGSizeMake(panelWidth, y);
    return [renderedSections copy];
}
