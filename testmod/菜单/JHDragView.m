

#import "JHDragView.h"
#import "JHPP.h"
#import "NSObject+UI.h"

@interface JHDragView ()

@property BOOL keepFront;
@property BOOL keepWindow;
@property NSTimer* frontTimer;
@property CGPoint startLocation;

@end
static BOOL MenDeal;

@implementation JHDragView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (CGRectGetWidth(frame) <= 0 ||
        CGRectGetHeight(frame) <= 0) {
        frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 70, 130, 50, 50);
    }
    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
//        tap.numberOfTapsRequired = 2;//点击次数
//        tap.numberOfTouchesRequired = 3;//手指数
//        [[JHPP currentViewController].view addGestureRecognizer:tap];
//        [tap addTarget:self action:@selector(aaa)];
    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(aaa)];

    tap.numberOfTapsRequired = 2;//点击次数
    tap.numberOfTouchesRequired = 3;//手指数

    [[JHPP currentViewController].view addGestureRecognizer:tap];

    
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
        //self.layer.borderWidth = 0.95f;
        //self.backgroundColor = [UIColor blackColor];
        self.clipsToBounds = YES;
        self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2;
        self.alpha = 50.0f;
        //悬浮窗头像
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://app.zonoeios.xyz/uploads/20220704/d042be36ab9f4c73f0c721bccc6ba6c9.png"]];
                        UIImage *decodedImage = [UIImage imageWithData:imageData];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.layer.contents = (id)decodedImage.CGImage;
                        });
                    });
        
        self.keepFront = YES;
        self.keepWindow = NO;
        
        self.frontTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer*t){
            if(!self.hidden) {
                
                if(self.keepFront) [self.superview bringSubviewToFront:self];
                
                if (!self.keepWindow) {

                    UIWindow *window = nil;

                    // ✅ iOS13+ 正确获取 KeyWindow（支持 iPhone+iPad+iOS18）
                    if (@available(iOS 13.0, *)) {

                        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {

                            // 只找当前正在前台的 Scene
                            if (scene.activationState == UISceneActivationStateForegroundActive &&
                                [scene isKindOfClass:[UIWindowScene class]]) {

                                UIWindowScene *windowScene = (UIWindowScene *)scene;

                                // 遍历这个 Scene 的所有 window
                                for (UIWindow *w in windowScene.windows) {

                                    if (w.isKeyWindow) {
                                        window = w;
                                        break;
                                    }
                                }
                            }

                            if (window) break;
                        }

                    } else {
                        // iOS12 及以下
                        window = UIApplication.sharedApplication.keyWindow;
                    }

                    // ✅安全判断
                    if (window && self.superview != window) {
                        [window addSubview:self];
                    }
                }

            }
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.frontTimer invalidate];
        });
    }
    return self;
}
- (void)aaa {
    BOOL willHide = !self.hidden;

    if (!willHide) {
        self.hidden = NO;
        self.alpha = 0;
    }

    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = willHide ? 0.0 : 1.0;
    } completion:^(BOOL finished) {
        self.hidden = willHide;
    }];
}

//
//- (void)aaa{
//    if (!MenDeal) {
//        self.hidden = NO;
//    } else {
//        self.hidden = YES;
//    }
//    
//    MenDeal = !MenDeal;
//}

#pragma mark - override

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    self.startLocation = [touch locationInView:self.superview];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.superview];
    self.center = point;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint endLocation = [touch locationInView:self.superview];
    CGFloat dx = endLocation.x - self.startLocation.x;
    CGFloat dy = endLocation.y - self.startLocation.y;
    BOOL isTap = (dx * dx + dy * dy) <= 64.0f;

    [self shouldResetFrame];

    if (isTap) {
        [self vip菜单显示];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self shouldResetFrame];
}

#pragma mark - private

- (void)shouldResetFrame
{
    CGFloat midX = CGRectGetWidth(self.superview.frame)*0.5;
    CGFloat midY = CGRectGetHeight(self.superview.frame)*0.5;
    CGFloat maxX = midX*2;
    CGFloat maxY = midY*2;
    CGRect frame = self.frame;

    if (CGRectGetMinX(frame) < 0 ||
        CGRectGetMidX(frame) <= midX) {
        frame.origin.x = 0;
    }else if (CGRectGetMidX(frame) > midX ||
              CGRectGetMaxX(frame) > maxX) {
        frame.origin.x = maxX - CGRectGetWidth(frame);
    }

    if (CGRectGetMinY(frame) < 0) {
        frame.origin.y = 0;
    }else if (CGRectGetMaxY(frame) > maxY) {
        frame.origin.y = maxY - CGRectGetHeight(frame);
    }

    [UIView animateWithDuration:0.25 animations:^{
//        CGFloat width = MAX([UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
//        self.frame = CGRectMake(width-70, 100, 65, 65);
        self.frame = frame;
    }];
}


@end
