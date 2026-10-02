#import "SandboxBrowserVC.h"

static const unsigned long long ZONSandboxPreviewMaxBytes = 1024ULL * 1024ULL;

@interface SandboxBrowserVC ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSString *> *files;
@property (nonatomic, strong) NSString *currentPath;
@property (nonatomic, strong) NSMutableArray<NSString *> *pathStack;
@property (nonatomic, strong) UISegmentedControl *segmentControl;

@end

@implementation SandboxBrowserVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.pathStack = [NSMutableArray array];

    self.segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Documents", @"Library"]];
    self.segmentControl.selectedSegmentIndex = 0;
    [self.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.segmentControl;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(close)];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];

    UIScreenEdgePanGestureRecognizer *edgePan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(handleRightSwipe:)];
    edgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:edgePan];

    if (self.startPath.length > 0) {
        [self loadPath:self.startPath];
    } else {
        [self loadPath:[self defaultPathForSegment:self.segmentControl.selectedSegmentIndex]];
    }
}

#pragma mark - Helpers

- (void)presentError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"操作失败"
                                                                   message:message.length ? message : @"未知错误"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)isLikelyTextFileAtPath:(NSString *)path size:(unsigned long long)size {
    if (size > ZONSandboxPreviewMaxBytes) return NO;

    NSString *ext = path.pathExtension.lowercaseString;
    static NSSet<NSString *> *textExtensions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        textExtensions = [NSSet setWithArray:@[
            @"txt", @"log", @"json", @"xml", @"plist", @"strings", @"csv",
            @"md", @"ini", @"conf", @"cfg", @"yaml", @"yml", @"js", @"html",
            @"htm", @"css", @"lua", @"m", @"mm", @"h", @"c", @"cc", @"cpp"
        ]];
    });
    return ext.length == 0 || [textExtensions containsObject:ext];
}

#pragma mark - 分区切换

- (void)segmentChanged:(UISegmentedControl *)sender {
    [self.pathStack removeAllObjects];
    [self loadPath:[self defaultPathForSegment:sender.selectedSegmentIndex]];
}

- (NSString *)defaultPathForSegment:(NSInteger)index {
    if (index == 0) {
        return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    }
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
}

#pragma mark - 目录加载

- (void)loadPath:(NSString *)path {
    NSError *error = nil;
    NSArray<NSString *> *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if (!arr) {
        [self presentError:error.localizedDescription ?: @"目录读取失败"];
        return;
    }

    self.currentPath = path;
    NSArray<NSString *> *sorted = [arr sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    self.files = [sorted mutableCopy];
    [self.tableView reloadData];
    self.title = path.lastPathComponent;
}

#pragma mark - 返回上一级

- (void)goBack {
    if (self.pathStack.count == 0) return;

    NSString *previousPath = self.pathStack.lastObject;
    [self.pathStack removeLastObject];
    [self loadPath:previousPath];
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
    (void)tableView;
    (void)section;
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"SandboxCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }

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
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
    if (!exists) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self presentError:@"文件不存在或已被其他进程删除"];
        [self loadPath:self.currentPath];
        return;
    }

    if (isDir) {
        [self.pathStack addObject:self.currentPath];
        [self loadPath:fullPath];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    NSError *attributeError = nil;
    NSDictionary<NSFileAttributeKey, id> *attributes =
        [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&attributeError];
    unsigned long long fileSize = [attributes[NSFileSize] unsignedLongLongValue];

    NSString *content = nil;
    if (!attributeError && [self isLikelyTextFileAtPath:fullPath size:fileSize]) {
        NSError *readError = nil;
        content = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&readError];
        if (readError) content = nil;
    }

    NSString *message = content;
    if (!message.length) {
        if (attributeError) {
            message = attributeError.localizedDescription ?: @"无法读取文件信息";
        } else if (fileSize > ZONSandboxPreviewMaxBytes) {
            message = [NSString stringWithFormat:@"文件较大（%.2f MB），不在菜单内预览。可使用“分享”导出。",
                       (double)fileSize / (1024.0 * 1024.0)];
        } else {
            message = @"该文件不是可直接预览的 UTF-8 文本。可使用“分享”导出。";
        }
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:file
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"分享" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL]
                                                                              applicationActivities:nil];
        activity.popoverPresentationController.sourceView = self.view;
        activity.popoverPresentationController.sourceRect = self.view.bounds;
        [self presentViewController:activity animated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - 左滑删除文件

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    UIContextualAction *deleteAction =
        [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                title:@"删除"
                                              handler:^(__unused UIContextualAction *action,
                                                        __unused UIView *sourceView,
                                                        void (^completionHandler)(BOOL)) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || indexPath.row >= self.files.count) {
            completionHandler(NO);
            return;
        }

        NSString *file = self.files[indexPath.row];
        NSString *fullPath = [self.currentPath stringByAppendingPathComponent:file];
        NSError *error = nil;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
        if (!removed) {
            completionHandler(NO);
            [self presentError:error.localizedDescription ?: @"删除失败"];
            return;
        }

        [self.files removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        completionHandler(YES);
    }];

    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

@end
