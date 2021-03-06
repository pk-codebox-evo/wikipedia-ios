#import "WMFFirstRandomViewController.h"
#import "MWKSite.h"
#import "WMFRandomArticleFetcher.h"
#import "Wikipedia-swift.h"
#import "MWKDataStore.h"
#import "SessionSingleton.h"
#import "MWKSearchResult.h"
#import "WMFRandomArticleViewController.h"
#import "UIViewController+WMFArticlePresentation.h"

@interface WMFFirstRandomViewController ()

@property (nonatomic, strong, nonnull) MWKSite* site;
@property (nonatomic, strong, nonnull) MWKDataStore* dataStore;

@end

@implementation WMFFirstRandomViewController

- (nonnull instancetype)initWithSite:(nonnull MWKSite*)site dataStore:(nonnull MWKDataStore*)dataStore {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.site = site;
        self.dataStore = dataStore;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    return [self initWithSite:[MWKSite siteWithLanguage:@"en"] dataStore:[SessionSingleton sharedInstance].dataStore];
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    return [self initWithNibName:nil bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    MWKSite *site = self.site;
    WMFRandomArticleFetcher *fetcher = [[WMFRandomArticleFetcher alloc] init];
    [fetcher fetchRandomArticleWithSite:self.site failure:^(NSError *error) {
        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    } success:^(MWKSearchResult* result) {
        MWKTitle* title = [site titleWithString:result.displayTitle];
        WMFRandomArticleViewController* randomArticleVC = [[WMFRandomArticleViewController alloc] initWithArticleTitle:title dataStore:self.dataStore];
        NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
        [viewControllers replaceObjectAtIndex:viewControllers.count - 1 withObject:randomArticleVC];
        [self.navigationController setViewControllers:viewControllers];
    }];
}

@end
