#import <Foundation/Foundation.h>
#import <stdlib.h>

NS_ASSUME_NONNULL_BEGIN

static inline void ZONSchedulePostRestoreApplicationExit(void)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        exit(0);
    });
}

NS_ASSUME_NONNULL_END
