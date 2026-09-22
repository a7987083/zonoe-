#import "ZONRuntimeDirectoryService.h"

@implementation ZONRuntimeDirectoryService

+ (NSString *)temporaryDirectoryPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
}

+ (BOOL)ensureTemporaryDirectory
{
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *tmpPath = [self temporaryDirectoryPath];
    BOOL isDirectory = NO;

    if ([manager fileExistsAtPath:tmpPath isDirectory:&isDirectory]) {
        if (isDirectory) return YES;
        [manager removeItemAtPath:tmpPath error:nil];
    }

    NSError *error = nil;
    BOOL created = [manager createDirectoryAtPath:tmpPath
                      withIntermediateDirectories:YES
                                       attributes:nil
                                            error:&error];
    if (!created) {
        NSLog(@"❌ 创建 tmp 目录失败 %@: %@", tmpPath, error.localizedDescription);
    }
    return created;
}

@end
