#ifndef ZONSectionRenderer_h
#define ZONSectionRenderer_h

#import <UIKit/UIKit.h>

@class FoldSectionView;

typedef void (^ZONSectionRelayoutBlock)(void);

NS_ASSUME_NONNULL_BEGIN

NSArray<FoldSectionView *> *ZONRenderRegisteredSections(UIScrollView *scrollView,
                                                         CGFloat panelWidth,
                                                         id target,
                                                         SEL cardAction,
                                                         SEL gridAction,
                                                         SEL switchAction,
                                                         SEL adSwitchAction,
                                                         SEL adSliderAction,
                                                         ZONSectionRelayoutBlock relayout);

NS_ASSUME_NONNULL_END

#endif /* ZONSectionRenderer_h */
