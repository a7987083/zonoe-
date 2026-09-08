//
//  jianghu.m
//  JSQ
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <pthread.h>
#include "MemScan.h"
#import <AVFoundation/AVFoundation.h>
#import <AdSupport/AdSupport.h>
#import <AVKit/AVKit.h>
#import "jianghu.h"
#import <AudioToolbox/AudioToolbox.h>
#import "UISlider+VDTrackHeight.h"
#import "ImgTool.h"
#import "PubgLoad.h"
#import "config.h"
#import "fuzhu.h"
#import "WX_NongShiFu123.h"
#import "getKeychain.h"
#import "NSString+MD5.h"
#import "SSZipArchive.h"
#import "MBProgressHUD.h"
#import "JHPP.h"
#import "PopupMenuVC.h"


#import "YYYPicker.h"
#import "daochucd.h"
#define CurrentViewSize self.view.frame.size


@interface jianghu ()<UITableViewDataSource,UITableViewDelegate,SSZipArchiveDelegate,NSURLSessionDelegate>
@property (nonatomic, strong) dispatch_source_t timer;
@property (readwrite, nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) NSTimer *viewCheckTimer;  // 定时器

@property (nullable, readonly, retain) id <NSURLSessionDelegate> delegate;

// 运行委托回调的操作队列。

@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;


@end
static NSDictionary *jsonx;
static UIView *UIViewJianghu;
static UITableView *personalTableView;
static float 比例 = 1;
static int 菜单 = 0;

static int MyMem = 2;   // 1 == 远程菜单； 2 == 工具箱内购； 3== 秒过广告
static int SuoDing;
static NSArray *zhugongneng;
static NSArray *dataSource;
static NSArray *chaxungongneng;

static UILabel *BianSuTitle;
static UILabel *AdTitle;

static UIView *调试;

static UIButton *群;
static UIButton *源码;
static UISegmentedControl *segment;

JJMemoryEngine* engine;
NSString *循环冻结;
NSTimer *timer;
BOOL 取消冻结;

//NSString *MyMems=[[NSUserDefaults standardUserDefaults] objectForKey:@"com.facebook.sdk.kits.botmaske"];
//int intString = [MyMems intValue];
//int MyMem = intString;

@implementation jianghu

static vector<void *> JieGuo(NSString *ss,NSString *lh,NSString *jq){
    
    NSArray *搜索 =[ss componentsSeparatedByString:@","];
    JJMemoryEngine engine = JJMemoryEngine(mach_task_self());//初始化
    uint64_t 搜索范围下限 = strtoul([搜索[2] UTF8String],0,16);
    uint64_t 搜索范围上限 = strtoul([搜索[3] UTF8String],0,16);
    AddrRange range = (AddrRange){0x0 + 搜索范围下限,0x0 + 搜索范围上限};

    if([搜索[0] isEqualToString:@"I8"]){
        if([搜索[1] containsString:@"-"]){
        SInt8 search = [搜索[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_SByte);
        }else{
        int8_t search = [搜索[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_UByte);
        }
    }else if([搜索[0] isEqualToString:@"I16"]){
        if([搜索[1] containsString:@"-"]){
        SInt16 search = [搜索[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_SShort);
        }else{
        int16_t search = [搜索[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_UShort);
        }
    }else if([搜索[0] isEqualToString:@"I32"]){
        if([搜索[1] containsString:@"-"]){
        SInt32 search = [搜索[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_SInt);
        }else{
        int32_t search = [搜索[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_UInt);
        }
    }else if([搜索[0] isEqualToString:@"I64"]){
        if([搜索[1] containsString:@"-"]){
        SInt64 search = [搜索[1] longLongValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_SLong);
        }else{
        int64_t search = [搜索[1] longLongValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_ULong);
        }
    }else if([搜索[0] isEqualToString:@"F32"]){
        float search = [搜索[1] floatValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_Float);
    }else if([搜索[0] isEqualToString:@"F64"]){
        double search = [搜索[1] doubleValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_Double);
    }
    
    if(lh){
    NSArray *联合 =[lh componentsSeparatedByString:@";"];
    for(int ll = 0; ll<联合.count;ll++){
        NSArray *联合搜索 =[联合[ll] componentsSeparatedByString:@","];
        int 范围 = [[NSString stringWithFormat:@"%lu",strtoul([联合搜索[2] UTF8String],0,16)] intValue];

        if([联合搜索[0] isEqualToString:@"I8"]){
            if([联合搜索[1] containsString:@"-"]){
            SInt8 search = [联合搜索[1] intValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_SByte);
            }else{
            int8_t search = [联合搜索[1] intValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_UByte);
            }
        }else if([联合搜索[0] isEqualToString:@"I16"]){
            if([联合搜索[1] containsString:@"-"]){
            SInt16 search = [联合搜索[1] intValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_SShort);
            }else{
            int16_t search = [联合搜索[1] intValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_UShort);
            }
        }else if([联合搜索[0] isEqualToString:@"I32"]){
            if([联合搜索[1] containsString:@"-"]){
            SInt32 search = [联合搜索[1] intValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_SInt);
            }else{
            int32_t search = [联合搜索[1] intValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_UInt);
            }
        }else if([联合搜索[0] isEqualToString:@"I64"]){
            if([联合搜索[1] containsString:@"-"]){
            SInt64 search = [联合搜索[1] longLongValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_SLong);
            }else{
            int64_t search = [联合搜索[1] longLongValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_ULong);
            }
        }else if([联合搜索[0] isEqualToString:@"F32"]){
            float search = [联合搜索[1] floatValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_Float);
        }else if([联合搜索[0] isEqualToString:@"F64"]){
            double search = [联合搜索[1] doubleValue];
            engine.JJNearBySearch(范围, &search, JJ_Search_Type_Double);
        }

    }
    }
    
    if(jq){
    NSArray *精确 =[jq componentsSeparatedByString:@","];
    uint64_t 精确范围下限 = strtoul([精确[2] UTF8String],0,16);
    uint64_t 精确范围上限 = strtoul([精确[3] UTF8String],0,16);
    range = (AddrRange){0x0 + 精确范围下限,0x0 + 精确范围上限};

    if([精确[0] isEqualToString:@"I8"]){
        if([精确[1] containsString:@"-"]){
        SInt8 search = [精确[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_SByte);
        }else{
        int8_t search = [精确[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_UByte);
        }
    }else if([精确[0] isEqualToString:@"I16"]){
        if([精确[1] containsString:@"-"]){
        SInt16 search = [精确[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_SShort);
        }else{
        int16_t search = [精确[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_UShort);
        }
    }else if([精确[0] isEqualToString:@"I32"]){
        if([精确[1] containsString:@"-"]){
        SInt32 search = [精确[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_SInt);
        }else{
        int32_t search = [精确[1] intValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_UInt);
        }
    }else if([精确[0] isEqualToString:@"I64"]){
        if([精确[1] containsString:@"-"]){
        SInt64 search = [精确[1] longLongValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_SLong);
        }else{
        int64_t search = [精确[1] longLongValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_ULong);
        }
    }else if([精确[0] isEqualToString:@"F32"]){
        float search = [精确[1] floatValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_Float);
    }else if([精确[0] isEqualToString:@"F64"]){
        double search = [精确[1] doubleValue];
        engine.JJScanMemory(range, &search, JJ_Search_Type_Double);
    }
    }
    return engine.getResults(engine.getResultsCount());
    
}

static void Xg2(NSString *a,NSString *b,NSString *c,NSString *d,BOOL Dj){
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        JJMemoryEngine engine = JJMemoryEngine(mach_task_self());
    if([a isEqualToString:@"I8"]){
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        if([b containsString:@"-"]){
            SInt8 search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py),&search,JJ_Search_Type_SByte);
        }else{
            int8_t search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_UByte);
        }
    }else if([a isEqualToString:@"I16"]){
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        if([b containsString:@"-"]){
            SInt16 search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_SShort);
        }else{
            uint16_t search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_UShort);
        }
    }else if([a isEqualToString:@"I32"]){
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        if([b containsString:@"-"]){
            SInt32 search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_SInt);
        }else{
            int32_t search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_UInt);
        }
    }else if([a isEqualToString:@"I64"]){
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        if([b containsString:@"-"]){
            SInt64 search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_SLong);
        }else{
            int64_t search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_ULong);
        }
    }else if([a isEqualToString:@"F32"]){
        float search = [b floatValue];
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_Float);
    }else if([a isEqualToString:@"F64"]){
        double search = [b doubleValue];
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_Double);
    }
    
    //循环修改冻结的数据
    NSArray *xh =[循环冻结 componentsSeparatedByString:@"\n"];
        if(取消冻结 != YES && Dj == YES){
            for(int e = 0;e<xh.count-1;e++){
            NSArray *g =[xh[e] componentsSeparatedByString:@"#"];
                if(e == xh.count-2){
                Xg2(g[0],g[1],g[2],g[3],YES);
                }else{
                    Xg2(g[0],g[1],g[2],g[3],NO);
                }
                usleep(3000);
               }
        }
    });
    
}

static void Xg(NSString *a,NSString *b,NSString *c,NSString *d,BOOL Dj){
    //冻结数据时进行保存数据
    if(Dj){
        循环冻结 = [NSString stringWithFormat:@"%@#%@#%@#%@\n%@",a,b,c,d,循环冻结];
        取消冻结 = NO;
        Xg2(a,b,c,d,YES);
    }
    JJMemoryEngine engine = JJMemoryEngine(mach_task_self());
    //修改
    if([a isEqualToString:@"I8"]){
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        if([b containsString:@"-"]){
            SInt8 search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py),&search,JJ_Search_Type_SByte);
        }else{
            int8_t search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_UByte);
        }
    }else if([a isEqualToString:@"I16"]){
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        if([b containsString:@"-"]){
            SInt16 search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_SShort);
        }else{
            uint16_t search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_UShort);
        }
    }else if([a isEqualToString:@"I32"]){
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        if([b containsString:@"-"]){
            SInt32 search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_SInt);
        }else{
            int32_t search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_UInt);
        }
    }else if([a isEqualToString:@"I64"]){
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        if([b containsString:@"-"]){
            SInt64 search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_SLong);
        }else{
            int64_t search = [b intValue];
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_ULong);
        }
    }else if([a isEqualToString:@"F32"]){
        float search = [b floatValue];
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_Float);
    }else if([a isEqualToString:@"F64"]){
        double search = [b doubleValue];
        int py = [d intValue];
        uint64_t dz = strtoul([c UTF8String],0,16);
        engine.JJWriteMemory((void *)((unsigned long long)(dz)+py), &search, JJ_Search_Type_Double);
    }
    
}

static BOOL Wzpd(NSString *a,NSString *b){
    if ([a hasSuffix:b]) {
        return YES;
    }
    return NO;
}


static BOOL Szpd(NSString *a,NSString *b,NSString *c,NSString *d,NSString *e){
    
    int py = [c intValue];
    NSArray *兼 = [e componentsSeparatedByString:@"or"];
    if([a isEqualToString:@"I8"]){
        if([d containsString:@"=="] || [d containsString:@">="] || [d containsString:@"<="]){
        uint64_t dz = strtoul([b UTF8String],0,16);
        int8_t sz = *(int8_t*)((unsigned long long)(dz)+ py);
            for(int j = 0;j<兼.count;j++){
            if([d containsString:@"=="] ? sz == [兼[j] intValue] : [d containsString:@">="] ? sz >= [兼[j] intValue] : sz <= [兼[j] intValue]){
                return YES;
            }else{
                if(j == 兼.count-1){
                return NO;
                }
            }
            }
        }
    }else if([a isEqualToString:@"I16"]){
        if([d containsString:@"=="] || [d containsString:@">="] || [d containsString:@"<="]){
        uint64_t dz = strtoul([b UTF8String],0,16);
            int16_t sz = *(int16_t*)((unsigned long long)(dz)+ py);
            for(int j = 0;j<兼.count;j++){
            if([d containsString:@"=="] ? sz == [兼[j] intValue] : [d containsString:@">="] ? sz >= [兼[j] intValue] : sz <= [兼[j] intValue]){
                return YES;
            }else{
                if(j == 兼.count-1){
                return NO;
                }
            }
            }
        }
    }else if([a isEqualToString:@"I32"]){
        if([d containsString:@"=="] || [d containsString:@">="] || [d containsString:@"<="]){
        uint64_t dz = strtoul([b UTF8String],0,16);
            int32_t sz = *(int32_t*)((unsigned long long)(dz)+ py);
            for(int j = 0;j<兼.count;j++){
            if([d containsString:@"=="] ? sz == [兼[j] intValue] : [d containsString:@">="] ? sz >= [兼[j] intValue] : sz <= [兼[j] intValue]){
                return YES;
            }else{
                if(j == 兼.count-1){
                return NO;
                }
            }
            }
        }
    }else if([a isEqualToString:@"I64"]){
        if([d containsString:@"=="] || [d containsString:@">="] || [d containsString:@"<="]){
        uint64_t dz = strtoul([b UTF8String],0,16);
            int64_t sz = *(int64_t*)((unsigned long long)(dz)+ py);
            for(int j = 0;j<兼.count;j++){
            if([d containsString:@"=="] ? sz == [兼[j] longLongValue] : [d containsString:@">="] ? sz >= [兼[j] longLongValue] : sz <= [兼[j] longLongValue]){
                return YES;
            }else{
                if(j == 兼.count-1){
                return NO;
                }
            }
            }
        }
    }else if([a isEqualToString:@"F32"]){
        if([d containsString:@"=="] || [d containsString:@">="] || [d containsString:@"<="]){
        uint64_t dz = strtoul([b UTF8String],0,16);
            float sz = *(float*)((unsigned long long)(dz)+ py);
            for(int j = 0;j<兼.count;j++){
            if([d containsString:@"=="] ? sz == [兼[j] floatValue] : [d containsString:@">="] ? sz >= [兼[j] floatValue] : sz <= [兼[j] floatValue]){
                return YES;
            }else{
                if(j == 兼.count-1){
                return NO;
                }
            }
            }
        }
    }else if([a isEqualToString:@"F64"]){
        if([d containsString:@"=="] || [d containsString:@">="] || [d containsString:@"<="]){
        uint64_t dz = strtoul([b UTF8String],0,16);
        double sz = *(double*)((unsigned long long)(dz)+ py);
            for(int j = 0;j<兼.count;j++){
            if([d containsString:@"=="] ? sz == [兼[j] doubleValue] : [d containsString:@">="] ? sz >= [兼[j] doubleValue] : sz <= [兼[j] doubleValue]){
                return YES;
            }else{
                if(j == 兼.count-1){
                return NO;
                }
            }
            }
        }
    }
    return YES;
}

+ (NSString *)getUTF8EncodeStringWithURLString:(NSString *)urlString
{
    if (urlString && urlString.length > 0)
    {
        NSString *encodedString = (NSString *)
        CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                  (CFStringRef)urlString,
                                                                  (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                                  NULL,
                                                                  kCFStringEncodingUTF8));
        return encodedString;
    }
    else
    {
        return @"";
    }
}

+ (void)chushihua
{
  
    dispatch_async(dispatch_get_main_queue(), ^{
        [jianghu chushihuad];
        [jianghu qonConsol1loopleButtonTappeda];
    });
    
    
}

+ (void)qonConsol1loopleButtonTappeda{
    if(菜单 == 0){
        菜单 = 1;
        CGFloat Width = 350; CGFloat Height = 280;
        
        UIWindow *mainWindow1 = [UIApplication sharedApplication].keyWindow;
        UIViewJianghu = [[UIView alloc]
                         initWithFrame:CGRectMake(0,0, Width, Height)];
        UIViewJianghu.backgroundColor=[UIColor colorWithRed:239 / 255.0 green:238 / 255.0 blue:245 / 255.0 alpha:1];
        UIViewJianghu.layer.borderColor = [[UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f] CGColor];
        UIViewJianghu.layer.borderWidth = 1.0f;
        UIViewJianghu.layer.cornerRadius = 5;
        UIViewJianghu.hidden=NO;
        UIViewJianghu.center = mainWindow1.center;
        UIViewJianghu.alpha = 0.0f;
        [[JHPP currentViewController].view addSubview:UIViewJianghu];
        [UIView animateWithDuration:1 animations:^{
            UIViewJianghu.alpha = 1;
        }];
      
        UIView *h = [[UIView alloc]
                     initWithFrame:CGRectMake(0,0, UIViewJianghu.frame.size.width, 50)];
        h.backgroundColor=[UIColor whiteColor];
        h.layer.cornerRadius = 5;
        [UIViewJianghu addSubview:h];
        
        UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(movingBtn:)];
        [h addGestureRecognizer:pan];
        
        [jianghu addShadowToView:h withColor:[UIColor blackColor]];
        
        UIButton *touxiang = [[UIButton alloc]
                              initWithFrame:CGRectMake(10,10, 30, 30)];
        touxiang.backgroundColor=[UIColor blackColor];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://app.zonoeios.xyz/uploads/20221117/136ffb242c8f8b10b5a5814a95faa80b.png"]];
                UIImage *decodedImage = [UIImage imageWithData:imageData];
                dispatch_async(dispatch_get_main_queue(), ^{touxiang.layer.contents = (id)decodedImage.CGImage;});});
        touxiang.clipsToBounds = YES;
        touxiang.layer.cornerRadius = CGRectGetWidth(touxiang.bounds) / 2;
        [touxiang addTarget:self action:@selector(调试) forControlEvents:UIControlEventTouchUpInside];
        [h addSubview:touxiang];
//
//        UILabel *BT = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, h.frame.size.width, 30)];
//        BT.numberOfLines = 0;
//        BT.lineBreakMode = NSLineBreakByCharWrapping;
//        BT.text = @"功能";
//        BT.textAlignment = NSTextAlignmentCenter;
//        BT.font = [UIFont boldSystemFontOfSize:15];
//        BT.textColor = [UIColor blackColor];
//        [h addSubview:BT];
        
        UIButton *调整 = [[UIButton alloc]
                        initWithFrame:CGRectMake(50,10, 70, 30)];
        
        [调整 setTitle:@"VIP功能" forState:UIControlStateNormal];
        [调整 setTitleColor:[UIColor colorWithRed:67 / 255.0 green:110 / 255.0 blue:238 / 255.0 alpha:1] forState:UIControlStateNormal];//p1颜色
        调整.backgroundColor=[UIColor colorWithRed:239 / 255.0 green:238 / 255.0 blue:245 / 255.0 alpha:1];
        调整.layer.borderWidth = 1.0f;//边框大小
        [调整.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
        调整.clipsToBounds = YES;
        调整.layer.cornerRadius = 5;
        [调整 addTarget:self action:@selector(调试) forControlEvents:UIControlEventTouchUpInside];
        [h addSubview:调整];
//
        UIButton *调整a = [[UIButton alloc]
                        initWithFrame:CGRectMake(230,10, 70, 30)];
        
        [调整a setTitle:@"游戏大全" forState:UIControlStateNormal];
        [调整a setTitleColor:[UIColor colorWithRed:67 / 255.0 green:110 / 255.0 blue:238 / 255.0 alpha:1] forState:UIControlStateNormal];//p1颜色
        调整a.backgroundColor=[UIColor colorWithRed:239 / 255.0 green:238 / 255.0 blue:245 / 255.0 alpha:1];
        调整a.layer.borderWidth = 1.0f;//边框大小
        [调整a.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
        调整a.clipsToBounds = YES;
        调整a.layer.cornerRadius = 5;
        [调整a addTarget:self action:@selector(源码) forControlEvents:UIControlEventTouchUpInside];
        [h addSubview:调整a];
//
//
//        UIButton *BT = [[UIButton alloc]
//                        initWithFrame:CGRectMake(130, 10, 70, 30)];
//
//        [BT setTitle:@"秒过广告" forState:UIControlStateNormal];
//        [BT setTitleColor:[UIColor colorWithRed:67 / 255.0 green:110 / 255.0 blue:238 / 255.0 alpha:1] forState:UIControlStateNormal];//p1颜色
//        BT.backgroundColor=[UIColor colorWithRed:239 / 255.0 green:238 / 255.0 blue:245 / 255.0 alpha:1];
//        BT.layer.borderWidth = 1.0f;//边框大小
//        [BT.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
//        BT.clipsToBounds = YES;
//        BT.layer.cornerRadius = 5;
//        [BT addTarget:self action:@selector(秒过广告:) forControlEvents:UIControlEventTouchUpInside];
//        [h addSubview:BT];
//
//
        UILabel *BT = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, h.frame.size.width, 30)];
        BT.numberOfLines = 0;
        BT.lineBreakMode = NSLineBreakByCharWrapping;
        BT.text = @"zonoe源游戏";
        BT.textAlignment = NSTextAlignmentCenter;
        BT.font = [UIFont boldSystemFontOfSize:15];
        BT.textColor = [UIColor blackColor];
        [h addSubview:BT];
        
        
        NSString *kmmm=[[NSUserDefaults standardUserDefaults] objectForKey:@"到期时间"];
        NSString *daoqishijian = [NSString stringWithFormat:@"到期时间:\n%@", kmmm];
//        UILabel *BTa = [[UILabel alloc] initWithFrame:CGRectMake(15,10, 200, -90)];
        UILabel *BTa = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, h.frame.size.width, -50)];
        BTa.numberOfLines = 0;
        BTa.lineBreakMode = NSLineBreakByCharWrapping;
        BTa.text = daoqishijian;
        BTa.textAlignment = NSTextAlignmentCenter;
        BTa.font = [UIFont boldSystemFontOfSize:15];
        BTa.textColor = [UIColor blackColor];
        [h addSubview:BTa];
        
        UIButton *调整B = [[UIButton alloc]
                         initWithFrame:CGRectMake(130,10, 90, 30)];
        调整B.clipsToBounds = YES;
        调整B.layer.cornerRadius = 5;
        [调整B addTarget:self action:@selector(秒过广告:) forControlEvents:UIControlEventTouchUpInside];
        [h addSubview:调整B];
//
        
        UIButton *关闭 = [[UIButton alloc]
                        initWithFrame:CGRectMake(h.frame.size.width-30,15, 20, 20)];
        关闭.backgroundColor=[UIColor blueColor];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://app.zonoeios.xyz/uploads/20240504/32a23c04f0ada3f4a91482d8f1402c07.png"]];
                UIImage *decodedImage = [UIImage imageWithData:imageData];
                dispatch_async(dispatch_get_main_queue(), ^{关闭.layer.contents = (id)decodedImage.CGImage;});});
        关闭.clipsToBounds = YES;
        关闭.layer.cornerRadius = CGRectGetWidth(关闭.bounds) / 2;
        [关闭 addTarget:self action:@selector(关闭菜单) forControlEvents:UIControlEventTouchUpInside];
        [h addSubview:关闭];
        
        //UIViewJianghu.frame.size.width
        personalTableView = [[UITableView alloc]initWithFrame:CGRectMake(20,60,UIViewJianghu.frame.size.width-40,UIViewJianghu.frame.size.height-70) style:UITableViewStyleGrouped];
        personalTableView.backgroundColor = [UIColor colorWithRed:239 / 255.0 green:238 / 255.0 blue:245 / 255.0 alpha:1];
        personalTableView.bounces = YES;//yes，就是滚动超过边界会反弹有反弹回来的效果; NO，那么滚动到达边界会立刻停止。
        personalTableView.dataSource = (id<UITableViewDataSource>) self;
        personalTableView.delegate = (id<UITableViewDelegate>) self;
        personalTableView.showsVerticalScrollIndicator = NO;//不显示右侧滑块
        personalTableView.separatorStyle = UITableViewCellSeparatorStyleNone;//分割线
        [UIViewJianghu addSubview:personalTableView];
        
        
    }else{
        UIViewJianghu.hidden = NO;
        [UIView animateKeyframesWithDuration:0.7 delay:0 options:0 animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.4 animations:^{
                UIViewJianghu.transform = CGAffineTransformMakeScale(比例+0.05, 比例+0.05);
            }];
            [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.7 animations:^{
                UIViewJianghu.transform = CGAffineTransformMakeScale(比例, 比例);
            }];
        }completion:nil];
    }
    
}

// 在合适的地方（例如初始化方法）启动定时器
+ (void)chushihuad {
    // 启动定时器，每隔1秒检查一次视图层级
    jianghu *selfObject = [[jianghu alloc] init];
    selfObject.viewCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                 target:selfObject
                                                               selector:@selector(checkViewHierarchy)
                                                               userInfo:nil
                                                                repeats:YES];
}

- (void)checkViewHierarchy {
    // 你可以在这里添加逻辑来检查视图层级
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
    NSArray *subviews = mainWindow.subviews;
    
    // 你可以检查UIViewJianghu是否正确显示
    if (![subviews containsObject:UIViewJianghu]) {
        NSLog(@"UIViewJianghu未添加到窗口中！");
    } else {
        NSLog(@"UIViewJianghu已正确添加到窗口！");
    }
    
    // 例如，你还可以检查视图的顺序或特定的层级关系
    if (UIViewJianghu.alpha == 0.0f) {
        NSLog(@"UIViewJianghu不可见");
    } else {
        NSLog(@"UIViewJianghu可见");
    }
}

// 关闭定时器
- (void)stopViewCheckTimer {
    if (self.viewCheckTimer) {
        [self.viewCheckTimer invalidate];
        self.viewCheckTimer = nil;
    }
}


+ (void)调试{
    
    if(调试.hidden == YES){
        调试.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^{
            调试.alpha = 1;
        }];
        
    }else{
    
    调试 = [[UIView alloc]
                 initWithFrame:CGRectMake(0,0, UIViewJianghu.frame.size.width - 35, 50)];
    调试.backgroundColor=[UIColor whiteColor];
    调试.layer.cornerRadius = 5;
    调试.alpha = 0;
    [UIViewJianghu addSubview:调试];
    
    [UIView animateWithDuration:0.5 animations:^{
        调试.alpha = 1;
    }];
    
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(movingBtn:)];
    [调试 addGestureRecognizer:pan];
//        NSString *MyMems=[[NSUserDefaults standardUserDefaults] objectForKey:@"com.facebook.sdk.kits.botmaske"];
//        int intString = [MyMems intValue];
//        int MyMem = intString;
    UIButton *工具 = [[UIButton alloc]
                    initWithFrame:CGRectMake(10,10, 调试.frame.size.width / 4-10, 30)];
//        if(MyMem == 1){
//        [工具 setTitle:@"工具箱" forState:UIControlStateNormal];
//        }else if(MyMem == 2){
//        [工具 setTitle:@"主功能" forState:UIControlStateNormal];
//        }else if(MyMem == 3){
//        [工具 setTitle:@"主功能" forState:UIControlStateNormal];
//        }
//        else if(MyMem == 4){
//        [工具 setTitle:@"存档功能" forState:UIControlStateNormal];
//        }
        [工具 setTitle:@"主功能" forState:UIControlStateNormal];
    [工具 setTitleColor:[UIColor colorWithRed:67 / 255.0 green:110 / 255.0 blue:238 / 255.0 alpha:1] forState:UIControlStateNormal];//p1颜色
    工具.backgroundColor=[UIColor colorWithRed:239 / 255.0 green:238 / 255.0 blue:245 / 255.0 alpha:1];
    工具.layer.borderWidth = 1.0f;//边框大小
    [工具.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
    工具.clipsToBounds = YES;
    工具.layer.cornerRadius = 5;
    [工具 addTarget:self action:@selector(工具:) forControlEvents:UIControlEventTouchUpInside];
    [调试 addSubview:工具];
    
    UIButton *调整 = [[UIButton alloc]
                    initWithFrame:CGRectMake(调试.frame.size.width / 4 + 10,10, 调试.frame.size.width / 4-10, 30)];
    
    [调整 setTitle:@"存档功能" forState:UIControlStateNormal];
    [调整 setTitleColor:[UIColor colorWithRed:67 / 255.0 green:110 / 255.0 blue:238 / 255.0 alpha:1] forState:UIControlStateNormal];//p1颜色
    调整.backgroundColor=[UIColor colorWithRed:239 / 255.0 green:238 / 255.0 blue:245 / 255.0 alpha:1];
    调整.layer.borderWidth = 1.0f;//边框大小
    [调整.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
    调整.clipsToBounds = YES;
    调整.layer.cornerRadius = 5;
    [调整 addTarget:self action:@selector(功能:) forControlEvents:UIControlEventTouchUpInside];
    [调试 addSubview:调整];
    
    源码 = [[UIButton alloc]
                    initWithFrame:CGRectMake(调试.frame.size.width / 4 *2 + 10,10, 调试.frame.size.width / 4-10, 30)];
    
    [源码 setTitle:@"VIP存档" forState:UIControlStateNormal];
    [源码 setTitleColor:[UIColor colorWithRed:67 / 255.0 green:110 / 255.0 blue:238 / 255.0 alpha:1] forState:UIControlStateNormal];//p1颜色
    源码.backgroundColor=[UIColor colorWithRed:239 / 255.0 green:238 / 255.0 blue:245 / 255.0 alpha:1];
    源码.layer.borderWidth = 1.0f;//边框大小
    [源码.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
    源码.clipsToBounds = YES;
    源码.layer.cornerRadius = 5;
    [源码 addTarget:self action:@selector(yuncd) forControlEvents:UIControlEventTouchUpInside];
    [调试 addSubview:源码];
    
    群 = [[UIButton alloc]
                    initWithFrame:CGRectMake(调试.frame.size.width / 4 *3 + 10,10, 调试.frame.size.width / 4-10, 30)];
    
    [群 setTitle:@"远程下载" forState:UIControlStateNormal];
    [群 setTitleColor:[UIColor colorWithRed:67 / 255.0 green:110 / 255.0 blue:238 / 255.0 alpha:1] forState:UIControlStateNormal];//p1颜色
    群.backgroundColor=[UIColor colorWithRed:239 / 255.0 green:238 / 255.0 blue:245 / 255.0 alpha:1];
    群.layer.borderWidth = 1.0f;//边框大小
    [群.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
    群.clipsToBounds = YES;
    群.layer.cornerRadius = 5;
    [群 addTarget:self action:@selector(远程) forControlEvents:UIControlEventTouchUpInside];
    [调试 addSubview:群];
    }
     
}


+ (UIViewController *)topViewController {

    UIViewController *rootVC =
    [UIApplication sharedApplication].keyWindow.rootViewController;

    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }

    return rootVC;
}

#pragma mark - 全局显示弹窗

+ (void)源码 {

    dispatch_async(dispatch_get_main_queue(), ^{

        UIViewController *topVC = [self topViewController];

        PopupMenuVC *menu = [PopupMenuVC new];
        menu.modalPresentationStyle = UIModalPresentationOverFullScreen;

        [topVC presentViewController:menu animated:NO completion:nil];
    });
}


+ (void)远程{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                       {
            [[PubgLoad alloc] yuanchengdwon];
            [self 关闭菜单];
        });
       
    }


+ (void)菜单调整{
//    if(segment.alpha == 1){
//        源码.hidden = NO;
//        群.hidden = NO;
//        [UIView animateKeyframesWithDuration:0.6 delay:0 options:0 animations:^{
//            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.3 animations:^{
//                segment.alpha = 0;
//            }];
//            [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.6 animations:^{
//                源码.alpha = 1;
//                群.alpha = 1;
//            }];
//        }completion:^(BOOL finished) {
//            [segment removeFromSuperview];
//        }];
//
//    }else{
//
//    NSArray *array = [NSArray arrayWithObjects:@"还原",@"缩小",@"放大", nil];
//    //初始化UISegmentedControl
//    segment = [[UISegmentedControl alloc]initWithItems:array];
//    //设置frame
//    segment.frame = CGRectMake(调试.frame.size.width / 4*2 + 10, 10, 调试.frame.size.width / 4*2-10, 30);
//    segment.apportionsSegmentWidthsByContent = YES;
//    segment.momentary = YES;
//        segment.alpha = 0;
//    //添加到视图
//    [segment addTarget:self action:@selector(change:) forControlEvents:UIControlEventValueChanged];
//    [调试 addSubview:segment];
//
//        [UIView animateKeyframesWithDuration:0.6 delay:0 options:0 animations:^{
//            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.3 animations:^{
//                源码.alpha = 0;
//                群.alpha = 0;
//            }];
//            [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.6 animations:^{
//                segment.alpha = 1;
//            }];
//        }completion:^(BOOL finished) {
//            源码.hidden = YES;
//            群.hidden = YES;
//        }];
//    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSFileManager *Manager = [NSFileManager defaultManager];

        NSString *dataFile = [NSHomeDirectory() stringByAppendingString:@"/tmp/"];
        NSString *imageDir = [NSString stringWithFormat:@"%@",dataFile];
        NSLog(@"✈️删除tmp, %@", imageDir);
        [Manager removeItemAtPath:imageDir error:nil];
        
        NSString *dataFilez = [NSHomeDirectory() stringByAppendingString:@"/Documents/"];
        NSString *imageDirz = [NSString stringWithFormat:@"%@",dataFilez];
        NSLog(@"✈️删除tmp, %@", imageDirz);
        [Manager removeItemAtPath:imageDirz error:nil];
        
        NSString *dataFilex = [NSHomeDirectory() stringByAppendingString:@"/Library/"];
        NSString *imageDirx = [NSString stringWithFormat:@"%@",dataFilex];
        NSLog(@"✈️删除tmp, %@", imageDirx);
        [Manager removeItemAtPath:imageDirx error:nil];
        //清空plist
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
        
        
        NSString *DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:DocumentsPath];
        
        for (NSString *fileName in enumerator) {
            
            [[NSFileManager defaultManager] removeItemAtPath:[DocumentsPath stringByAppendingPathComponent:fileName] error:nil];
            
        }
        
        NSString *LibraryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
        
        NSDirectoryEnumerator *enumerator1 = [[NSFileManager defaultManager] enumeratorAtPath:LibraryPath];
        
        for (NSString *fileName in enumerator1) {
            
            [[NSFileManager defaultManager] removeItemAtPath:[LibraryPath stringByAppendingPathComponent:fileName] error:nil];
        }
        
        
        
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

+ (void)工具:(UIButton *)a{
//    NSString *MyMems=[[NSUserDefaults standardUserDefaults] objectForKey:@"com.facebook.sdk.kits.botmaske"];
//    int intString = [MyMems intValue];
//    int MyMembut = intString;
    if(MyMem == 1){
        MyMem = 2;
        [a setTitle:@"云存档" forState:UIControlStateNormal];
    }else if(MyMem == 2){
        MyMem = 1;
        [a setTitle:@"工具箱" forState:UIControlStateNormal];
    }else if(MyMem == 3){
        MyMem = 2;
        [a setTitle:@"工具箱" forState:UIControlStateNormal];
    }
    if(MyMem == 4){
        MyMem = 2;
        [a setTitle:@"工具箱" forState:UIControlStateNormal];
    }
//    if(MyMembut == 2|| (MyMem == 1)){
//    MyMem = 2;
//    [a setTitle:@"工具箱c" forState:UIControlStateNormal];
//    }
//   if(MyMembut == 3|| (MyMem == 4)){
//    MyMem = 3;
//    [a setTitle:@"工具箱d" forState:UIControlStateNormal];
//    }

    
    [UIView transitionWithView: personalTableView
                      duration: 0.5f
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^(void)
     {
         [personalTableView reloadData];
         调试.alpha = 0;
     }
                    completion: ^(BOOL isFinished)
     {
         调试.hidden = YES;
     }];
}
+ (void)功能:(UIButton *)a{

    MyMem = 4;
    [a setTitle:@"存档功能" forState:UIControlStateNormal];
    
    
    
    [UIView transitionWithView: personalTableView
                      duration: 0.5f
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^(void)
     {
         [personalTableView reloadData];
         调试.alpha = 0;
     }
                    completion: ^(BOOL isFinished)
     {
         调试.hidden = YES;
     }];
}
+ (void)秒过广告:(UIButton *)a{

    MyMem = 2;
//    [a setTitle:@"存档功能" forState:UIControlStateNormal];
    
    
    
    [UIView transitionWithView: personalTableView
                      duration: 0.5f
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^(void)
     {
         [personalTableView reloadData];
         调试.alpha = 0;
     }
                    completion: ^(BOOL isFinished)
     {
         调试.hidden = YES;
     }];
}


+ (void)change:(UISegmentedControl *)sender{
    if (sender.selectedSegmentIndex == 0) {
        比例 =  1;
        [UIView animateWithDuration:0.2 animations:^{
            UIViewJianghu.transform = CGAffineTransformMakeScale(比例, 比例);
        }];
    }else if (sender.selectedSegmentIndex == 1) {
        比例 =  比例 - 0.1;
        [UIView animateWithDuration:0.2 animations:^{
            UIViewJianghu.transform = CGAffineTransformMakeScale(比例, 比例);
        }];
    }else if (sender.selectedSegmentIndex == 2){
        比例 =  比例 + 0.1;
        [UIView animateWithDuration:0.2 animations:^{
            UIViewJianghu.transform = CGAffineTransformMakeScale(比例, 比例);
        }];
    }
}

+ (void)addShadowToView:(UIView *)theView withColor:(UIColor *)theColor {
    // 阴影颜色
    theView.layer.shadowColor = theColor.CGColor;
    // 阴影偏移，默认(0, -3)
    theView.layer.shadowOffset = CGSizeMake(0,0);
    // 阴影透明度，默认0
    theView.layer.shadowOpacity = 0.5;
    // 阴影半径，默认3
    theView.layer.shadowRadius = 5;
}

+ (void)关闭菜单{
    [UIView animateWithDuration:0.5 animations:^{
        UIViewJianghu.transform = CGAffineTransformMakeScale(0.0001, 0.0001);
    } completion:^(BOOL finished) {
//        [UIViewJianghu removeFromSuperview];
        UIViewJianghu.hidden = YES;
        调试.alpha = 0;
        调试.hidden = YES;
        //UIViewJianghu.alpha = 0;
        // UIViewJianghu.transform = CGAffineTransformMakeScale(比例, 比例);
       
    }];
    
}

+ (void)movingBtn:(UIPanGestureRecognizer *)recognizer{
   // UIView *jianghuui = (UIView *)recognizer.view;
    CGPoint translation = [recognizer translationInView:UIViewJianghu];
    if(recognizer.state == UIGestureRecognizerStateBegan){
    }else if(recognizer.state == UIGestureRecognizerStateChanged){
        UIViewJianghu.center = CGPointMake(UIViewJianghu.center.x + translation.x, UIViewJianghu.center.y + translation.y);
        [recognizer setTranslation:CGPointZero inView:UIViewJianghu];
    }else if(recognizer.state == UIGestureRecognizerStateEnded){
        CGFloat newX2=UIViewJianghu.center.x;
        CGFloat newY2=UIViewJianghu.center.y;
        UIViewJianghu.center = CGPointMake(newX2, newY2);
        [recognizer setTranslation:CGPointZero inView:UIViewJianghu];
    }
}



#pragma mark - TbaleView的数据源代理方法实现
+ (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  
    if(MyMem == 1){
        return 1;
    }
    
    //------------------------------工具箱------------------------------//
    else if(MyMem == 2){
        return 4;
    } else if(MyMem == 3){
        return 2;
    }else if(MyMem == 4){
        return 1;
    }

    return 1;
}
//返回行数的代理方法
+ (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  
    
    if(MyMem == 1){
    for (int ii=0; ii<zhugongneng.count; ii++) {
        if (section==ii){
            NSArray *HangShu = [zhugongneng[ii] objectForKey:@"gongneng"];
            NSLog(@"asdasd=%@",HangShu);

            return HangShu.count;
        }
    }
    }
    
    
    //------------------------------工具箱------------------------------//
    else if(MyMem == 2){
        if (section==0 || section==3){
            return 1;
        }else{
            return 2;
        }
    }
    else if(MyMem == 3){
        if (section==0 || section==3){
            return 2;
        }else{
            return 2;
        }
    }
    else  if(MyMem == 4){
        if (section==0){
            return 4;
        }else{
            return 1;
        }
        
    }
    return 1;
}
//每个分组上边预留的空白高度
+ (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
 
    if(MyMem == 1){
        
        for (int ii=0; ii<zhugongneng.count; ii++) {
            if (section==ii){
                NSString *ShuoMing = [[zhugongneng[ii] objectForKey:@"说明"] stringByReplacingOccurrencesOfString:@"br" withString:@"\n"];
                NSArray *askas =[ShuoMing componentsSeparatedByString:@"\n"];
                CGFloat LiuBaiGaoDu = 5 + askas.count * 15;
                if(ii == 0){
                    return LiuBaiGaoDu;
                }else{
                    return askas.count * 15;
                }
            }
        }
        
    }
    
    //------------------------------工具箱------------------------------//
    else if(MyMem == 2){
        return 20;
    }
    //------------------------------自定义------------------------------//
    else if(MyMem == 3){
        return 20;
    }
    else  if(MyMem == 4){
        return 20;
        
    }
    return 15;
}

//每个分组下边预留的空白高度
+ (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}

+ (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   
    NSString *headerLabel;
    if(MyMem == 1){
    for (int ii=0; ii<zhugongneng.count; ii++) {
        if (section==ii){
            headerLabel = [[zhugongneng[ii] objectForKey:@"说明"] stringByReplacingOccurrencesOfString:@"br" withString:@"\n"];
        }
    }
    }
    
    //------------------------------工具箱------------------------------//
    else if(MyMem == 2){
//
//        if (section == 0)
//            headerLabel = @"内购破解「破解部分游戏内购」";
//
//        else if (section == 1)
//        headerLabel = @"广告加速「对部分激励视频加速跳过」";
//
//        else if (section == 2)
//            headerLabel = @"游戏变速「对部分游戏进行变速」";
    }else if(MyMem == 3){
        
//       if (section == 0)
//           headerLabel = @"广告加速「对部分激励视频加速跳过」";
//
//        else if (section == 1)
//           headerLabel = @"游戏变速「对部分游戏进行变速」";

    }
    else if(MyMem == 4){
  
        if (section == 0)
                  headerLabel = @"存档功能「仅支持部分单机游戏过」";
    }
    return headerLabel;
    
}

+ (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
//    if (section == zhugongneng.count - 1){
//        NSString *copyright = @"© 2022 Copyright QQ1244795065.";
//        return copyright;
//    }
    return nil;
}

+ (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section

{
    
    view.tintColor = [UIColor whiteColor];
    
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.textAlignment=NSTextAlignmentCenter;
    
    header.textLabel.font = [UIFont boldSystemFontOfSize:12];
    
}

//每个分组下对应的tableView高度
+ (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40;
}

//返回每一行Cell的代理方法
+ (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    UIView *footSpinnerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 60.0f)];

    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(130.0f, 0.0f, 60.0f, 60.0f)];
    activity.color = [UIColor redColor];
    [activity startAnimating];//启动有刷新图标的view
    footSpinnerView.backgroundColor = [UIColor grayColor];
    [footSpinnerView addSubview:activity];
     
     //设置footerview
//     self.myTableView.tableFooterView = footSpinnerView;
    
    
    
    // 1 初始化Cell
    // 1.1 设置Cell的重用标识
    static NSString *ID = @"cell";
    // 1.2 去缓存池中取Cell
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    // 1.3 若取不到便创建一个带重用标识的Cell
    if (cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ID];
        //UITableViewCellStyleSubtitle // 带小标题
        //UITableViewCellStyleDefault
    }else//当页面拉动的时候 当cell存在并且最后一个存在 把它进行删除就出来一个独特的cell我们在进行数据配置即可避免
    {
        while ([cell.contentView.subviews lastObject] != nil) {
            [(UIView *)[cell.contentView.subviews lastObject] removeFromSuperview];
        }
    }
    cell.textLabel.textColor = [UIColor colorWithRed:0/255.0f green:191/255.0f blue:255/255.0f alpha:1.0f];
   
    cell.textLabel.font = [UIFont boldSystemFontOfSize:13];
    

    
    UISwitch* switchView = [[UISwitch alloc]init];
    UIButton *btn = nil;
    CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
    CGRect rect = [tableView convertRect:rectInTableView toView:[tableView superview]];
    if([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height){
        btn = [[UIButton alloc] initWithFrame:CGRectMake(rect.size.width-190, 5, 60, 30)];
    }else if([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height){
        btn = [[UIButton alloc] initWithFrame:CGRectMake(rect.size.width - 110, 5, 60, 30)];
    }
  


  
    if(MyMem == 1){
        
        if (indexPath.section==0){
            cell.textLabel.text = @"检查游戏版本";
            //设置Cell右边的小箭头
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
//            [switchView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"NNGGNNGG"] animated:YES];
            [switchView addTarget:self
                           action:@selector(jcbb)
                 forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchView;
        
        }
   
}else if(MyMem == 2){
 
        if (indexPath.section==0){
            cell.textLabel.text = @"内购破解和iGameGod去广告";
            //设置Cell右边的小箭头
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [switchView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"NNGGNNGG"] animated:YES];
            [switchView addTarget:self
                           action:@selector(NeiGouButton:)
                 forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchView;
        
        }else if (indexPath.section==2){
            if (indexPath.row == 0){
                cell.textLabel.text = @"游戏变速";
                //设置Cell右边的小箭头
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                [switchView setOn:[ImgTool share].games animated:YES];
                [switchView addTarget:self
                               action:@selector(GameSpeedButton:)
                     forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = switchView;
                
            }
            if (indexPath.row == 1){
                CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
                CGRect rect = [tableView convertRect:rectInTableView toView:[tableView superview]];
                UISlider *slider = nil;
                if([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height){
                    slider = [[UISlider alloc] initWithFrame:CGRectMake(15, 0, rect.size.width - 100, 40)];
                    BianSuTitle = [[UILabel alloc] initWithFrame:CGRectMake(rect.size.width - 100, 0, 100, 40)];
                }else if([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height){
                    slider = [[UISlider alloc] initWithFrame:CGRectMake(15, 0, rect.size.width - 90, 40)];
                    BianSuTitle = [[UILabel alloc] initWithFrame:CGRectMake(rect.size.width - 90, 0, 90, 40)];
                }
                /// 属性配置
                // minimumValue  : 当值可以改变时，滑块可以滑动到最小位置的值，默认为0.0
                slider.minimumValue = -50;
                // maximumValue : 当值可以改变时，滑块可以滑动到最大位置的值，默认为1.0
                slider.maximumValue = 50;
                // 当前值，这个值是介于滑块的最大值和最小值之间的，如果没有设置边界值，默认为0-1；
                slider.value = [ImgTool share].num;
                // continuous : 如果设置YES，在拖动滑块的任何时候，滑块的值都会改变。默认设置为YES
                [slider setContinuous:YES];
                [slider addTarget:self action:@selector(GameSpeed:) forControlEvents:UIControlEventValueChanged];
                [cell.contentView addSubview:slider];
                slider.vd_trackHeight = 5.0f;
                
                BianSuTitle.text = @"当前变速";
                BianSuTitle.numberOfLines = 0;
                BianSuTitle.lineBreakMode = NSLineBreakByCharWrapping;
                BianSuTitle.textAlignment = NSTextAlignmentCenter;
                BianSuTitle.font = [UIFont boldSystemFontOfSize:12];
                BianSuTitle.textColor = [UIColor colorWithRed:128/255.0f green:128/255.0f blue:128/255.0f alpha:1.0f];
                [cell.contentView addSubview:BianSuTitle];
            }
        }else if (indexPath.section==1){
            if (indexPath.row == 0){
                cell.textLabel.text = @"广告加速";
                //设置Cell右边的小箭头
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                [switchView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"AADDAADD"] animated:YES];
                [switchView addTarget:self
                               action:@selector(AdSpeedButton:)
                     forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = switchView;
            }
            if (indexPath.row == 1){
                CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
                CGRect rect = [tableView convertRect:rectInTableView toView:[tableView superview]];
                UISlider *slider1 = nil;
                if([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height){
                    slider1 = [[UISlider alloc] initWithFrame:CGRectMake(15, 0, rect.size.width - 100, 40)];
                    AdTitle = [[UILabel alloc] initWithFrame:CGRectMake(rect.size.width - 100, 0, 100, 40)];
                }else if([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height){
                    slider1 = [[UISlider alloc] initWithFrame:CGRectMake(15, 0, rect.size.width - 90, 40)];
                    AdTitle = [[UILabel alloc] initWithFrame:CGRectMake(rect.size.width - 90, 0, 90, 40)];
                }
                /// 属性配置
                // minimumValue  : 当值可以改变时，滑块可以滑动到最小位置的值，默认为0.0
                slider1.minimumValue = 1;
                // maximumValue : 当值可以改变时，滑块可以滑动到最大位置的值，默认为1.0
                slider1.maximumValue = 100;
                // 当前值，这个值是介于滑块的最大值和最小值之间的，如果没有设置边界值，默认为0-1；
                slider1.value = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AADDssppeedd"] intValue];
                // continuous : 如果设置YES，在拖动滑块的任何时候，滑块的值都会改变。默认设置为YES
                [slider1 setContinuous:YES];
                [slider1 addTarget:self action:@selector(AdSpeed:) forControlEvents:UIControlEventValueChanged];
                [cell.contentView addSubview:slider1];
                slider1.vd_trackHeight = 5.0f;
                
                AdTitle.text = @"当前变速";
                AdTitle.numberOfLines = 0;
                AdTitle.lineBreakMode = NSLineBreakByCharWrapping;
                AdTitle.textAlignment = NSTextAlignmentCenter;
                AdTitle.font = [UIFont boldSystemFontOfSize:12];
                AdTitle.textColor = [UIColor colorWithRed:128/255.0f green:128/255.0f blue:128/255.0f alpha:1.0f];
                [cell.contentView addSubview:AdTitle];
            }
        }
    
    //------------------------------自定义------------------------------//
}else if(MyMem == 3){
    
   if (indexPath.section==1){
        if (indexPath.row == 0){
            cell.textLabel.text = @"游戏变速「对部分游戏进行变速」";
            //设置Cell右边的小箭头
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [switchView setOn:[ImgTool share].games animated:YES];
            [switchView addTarget:self
                           action:@selector(GameSpeedButton:)
                 forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchView;
        }
        if (indexPath.row == 1){
            CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
            CGRect rect = [tableView convertRect:rectInTableView toView:[tableView superview]];
            UISlider *slider = nil;
            if([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height){
                slider = [[UISlider alloc] initWithFrame:CGRectMake(15, 0, rect.size.width - 100, 40)];
                BianSuTitle = [[UILabel alloc] initWithFrame:CGRectMake(rect.size.width - 100, 0, 100, 40)];
            }else if([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height){
                slider = [[UISlider alloc] initWithFrame:CGRectMake(15, 0, rect.size.width - 90, 40)];
                BianSuTitle = [[UILabel alloc] initWithFrame:CGRectMake(rect.size.width - 90, 0, 90, 40)];
            }
            /// 属性配置
            // minimumValue  : 当值可以改变时，滑块可以滑动到最小位置的值，默认为0.0
            slider.minimumValue = -50;
            // maximumValue : 当值可以改变时，滑块可以滑动到最大位置的值，默认为1.0
            slider.maximumValue = 50;
            // 当前值，这个值是介于滑块的最大值和最小值之间的，如果没有设置边界值，默认为0-1；
            slider.value = [ImgTool share].num;
            // continuous : 如果设置YES，在拖动滑块的任何时候，滑块的值都会改变。默认设置为YES
            [slider setContinuous:YES];
            [slider addTarget:self action:@selector(GameSpeed:) forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:slider];
            slider.vd_trackHeight = 5.0f;
            
            BianSuTitle.text = @"当前变速";
            BianSuTitle.numberOfLines = 0;
            BianSuTitle.lineBreakMode = NSLineBreakByCharWrapping;
            BianSuTitle.textAlignment = NSTextAlignmentCenter;
            BianSuTitle.font = [UIFont boldSystemFontOfSize:12];
            BianSuTitle.textColor = [UIColor colorWithRed:128/255.0f green:128/255.0f blue:128/255.0f alpha:1.0f];
            [cell.contentView addSubview:BianSuTitle];
        }
    }else if (indexPath.section==0){
        if (indexPath.row == 0){
            cell.textLabel.text = @"广告加速「对部分激励视频加速」";
            //设置Cell右边的小箭头
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [switchView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"AADDAADD"] animated:YES];
            [switchView addTarget:self
                           action:@selector(AdSpeedButton:)
                 forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchView;
        }
        if (indexPath.row == 1){
            CGRect rectInTableView = [tableView rectForRowAtIndexPath:indexPath];
            CGRect rect = [tableView convertRect:rectInTableView toView:[tableView superview]];
            UISlider *slider1 = nil;
            if([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height){
                slider1 = [[UISlider alloc] initWithFrame:CGRectMake(15, 0, rect.size.width - 100, 40)];
                AdTitle = [[UILabel alloc] initWithFrame:CGRectMake(rect.size.width - 100, 0, 100, 40)];
            }else if([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height){
                slider1 = [[UISlider alloc] initWithFrame:CGRectMake(15, 0, rect.size.width - 90, 40)];
                AdTitle = [[UILabel alloc] initWithFrame:CGRectMake(rect.size.width - 90, 0, 90, 40)];
            }
            /// 属性配置
            // minimumValue  : 当值可以改变时，滑块可以滑动到最小位置的值，默认为0.0
            slider1.minimumValue = 1;
            // maximumValue : 当值可以改变时，滑块可以滑动到最大位置的值，默认为1.0
            slider1.maximumValue = 100;
            // 当前值，这个值是介于滑块的最大值和最小值之间的，如果没有设置边界值，默认为0-1；
            slider1.value = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AADDssppeedd"] intValue];
            // continuous : 如果设置YES，在拖动滑块的任何时候，滑块的值都会改变。默认设置为YES
            [slider1 setContinuous:YES];
            [slider1 addTarget:self action:@selector(AdSpeed:) forControlEvents:UIControlEventValueChanged];
            [cell.contentView addSubview:slider1];
            slider1.vd_trackHeight = 5.0f;
            
            AdTitle.text = @"当前变速";
            AdTitle.numberOfLines = 0;
            AdTitle.lineBreakMode = NSLineBreakByCharWrapping;
            AdTitle.textAlignment = NSTextAlignmentCenter;
            AdTitle.font = [UIFont boldSystemFontOfSize:12];
            AdTitle.textColor = [UIColor colorWithRed:128/255.0f green:128/255.0f blue:128/255.0f alpha:1.0f];
            [cell.contentView addSubview:AdTitle];
        }
    }

//------------------------------自定义------------------------------//
}else
    if(MyMem == 4){
        
        
         if (indexPath.section==0){
            if (indexPath.row == 0){
                cell.textLabel.text = @"备份游戏存档";
                btn.layer.cornerRadius = 15.0;//2.0是圆角的弧度，根据需求自己更改
                [btn setTitle:@"开启" forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];//p1颜色
                btn.backgroundColor = [UIColor blueColor];//框里面白色
                btn.layer.borderColor = [[UIColor whiteColor] CGColor];//边框颜色
                btn.layer.borderWidth = 1.95f;//边框大小
                [btn.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
                [btn addTarget:self action:@selector(beifen) forControlEvents:UIControlEventTouchUpInside];
//                [cell.contentView addSubview:btn];
                cell.accessoryView = btn;
           
                    // 创建点击手势
                    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beifen)];
                    [cell addGestureRecognizer:tapGesture];
         
               
            }  if (indexPath.row == 1){
                cell.textLabel.text = @"恢复游戏存档";
                btn.layer.cornerRadius = 15.0;//2.0是圆角的弧度，根据需求自己更改
                [btn setTitle:@"开启" forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];//p1颜色
                btn.backgroundColor = [UIColor blueColor];//框里面白色
                btn.layer.borderColor = [[UIColor whiteColor] CGColor];//边框颜色
                btn.layer.borderWidth = 1.95f;//边框大小
                [btn.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
                [btn addTarget:self action:@selector(huifu) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = btn;
            }
            if (indexPath.row == 2){
                cell.textLabel.text = @"清除游戏数据";
                btn.layer.cornerRadius = 15.0;//2.0是圆角的弧度，根据需求自己更改
                [btn setTitle:@"开启" forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];//p1颜色
                btn.backgroundColor = [UIColor blueColor];//框里面白色
                btn.layer.borderColor = [[UIColor whiteColor] CGColor];//边框颜色
                btn.layer.borderWidth = 1.95f;//边框大小
                [btn.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
                [btn addTarget:self action:@selector(qingchu) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = btn;
            }
            
            if (indexPath.row == 3){
                cell.textLabel.text = @"清除授权记录";
                btn.layer.cornerRadius = 15.0;//2.0是圆角的弧度，根据需求自己更改
                [btn setTitle:@"开启" forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];//p1颜色
                btn.backgroundColor = [UIColor blueColor];//框里面白色
                btn.layer.borderColor = [[UIColor whiteColor] CGColor];//边框颜色
                btn.layer.borderWidth = 1.95f;//边框大小
                [btn.titleLabel setFont:[UIFont systemFontOfSize:15]];//字体大小
                [btn addTarget:self action:@selector(yichu) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = btn;
            }
        
        }
        //------------------------------工具箱------------------------------//
    }
    return cell;
}

+ (void)NeiGouButton:(UISwitch *)NeiGouswi{
    if(NeiGouswi.isOn){
        [[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"NNGG"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NNGGNNGG"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [ImgTool share].NeiGou = 1;
    }else{
        [[NSUserDefaults standardUserDefaults] setValue:@"0" forKey:@"NNGG"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NNGGNNGG"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [ImgTool share].NeiGou = 0;
    }
}

+ (void)AdSpeedButton:(UISwitch *)AdSpeedswi{
    if(AdSpeedswi.isOn){
        [[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"AADD"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AADDAADD"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [ImgTool share].ADSpeed = 1;
    }else{
        [[NSUserDefaults standardUserDefaults] setValue:@"0" forKey:@"AADD"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"AADDAADD"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [ImgTool share].ADSpeed = 0;
    }
}

+ (void)GameSpeedButton:(UISwitch *)GameSpeedwi{
    if(GameSpeedwi.isOn){
        [ImgTool share].gamespeedeed = 1;
        [ImgTool share].games = YES;
        if ([ImgTool share].num >= 0) {
            [ImgTool share].multiple = [ImgTool share].num+1.0;
        }else{
            [ImgTool share].multiple = -(1.0/([ImgTool share].num-1.0));
        }
    }else{
        [ImgTool share].games = NO;
        [ImgTool share].gamespeedeed = 0;
        CGFloat l = 0;
        if (l >= 0) {
            [ImgTool share].multiple = l+1.0;
        }else{
            [ImgTool share].multiple = -(1.0/(l-1.0));
        }
    }
}

+ (void)GameSpeed:(UISlider *)slider
{
    BianSuTitle.text = [NSString stringWithFormat:@"%.1f倍",slider.value];
    [ImgTool share].num = slider.value;
    if([ImgTool share].gamespeedeed == 1){
        if ([ImgTool share].num >= 0) {
            [ImgTool share].multiple = [ImgTool share].num+1.0;
        }else{
            [ImgTool share].multiple = -(1.0/([ImgTool share].num-1.0));
        }
    }
}

+ (void)AdSpeed:(UISlider *)slider1
{
    AdTitle.text = [NSString stringWithFormat:@"%.1f倍",slider1.value];
    [ImgTool share].ADBiansu = slider1.value;
    [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%.1f",slider1.value] forKey:@"AADDssppeedd"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (NSString *)getSystemDates{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_Hans_CN"];
    dateFormatter.calendar = [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
    [dateFormatter setDateFormat:@"yyyy-MM-dd#HH:mm:ss"];
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    return dateStr;
}

+ (void)cellBtnClicked:(id)sender event:(id)event {
    
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [generator impactOccurred];
    
    NSSet *touches =[event allTouches];
    
    UITouch *touch =[touches anyObject];
    
    CGPoint currentTouchPosition = [touch locationInView:personalTableView];
    
    NSIndexPath *indexPath= [personalTableView indexPathForRowAtPoint:currentTouchPosition];
    
    if (indexPath!= nil) {
        dataSource = [zhugongneng[indexPath.section] objectForKey:@"gongneng"];//子菜单
        NSDictionary *zhigongneng =dataSource[indexPath.row];
        NSString *mc =[zhigongneng objectForKey:@"名称"];
        NSString *ss =[zhigongneng objectForKey:@"搜索"];
        NSString *lh =[zhigongneng objectForKey:@"联合"];
        NSString *jq =[zhigongneng objectForKey:@"精确"];
        NSString *xg =[zhigongneng objectForKey:@"修改"];
        NSString *srksm =[zhigongneng objectForKey:@"输入框说明"];
        
        NSString *自定义0 = [NSString stringWithFormat:@"%@##%@##%@##%@",ss,lh,jq,xg];
        
        if([mc containsString:@"数据"]||[mc containsString:@"存档"] ||[mc containsString:@"解说"]||[mc containsString:@"功能"]||[mc containsString:@"特殊"]){
            [[PubgLoad alloc]loadddd];
        }
        else
        {
            if([zhigongneng objectForKey:@"联锁修改"]){
                NSArray *联锁 = [zhigongneng objectForKey:@"联锁修改"];
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    for(int ls = 0; ls < 联锁.count; ls++){
                        NSDictionary *zhigongneng =联锁[ls];
                        NSArray *修改0 =[[zhigongneng objectForKey:@"修改"] componentsSeparatedByString:@";"];
                        NSArray *判断条件0 = [zhigongneng objectForKey:@"判断条件"] ? [[zhigongneng objectForKey:@"判断条件"] componentsSeparatedByString:@";"] : nil;
                        NSArray *锁定0 =[zhigongneng objectForKey:@"锁定数值"] ? [[zhigongneng objectForKey:@"锁定数值"] componentsSeparatedByString:@","] : [@"0,0,0" componentsSeparatedByString:@","];
                        BOOL 锁定 = [锁定0[0]intValue] == 1 ? YES : NO;
                        if([锁定0[2] intValue] == 1){
                            取消冻结 = YES;
                            循环冻结 = nil;
                        }
                        
                        NSString *sss = [zhigongneng objectForKey:@"搜索"];
                        NSString *lll = [zhigongneng objectForKey:@"联合"] ? [zhigongneng objectForKey:@"联合"] : nil;
                        NSString *jjj = [zhigongneng objectForKey:@"精确"] ? [zhigongneng objectForKey:@"精确"] : nil;
                        vector<void *> results = JieGuo(sss,lll,jjj);
                        for(int i =0;i<results.size();i++){
                            void *add = results[i];
                            //a类型 b地址 c偏移位数 d判断类型 e判断数值
                            NSString *addstr = [NSString stringWithFormat:@"%p",add];
                            if(判断条件0){
                                for(int a = 0; a<判断条件0.count;a++){
                                    NSArray *判断条件 =[判断条件0[a] componentsSeparatedByString:@","];
                                    if(判断条件.count == 4 ? Szpd(判断条件[0],addstr,判断条件[1],判断条件[2],判断条件[3]) : Wzpd(addstr,判断条件[0])){
                                        if(a == 判断条件0.count-1){
                                            for(int xg = 0;xg<修改0.count;xg++){
                                                NSArray *修改 =[修改0[xg] componentsSeparatedByString:@","];
                                                Xg(修改[0],修改[1],addstr,修改[2],锁定);
                                            }
                                        }
                                    }else{
                                        break;
                                    }
                                }
                            }else{
                                for(int xg = 0;xg<修改0.count;xg++){
                                    NSArray *修改 =[修改0[xg] componentsSeparatedByString:@","];
                                    Xg(修改[0],修改[1],addstr,修改[2],锁定);
                                }
                            }
                        }
                    }
                });
                [jianghu showMessage:[NSString stringWithFormat:@"%@开启成功",mc] duration:3];
            }else if([自定义0 containsString:@"自定义"]){
                UIAlertController *Daoru = [UIAlertController alertControllerWithTitle:@"KKONG" message:srksm preferredStyle:UIAlertControllerStyleAlert];
                
                [Daoru addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                    UITextField * firstKeywordTF = [[UITextField alloc]init];
                    
                    NSArray * textFieldArr = @[firstKeywordTF];
                    
                    textFieldArr = Daoru.textFields;
                    
                    UITextField * tf1 = Daoru.textFields[0];
                    
                    if(tf1.text.length != 0){
                        NSString *自定义1= [自定义0 stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"自定义"] withString:tf1.text];
                        NSArray *自定义 =[自定义1 componentsSeparatedByString:@"##"];
                        NSArray *修改0 =[自定义[3] componentsSeparatedByString:@";"];
                        NSArray *判断条件0 = [zhigongneng objectForKey:@"判断条件"] ? [[zhigongneng objectForKey:@"判断条件"] componentsSeparatedByString:@";"] : nil;
                        NSArray *锁定0 =[zhigongneng objectForKey:@"锁定数值"] ? [[zhigongneng objectForKey:@"锁定数值"] componentsSeparatedByString:@","] : [@"0,0,0" componentsSeparatedByString:@","];
                        BOOL 锁定 = [锁定0[0] intValue] == 1 ? YES : NO;
                        
                        if([锁定0[2] intValue] == 1){
                            取消冻结 = YES;
                            循环冻结 = nil;
                        }
                        
                        NSString *lll = nil;
                        NSString *jjj = nil;
                        if([自定义[1] containsString:@"0x"])
                        {
                            lll = 自定义[1];
                        }
                        if([自定义[2] containsString:@"0x"])
                        {
                            jjj = 自定义[2];
                        }
                        NSString *sss = 自定义[0];
                        dispatch_async(dispatch_get_global_queue(0, 0), ^{
                            vector<void *> results = JieGuo(sss,lll,jjj);
                            for(int i =0;i<results.size();i++){
                                void *add = results[i];
                                //a类型 b地址 c偏移位数 d判断类型 e判断数值
                                NSString *addstr = [NSString stringWithFormat:@"%p",add];
                                if(判断条件0){
                                    for(int a = 0; a<判断条件0.count;a++){
                                        NSArray *判断条件 =[判断条件0[a] componentsSeparatedByString:@","];
                                        if(判断条件.count == 4 ? Szpd(判断条件[0],addstr,判断条件[1],判断条件[2],判断条件[3]) : Wzpd(addstr,判断条件[0])){
                                            if(a == 判断条件0.count-1){
                                                for(int xg = 0;xg<修改0.count;xg++){
                                                    NSArray *修改 =[修改0[xg] componentsSeparatedByString:@","];
                                                    Xg(修改[0],修改[1],addstr,修改[2],锁定);
                                                }
                                            }
                                        }else{
                                            break;
                                        }
                                    }
                                }else{
                                    for(int xg = 0;xg<修改0.count;xg++){
                                        NSArray *修改 =[修改0[xg] componentsSeparatedByString:@","];
                                        Xg(修改[0],修改[1],addstr,修改[2],锁定);
                                    }
                                }
                            }
                        });
                        [jianghu showMessage:[NSString stringWithFormat:@"%@开启成功",mc] duration:3];
                    }
                }]];
                
                
                [Daoru addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                }]];
                
                [Daoru addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    
                }];
                
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:Daoru animated:true completion:nil];
                
            }else{
                NSArray *修改0 =[[zhigongneng objectForKey:@"修改"] componentsSeparatedByString:@";"];
                NSArray *判断条件0 = [zhigongneng objectForKey:@"判断条件"] ? [[zhigongneng objectForKey:@"判断条件"] componentsSeparatedByString:@";"] : nil;
                NSArray *锁定0 =[zhigongneng objectForKey:@"锁定数值"] ? [[zhigongneng objectForKey:@"锁定数值"] componentsSeparatedByString:@","] : [@"0,0,0" componentsSeparatedByString:@","];
                BOOL 锁定 = [锁定0[0] intValue] == 1 ? YES : NO;
                
                if([锁定0[2] intValue] == 1){
                    取消冻结 = YES;
                    循环冻结 = nil;
                }
                
                NSString *sss = [zhigongneng objectForKey:@"搜索"];
                NSString *lll = [zhigongneng objectForKey:@"联合"] ? [zhigongneng objectForKey:@"联合"] : nil;
                NSString *jjj = [zhigongneng objectForKey:@"精确"] ? [zhigongneng objectForKey:@"精确"] : nil;
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    vector<void *> results = JieGuo(sss,lll,jjj);
                    for(int i =0;i<results.size();i++){
                        void *add = results[i];
                        //a类型 b地址 c偏移位数 d判断类型 e判断数值
                        NSString *addstr = [NSString stringWithFormat:@"%p",add];
                        if(判断条件0){
                            for(int a = 0; a<判断条件0.count;a++){
                                NSArray *判断条件 =[判断条件0[a] componentsSeparatedByString:@","];
                                if(判断条件.count == 4 ? Szpd(判断条件[0],addstr,判断条件[1],判断条件[2],判断条件[3]) : Wzpd(addstr,判断条件[0])){
                                    if(a == 判断条件0.count-1){
                                        for(int xg = 0;xg<修改0.count;xg++){
                                            NSArray *修改 =[修改0[xg] componentsSeparatedByString:@","];
                                            Xg(修改[0],修改[1],addstr,修改[2],锁定);
                                        }
                                    }
                                }else{
                                    break;
                                }
                            }
                        }else{
                            for(int xg = 0;xg<修改0.count;xg++){
                                NSArray *修改 =[修改0[xg] componentsSeparatedByString:@","];
                                Xg(修改[0],修改[1],addstr,修改[2],锁定);
                            }
                        }
                    }
                });
                [jianghu showMessage:[NSString stringWithFormat:@"%@开启成功",mc] duration:3];
            }
            //[jianghu showMessage:@"功能开启完毕" duration:3];
            //[jianghu MyTitle:[NSString stringWithFormat:@"%@开启成功",mc]];
        }
    }
}
//1.接收到服务器的响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSLog(@"%s", __func__);
    
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
    
    // void (^)(NSURLSessionResponseDisposition)
}
//2.接收到服务器的数据（可能会被调用多次）
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSLog(@"%s", __func__);
}
//3.请求成功或者失败（如果失败，error有值）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"%s", __func__);
}

+ (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [personalTableView deselectRowAtIndexPath:[personalTableView indexPathForSelectedRow] animated:YES];

}

+ (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 设置cell的背景色为透明，如果不设置这个的话，则原来的背景色不会被覆盖
    cell.backgroundColor = UIColor.clearColor;
    
    // 圆角弧度半径
    CGFloat cornerRadius = 10.0f;
    
    // 创建一个shapeLayer
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    // 显示选中
    CAShapeLayer *backgroundLayer = [[CAShapeLayer alloc] init];
    //   创建一个可变的图像Path句柄，该路径用于保存绘图信息
    CGMutablePathRef pathRef = CGPathCreateMutable();
    //   获取cell的size
    //    第一个参数,是整个 cell 的 bounds, 第二个参数是距左右两端的距离,第三个参数是距上下两端的距离
    CGRect bounds = CGRectInset(cell.bounds, 0, 0);
    
    //      CGRectGetMinY：返回对象顶点坐标
    //      CGRectGetMaxY：返回对象底点坐标
    //      CGRectGetMinX：返回对象左边缘坐标
    //      CGRectGetMaxX：返回对象右边缘坐标
    //      CGRectGetMidX: 返回对象中心点的X坐标
    //      CGRectGetMidY: 返回对象中心点的Y坐标
    //      这里要判断分组列表中的第一行，每组section的第一行，每组section的中间行
    NSInteger rows = [tableView numberOfRowsInSection:indexPath.section];
    BOOL addLine = NO;
    if (rows == 1) {
        // 初始起点为cell的左侧中间坐标
        CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMidY(bounds));
        // 起始坐标为左下角，设为p，（CGRectGetMinX(bounds), CGRectGetMinY(bounds)）为左上角的点，设为p1(x1,y1)，(CGRectGetMidX(bounds), CGRectGetMinY(bounds))为顶部中点的点，设为p2(x2,y2)。然后连接p1和p2为一条直线l1，连接初始点p到p1成一条直线l，则在两条直线相交处绘制弧度为r的圆角。
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
        
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
        
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMinX(bounds), CGRectGetMaxY(bounds), cornerRadius);
        
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMinX(bounds), CGRectGetMidY(bounds), cornerRadius);
        // 终点坐标为右下角坐标点，把绘图信息都放到路径中去,根据这些路径就构成了一块区域了
        CGPathAddLineToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMidY(bounds));
    } else if (indexPath.row == 0) {
        // 初始起点为cell的左下角坐标
        CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
        // 起始坐标为左下角，设为p，（CGRectGetMinX(bounds), CGRectGetMinY(bounds)）为左上角的点，设为p1(x1,y1)，(CGRectGetMidX(bounds), CGRectGetMinY(bounds))为顶部中点的点，设为p2(x2,y2)。然后连接p1和p2为一条直线l1，连接初始点p到p1成一条直线l，则在两条直线相交处绘制弧度为r的圆角。
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
        
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
        // 终点坐标为右下角坐标点，把绘图信息都放到路径中去,根据这些路径就构成了一块区域了
        CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
        addLine = YES;
    } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
        // 初始起点为cell的左上角坐标
        CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
        
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius);
        
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
        // 添加一条直线，终点坐标为右下角坐标点并放到路径中去
        CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
    } else {
        // 添加cell的rectangle信息到path中（不包括圆角）
        CGPathAddRect(pathRef, nil, bounds);
        addLine = YES;
    }
    
    // 把已经绘制好的可变图像路径赋值给图层，然后图层根据这图像path进行图像渲染render
    layer.path = pathRef;
    backgroundLayer.path = pathRef;
    
    // 注意：但凡通过Quartz2D中带有creat/copy/retain方法创建出来的值都必须要释放
    CFRelease(pathRef);
    
    // 按照shape layer的path填充颜色，类似于渲染render
    layer.fillColor = [UIColor whiteColor].CGColor;
    
    // view大小与cell一致
    UIView *roundView = [[UIView alloc] initWithFrame:bounds];
    
    // 添加自定义圆角后的图层到roundView中
    [roundView.layer insertSublayer:layer atIndex:0];
    roundView.backgroundColor = UIColor.clearColor;
    
    // cell的背景view
    cell.backgroundView = roundView;
    
    // 添加分割线
    if (addLine == YES) {
        
        CALayer *lineLayer = [[CALayer alloc] init];
        
        CGFloat lineHeight = (1.f / [UIScreen mainScreen].scale);
        
        lineLayer.frame = CGRectMake(18, bounds.size.height-lineHeight, bounds.size.width, lineHeight);
        
        lineLayer.backgroundColor = tableView.separatorColor.CGColor;
        
        [layer addSublayer:lineLayer];
        
    }
    
    // 以上方法存在缺陷当点击cell时还是出现cell方形效果，因此还需要添加以下方法
    // 如果你 cell 已经取消选中状态的话,那以下方法是不需要的.
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:bounds];
    backgroundLayer.fillColor = tableView.separatorColor.CGColor;
    [selectedBackgroundView.layer insertSublayer:backgroundLayer atIndex:0];
    selectedBackgroundView.backgroundColor = UIColor.clearColor;
    cell.selectedBackgroundView = selectedBackgroundView;
    
    
    
}
+ (void)showMessage:(NSString *)message duration:(NSTimeInterval)time
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        
        UIWindow * window = [UIApplication sharedApplication].keyWindow;
        UIView *showview =  [[UIView alloc]init];
        showview.backgroundColor = [UIColor blackColor];
        showview.frame = CGRectMake(1, 1, 1, 1);
        showview.alpha = 1.0f;
        showview.layer.cornerRadius = 5.0f;
        showview.layer.masksToBounds = YES;
        [window addSubview:showview];
        
        UILabel *label = [[UILabel alloc]init];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:15.f],
                                     NSParagraphStyleAttributeName:paragraphStyle.copy};
        
        CGSize labelSize = [message boundingRectWithSize:CGSizeMake(207, 999)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:attributes context:nil].size;
        
        label.frame = CGRectMake(10, 5, labelSize.width +20, labelSize.height);
        label.text = message;
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor blackColor];
        label.font = [UIFont boldSystemFontOfSize:15];
        [showview addSubview:label];
        
        showview.frame = CGRectMake((screenSize.width - labelSize.width - 20)/2,
                                    screenSize.height - 300,
                                    labelSize.width+40,
                                    labelSize.height+10);
        [UIView animateWithDuration:time animations:^{
            showview.alpha = 0;
        } completion:^(BOOL finished) {
            [showview removeFromSuperview];
        }];
    });
}
+ (void)beifen
{       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                       {
        [self 关闭菜单];
//    [NSObject xzdylib];
    [[daochucd alloc]backupasd];
});
}
+ (void)huifu
{
    [self 关闭菜单];
    
    [[YYYPicker alloc] addBtnAction];
}
+ (void)qingchu
{
    [self 菜单调整];
    [self 关闭菜单];
}
+ (void)yichu
{
    [[WX_NongShiFu123 alloc] deletekm];
    [self 关闭菜单];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}
+ (void)yuncd
{
    [[PubgLoad alloc] checkCloudSaveStatus];
    [self 关闭菜单];
}

+ (void)jcbb
{
    [NSObject checkbanben]; 
    [self 关闭菜单];
}





@end
