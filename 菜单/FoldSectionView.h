#import <UIKit/UIKit.h>

@interface FoldSectionView : UIView

@property(nonatomic,strong) UIView *header;
@property(nonatomic,strong) UIView *contentView;

@property(nonatomic,assign) BOOL expanded;

@property(nonatomic,copy) void (^onToggle)(BOOL expanded);

@property (nonatomic, copy) NSString *stateKey;
 
- (instancetype)initWithTitle:(NSString *)title
                       detail:(NSString *)detail
                       status:(NSString *)status;

- (CGFloat)layoutAndGetHeight;
- (void)setStateKey:(NSString *)stateKey;
@end
