#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZONBackupStage) {
    ZONBackupStagePreparing = 0,
    ZONBackupStageScanning,
    ZONBackupStageCopyingDocuments,
    ZONBackupStageCopyingLibrary,
    ZONBackupStageArchiving,
    ZONBackupStageCompleted,
};

typedef void (^ZONBackupLargeItemDecisionReply)(BOOL skip);
typedef void (^ZONBackupLargeItemDecisionHandler)(NSString *relativePath,
                                                   unsigned long long size,
                                                   ZONBackupLargeItemDecisionReply reply);
typedef void (^ZONBackupProgressHandler)(ZONBackupStage stage,
                                         NSString * _Nullable detail,
                                         double progress);
typedef void (^ZONBackupCompletionHandler)(NSURL * _Nullable archiveURL,
                                           NSError * _Nullable error);

/// Pure backup execution service. It owns filesystem scanning/copying, staging, policy application
/// and ZIP creation, but does not present UIKit UI or share sheets.
@interface ZONBackupService : NSObject

+ (void)createBackupNamed:(NSString *)name
        largeItemDecision:(nullable ZONBackupLargeItemDecisionHandler)largeItemDecision
                 progress:(nullable ZONBackupProgressHandler)progress
               completion:(ZONBackupCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
