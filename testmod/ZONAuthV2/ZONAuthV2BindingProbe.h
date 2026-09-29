#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZONAuthV2BindingState) {
    ZONAuthV2BindingStateUnknown = 0,
    ZONAuthV2BindingStateNotBound = 1,
    ZONAuthV2BindingStateBound = 2,
};

typedef void (^ZONAuthV2BindingProbeCompletion)(ZONAuthV2BindingState state,
                                                 NSDictionary * _Nullable response,
                                                 NSError * _Nullable error);

@interface ZONAuthV2BindingProbe : NSObject

/// Compatibility query for the legacy /authorization endpoint.
/// Only structured binding evidence is authoritative; ambiguous HTML/text responses return Unknown.
+ (void)queryCard:(NSString *)card
             udid:(NSString *)udid
       completion:(ZONAuthV2BindingProbeCompletion)completion;

@end

NS_ASSUME_NONNULL_END
