#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZONRemoteRestoreCoordinator : NSObject

+ (instancetype)sharedCoordinator;
- (void)startArchiveDownloadWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
