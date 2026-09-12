#ifndef ZONFeatureRenderer_h
#define ZONFeatureRenderer_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

void ZONRenderCardFeatures(NSArray<NSDictionary<NSString *, id> *> *features,
                           UIView *contentView,
                           CGFloat sectionWidth,
                           id target,
                           SEL action);
void ZONRenderGridFeatures(NSArray<NSDictionary<NSString *, id> *> *features,
                           UIView *contentView,
                           CGFloat y,
                           id target,
                           SEL action);
UIView *ZONRenderSwitchRow(NSDictionary<NSString *, id> *feature,
                           CGFloat y,
                           CGFloat panelWidth,
                           id target,
                           SEL action);
UIView *ZONRenderAdSpeedRow(NSDictionary<NSString *, id> *feature,
                            CGFloat y,
                            CGFloat panelWidth,
                            id target,
                            SEL switchAction,
                            SEL sliderAction);
void ZONRenderRuntimeFeatures(NSArray<NSDictionary<NSString *, id> *> *features,
                              UIView *contentView,
                              CGFloat panelWidth,
                              id target,
                              SEL switchAction,
                              SEL adSwitchAction,
                              SEL adSliderAction);

NS_ASSUME_NONNULL_END

#endif /* ZONFeatureRenderer_h */
