#import "PopupMenuVC.h"
#import "../ZONCore/ZONMenuCoordinator.h"

// ZONCore is still a header-only group from the legacy target's perspective.
// Compile the coordinator implementation exactly once through this compatibility shell
// until ZONCore source files are explicitly represented by project.pbxproj.
#import "../ZONCore/ZONMenuCoordinator.m"

@interface PopupMenuVC ()
@property(nonatomic,strong) ZONMenuCoordinator *menuCoordinator;
@end

@implementation PopupMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.menuCoordinator = [[ZONMenuCoordinator alloc] initWithPresenter:self];
    [self.menuCoordinator viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.menuCoordinator viewDidAppear];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.menuCoordinator viewWillLayoutSubviews];
}

#pragma mark - Legacy selector passthrough

- (void)buildUI {
    [self.menuCoordinator buildUI];
}

- (void)relayoutSections {
    [self.menuCoordinator relayoutSections];
}

- (void)close {
    [self.menuCoordinator close];
}

- (void)adSwitchChanged:(UISwitch *)sw {
    [self.menuCoordinator adSwitchChanged:sw];
}

- (void)adSliderChanged:(UISlider *)slider {
    [self.menuCoordinator adSliderChanged:slider];
}

- (void)cardButtonTap:(UIButton *)sender {
    [self.menuCoordinator cardButtonTap:sender];
}

- (void)gridButtonTap:(UIButton *)sender {
    [self.menuCoordinator gridButtonTap:sender];
}

- (void)switchChanged:(UISwitch *)sw {
    [self.menuCoordinator switchChanged:sw];
}

@end
