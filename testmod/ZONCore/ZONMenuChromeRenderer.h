#ifndef ZONMenuChromeRenderer_h
#define ZONMenuChromeRenderer_h

#import <UIKit/UIKit.h>

@class FoldSectionView;

NS_ASSUME_NONNULL_BEGIN

CGFloat ZONRenderMenuHeader(UIView *panel, UIScrollView *scroll);
void ZONRelayoutMenuSections(UIView *panel,
                             UIScrollView *scroll,
                             NSArray<FoldSectionView *> *sections);

NS_ASSUME_NONNULL_END

#endif /* ZONMenuChromeRenderer_h */
