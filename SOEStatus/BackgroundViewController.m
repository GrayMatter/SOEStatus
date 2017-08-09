//
//  BackgroundViewController.m
//  SOEStatus
//
//  Created by Paul Lynch on 25/05/2013.
//  Copyright (c) 2013 P & L Systems. All rights reserved.
//

#import "BackgroundViewController.h"
#import "JBKenBurnsView.h"
#import "RootViewController.h"
#import "SOEGame.h"
#import "PhotoSearch.h"

NSString *PhotoSearchKeyConstant = @"FlickrSearchKey";

@interface BackgroundViewController ()

@property (nonatomic, strong) PhotoSearch *photoSearch;

@end

@implementation BackgroundViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)animateWithSearch:(NSString *)searchString transitionDuration:(float)duration loop:(BOOL)shouldLoop isLandscape:(BOOL)inLandscape {
    if (!self.photoSearch) self.photoSearch = [[PhotoSearch alloc] init];
    dispatch_queue_t task_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(task_queue, ^{
        [self.photoSearch photoSearch:searchString completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.photoSearch.photoURLs count]) {
                    [self.backgroundView animateWithImages:self.photoSearch.photoURLs transitionDuration:duration loop:shouldLoop isLandscape:inLandscape];
                } else {
                    // halt animations, if we're lucky
                    [self.backgroundView flush];
                }
            });
        }];
    });
}

- (void)gameChanged:(NSNotification *)notification {
    SOEGame *game = [[notification userInfo] objectForKey:@"game"];
    NSLog(@"%s %@", __PRETTY_FUNCTION__, game.name);
    [[NSUserDefaults standardUserDefaults] setObject:game.search forKey:PhotoSearchKeyConstant];
    if (game.search) {
        // statusBarOrientation is deprecated in 9.0 for UITrait*
        [self animateWithSearch:game.search transitionDuration:15.0 loop:YES isLandscape:UIInterfaceOrientationIsLandscape(self.interfaceOrientation)];
    }
}

- (IBAction)togglePopover:(id)sender {
    if (self.statusPopover.isPopoverVisible) {
        [self.statusPopover dismissPopoverAnimated:YES];
    } else {
        [self.statusPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameChanged:) name:SOEGameSelectedNotification object:nil];

    NSString *searchValue = [[NSUserDefaults standardUserDefaults] objectForKey:PhotoSearchKeyConstant];
    if (!searchValue) searchValue = @"daybreakgames";
    // statusBarOrientation is deprecated in 9.0 for UITrait*
    [self animateWithSearch:searchValue transitionDuration:15.0 loop:YES isLandscape:UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])];
    
    /*if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.statusButton = [[UIBarButtonItem alloc] initWithTitle:@"Status" style:UIBarButtonItemStylePlain target:self action:@selector(togglePopover:)];
        self.navigationItem.leftBarButtonItem = self.statusButton;
    }*/
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        RootViewController *rootVC = [[RootViewController alloc] init];
        UINavigationController *statusVC = [[UINavigationController alloc] initWithRootViewController:rootVC];
        self.statusPopover = [[UIPopoverController alloc] initWithContentViewController:statusVC];
        self.statusPopover.popoverContentSize = CGSizeMake(320.0, 440.0);
        
        // need to do this rather than call directly to allow rotation to landscape to happen first <shrug>
        [self performSelector:@selector(togglePopover:) withObject:self.statusButton afterDelay:0.0];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
