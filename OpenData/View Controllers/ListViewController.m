//
//  ListViewController.m
//  OpenData
//
//  Created by Michael Walker on 5/13/14.
//  Copyright (c) 2014 Lazer-Walker. All rights reserved.
//

#import "ListViewController.h"
#import "DataProcessor.h"
#import "MovementPath.h"
#import "Stop.h"
#import "UntrackedPeriod.h"

#import "TimedEvent.h"
#import "TimelineCell.h"

#import "StopTimelineCell.h"
#import "MovementPathTimelineCell.h"
#import "UntrackedPeriodTimelineCell.h"

#import "DayPresenter.h"

#import "FoursquareVenue.h"
#import "Venue.h"
#import "VenueListViewController.h"

@interface ListViewController ()
@property (strong, nonatomic) NSArray *data;
@property (nonatomic, strong) DayPresenter *presenter;
@end

@implementation ListViewController

- (id)initWithDaysAgo:(NSInteger)daysAgo {
    DayPresenter *presenter = [[DayPresenter alloc] initWithDaysAgo:daysAgo];
    return [self initWithPresenter:presenter];
}

- (id)initWithPresenter:(DayPresenter *)presenter {
    self = [super initWithStyle:UITableViewStylePlain];
    if (!self) return nil;

    self.presenter = presenter;
    [self.presenter addObserver:self forKeyPath:DayPresenterDataChangedKey options:0 context:nil];

    self.title = self.presenter.dayTitle;

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, self.tabBarController.tabBar.bounds.size.height, 0);

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Process" style:UIBarButtonItemStylePlain target:self action:@selector(reprocess)];

    [self.tableView registerClass:[StopTimelineCell class] forCellReuseIdentifier:[StopTimelineCell reuseIdentifier]];
    [self.tableView registerClass:[MovementPathTimelineCell class] forCellReuseIdentifier:[MovementPathTimelineCell reuseIdentifier]];
    [self.tableView registerClass:[UntrackedPeriodTimelineCell class] forCellReuseIdentifier:[UntrackedPeriodTimelineCell reuseIdentifier]];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    if ([keyPath isEqualToString:DayPresenterDataChangedKey]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - 
- (NSInteger)daysAgo {
    return self.presenter.daysAgo;
}

#pragma mark -
- (void)reprocess {
    DataProcessor *dataProcessor = [DataProcessor new];
    [dataProcessor reprocessData];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<TimedEvent> obj = [self.presenter eventForIndex:indexPath.row];
    Class cellClass = [self timelineCellClassForObject:obj];
    return [cellClass heightForTimedEvent:obj];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell<TimelineCell> *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    id<TimedEvent> obj = [self.presenter eventForIndex:indexPath.row];
    [cell setupWithTimedEvent:obj];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    Stop *stop = (Stop *)[self.presenter eventForIndex:indexPath.row];
    if (![stop isKindOfClass:Stop.class]) return;

    VenueListViewController *venueList = [[VenueListViewController alloc] initWithStop:stop];

    venueList.didTapCancelButtonBlock = ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    };

    venueList.didSelectVenueBlock = ^(Venue *venue) {
        [self dismissViewControllerAnimated:YES completion:nil];

        [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
            Venue *oldVenue = stop.venue;
            if (oldVenue && oldVenue.stops.count == 1) {
                [oldVenue MR_deleteEntity];
            }

            stop.venue = venue;
            stop.venueConfirmed = @(YES);

            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } completion:nil];
    };

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:venueList];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.presenter.numberOfEvents;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<TimedEvent> obj = [self.presenter eventForIndex:indexPath.row];
    NSString *cellIdentifier = [[self timelineCellClassForObject:obj] reuseIdentifier];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    return cell;
}

#pragma mark - Private
- (Class)timelineCellClassForObject:(id<TimedEvent>)obj {
    NSString *className = [NSString stringWithFormat:@"%@TimelineCell", NSStringFromClass(obj.class)];
    return NSClassFromString(className);
}

@end
