#import "SandboxBrowserVC.h"

@interface SandboxBrowserVC ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSString *> *files; // 当前显示文件列表
@property (nonatomic, strong) NSString *currentPath;
@property (nonatomic, strong) NSMutableArray<NSString *> *pathStack;
@property (nonatomic, strong) UISegmentedControl *segmentControl;

@end

@implementation SandboxBrowserVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    // 初始化路径栈
    self.pathStack = [NSMutableArray array];
    
    // 分区选择器
    self.segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Documents", @"Library"]];
    self.segmentControl.selectedSegmentIndex = 0;
    [self.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.segmentControl;
    
    // 左按钮返回上一级
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    // 右按钮关闭
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(close)];
    
    // 创建 tableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    // 添加右滑返回上一级手势
    UIScreenEdgePanGestureRecognizer *edgePan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)];
    edgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:edgePan];
    
    // 初始路径
    if (self.startPath) {
        [self loadPath:self.startPath];
    } else {
        [self loadPath:[self defaultPathForSegment:self.segmentControl.selectedSegmentIndex]];
    }
    
    // iOS 15+ 半屏支持下滑关闭
    if (@available(iOS 15.0, *)) {
        if (self.presentationController && [self.presentationController isKindOfClass:[UISheetPresentationController class]]) {
            UISheetPresentationController *sheet = (UISheetPresentationController *)self.presentationController;
            sheet.detents = @[
                [UISheetPresentationControllerDetent mediumDetent],
                [UISheetPresentationControllerDetent largeDetent]
            ];
            sheet.prefersGrabberVisible = YES;
            sheet.prefersScrollingExpandsWhenScrolledToEdge = YES;
        }
    }
}

#pragma mark - 分区切换
- (void)segmentChanged:(UISegmentedControl *)sender {
    [self.pathStack removeAllObjects];
    [self loadPath:[self defaultPathForSegment:sender.selectedSegmentIndex]];
}

- (NSString *)defaultPathForSegment:(NSInteger)index {
    if (index == 0) {
        return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    } else {
        return [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
    }
}

#pragma mark - 目录加载
- (void)loadPath:(NSString *)path {
    self.currentPath = path;
    NSError *error = nil;
    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    self.files = arr ? [arr mutableCopy] : [NSMutableArray array];
    [self.tableView reloadData];
    self.title = path.lastPathComponent;
}

#pragma mark - 返回上一级
- (void)goBack {
    if (self.pathStack.count > 0) {
        NSString *previousPath = [self.pathStack lastObject];
        [self.pathStack removeLastObject];
        [self loadPath:previousPath];
    }
}

#pragma mark - 关闭
- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 右滑返回手势
- (void)handleRightSwipe:(UIScreenEdgePanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self goBack];
    }
}

#pragma mark - UITableView DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"SandboxCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    
    NSString *file = self.files[indexPath.row];
    cell.textLabel.text = file;
    
    NSString *fullPath = [self.currentPath stringByAppendingPathComponent:file];
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
    cell.accessoryType = isDir ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *file = self.files[indexPath.row];
    NSString *fullPath = [self.currentPath stringByAppendingPathComponent:file];
    
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
    
    if (isDir) {
        [self.pathStack addObject:self.currentPath];
        [self loadPath:fullPath];
    } else {
        NSData *data = [NSData dataWithContentsOfFile:fullPath];
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:file message:content ?: @"无法显示内容" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"分享" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIActivityViewController *act = [[UIActivityViewController alloc] initWithActivityItems:@[fullPath] applicationActivities:nil];
            act.popoverPresentationController.sourceView = self.view;
            [self presentViewController:act animated:YES completion:nil];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - 左滑删除文件
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                               title:@"删除"
                                                                             handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        NSString *file = self.files[indexPath.row];
        NSString *fullPath = [self.currentPath stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
        [self.files removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        completionHandler(YES);
    }];
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
    return config;
}

@end
 
