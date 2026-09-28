#import "ZONPresentationCoordinator.h"

@interface ZONPresentationTask : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) ZONPresentationBuilder builder;
@property (nonatomic, assign) NSUInteger retries;
@end
@implementation ZONPresentationTask
@end

@interface ZONPresentationCoordinator ()
@property (nonatomic, strong) NSMutableArray<ZONPresentationTask *> *queue;
@property (nonatomic, strong) NSMutableSet<NSString *> *keys;
@property (nonatomic, assign) BOOL busy;
@end

@implementation ZONPresentationCoordinator

+ (instancetype)sharedCoordinator {
    static ZONPresentationCoordinator *c;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [ZONPresentationCoordinator new];
        c.queue = [NSMutableArray array];
        c.keys = [NSMutableSet set];
    });
    return c;
}

- (void)enqueueWithKey:(NSString *)key builder:(ZONPresentationBuilder)builder {
    if (!key.length || !builder) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.keys containsObject:key]) return;
        ZONPresentationTask *task = [ZONPresentationTask new];
        task.key = key;
        task.builder = builder;
        [self.keys addObject:key];
        [self.queue addObject:task];
        [self drain];
    });
}

- (void)cancelPendingWithKey:(NSString *)key {
    if (!key.length) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexSet *indexes = [self.queue indexesOfObjectsPassingTest:^BOOL(ZONPresentationTask *obj, NSUInteger idx, BOOL *stop) {
            return [obj.key isEqualToString:key];
        }];
        if (indexes.count) [self.queue removeObjectsAtIndexes:indexes];
        [self.keys removeObject:key];
    });
}

- (UIWindow *)activeWindow {
    UIApplication *app = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive || ![scene isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) if (window.isKeyWindow) return window;
            for (UIWindow *window in windowScene.windows) if (!window.hidden && window.alpha > 0.0 && window.windowLevel == UIWindowLevelNormal) return window;
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (app.keyWindow) return app.keyWindow;
#pragma clang diagnostic pop
    for (UIWindow *window in app.windows) if (!window.hidden && window.alpha > 0.0) return window;
    return nil;
}

- (UIViewController *)topControllerFrom:(UIViewController *)vc {
    if (!vc) return nil;
    if (vc.presentedViewController && !vc.presentedViewController.isBeingDismissed) return [self topControllerFrom:vc.presentedViewController];
    if ([vc isKindOfClass:UINavigationController.class]) return [self topControllerFrom:((UINavigationController *)vc).visibleViewController];
    if ([vc isKindOfClass:UITabBarController.class]) return [self topControllerFrom:((UITabBarController *)vc).selectedViewController];
    for (UIViewController *child in vc.children.reverseObjectEnumerator) {
        if (child.viewIfLoaded.window) {
            UIViewController *candidate = [self topControllerFrom:child];
            if (candidate) return candidate;
        }
    }
    return vc;
}

- (UIViewController *)currentPresenter {
    UIWindow *window = [self activeWindow];
    UIViewController *vc = [self topControllerFrom:window.rootViewController];
    if (!vc || !vc.viewIfLoaded.window || vc.isBeingDismissed || vc.isBeingPresented) return nil;
    if (vc.transitionCoordinator) return nil;
    return vc;
}

- (void)finishTask:(ZONPresentationTask *)task {
    if (!task) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.keys removeObject:task.key];
        self.busy = NO;
        [self drain];
    });
}

- (void)retryTask:(ZONPresentationTask *)task {
    task.retries += 1;
    NSTimeInterval delay = MIN(0.15 + (task.retries * 0.05), 0.5);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.busy = NO;
        [self.queue insertObject:task atIndex:0];
        [self drain];
    });
}

- (void)drain {
    NSAssert(NSThread.isMainThread, @"presentation coordinator must run on main thread");
    if (self.busy || self.queue.count == 0) return;
    self.busy = YES;
    ZONPresentationTask *task = self.queue.firstObject;
    [self.queue removeObjectAtIndex:0];

    UIViewController *presenter = [self currentPresenter];
    if (!presenter) {
        [self retryTask:task];
        return;
    }

    __block BOOL finished = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_block_t finish = ^{
        if (finished) return;
        finished = YES;
        [weakSelf finishTask:task];
    };

    UIViewController *target = task.builder(finish);
    if (!target) {
        finish();
        return;
    }

    [presenter presentViewController:target animated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (finished) return;
        if (!target.presentingViewController) {
            if (task.retries < 20) {
                self.busy = NO;
                [self.queue insertObject:task atIndex:0];
                [self drain];
            } else {
                finish();
            }
        }
    });
}

@end
