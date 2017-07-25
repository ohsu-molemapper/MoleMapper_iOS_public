//
//  DashboardViewController.m
//  MoleMapper
//
//  Created by Dan Webster on 8/16/15.
// Copyright (c) 2016, OHSU. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//


#import "DashboardViewController.h"
#import "DashboardActivityCompletionCell.h"
#import "DashboardZoneDocumentationCell.h"
#import "DashBoardMeasurementCell.h"
#import "DashboardBiggestMoleCell.h"
#import "DashboardSizeOvertimeCell.h"
#import "DashboardModel.h"
#import "MoleViewController.h"
#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>

@interface DashboardViewController ()
@end

@implementation DashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _cellList = [[NSMutableArray alloc] init];
    [self setupCellList];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"moleMapperLogo"]];
    AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.context = ad.managedObjectContext;
    
    _refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:_refreshControl];
    [_refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    _isLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!_isLoaded)
    {
        [[DashboardModel sharedInstance] refreshContext];
        [self setupCellList];
        [self.tableView reloadData];
    }
    else _isLoaded = NO;
}

- (void)refreshTable {
    //TODO: refresh your data
    [[DashboardModel sharedInstance] refreshContext];
    [self setupCellList];
    [_refreshControl endRefreshing];
    [self.tableView reloadData];
    
    /*AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.context = ad.managedObjectContext;*/
}

-(void) setupCellList
{
    if ([_cellList count] > 0)
    {
        for (int i = 0; i < [_cellList count]; ++i)
        {
            id data = [_cellList objectAtIndex:0];
            if (data != nil) data = nil;
            else continue;
        }
        
        [_cellList removeAllObjects];
    }
    
    /* Removed 11/5/16 due to Swift incompatibility
    DashboardUVExposure *cell0_uvExposure = (DashboardUVExposure*)[_tableView dequeueReusableCellWithIdentifier:@"DashboardUVExposure"];
    
    cell0_uvExposure = nil;
    
    if (cell0_uvExposure == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardUVExposure" owner:self options:nil];
        cell0_uvExposure = [nib objectAtIndex:0];
    }
     */
    
    //DashBoardMeasurementCell
    DashBoardMeasurementCell *cell0_measures = (DashBoardMeasurementCell *)[_tableView dequeueReusableCellWithIdentifier:@"DashBoardMeasurementCell"];
    
    cell0_measures = nil;
    
    if (cell0_measures == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashBoardMeasurementCell" owner:self options:nil];
        cell0_measures = [nib objectAtIndex:0];
    }
    /////
    
    //DashboardBiggestMoleCell
    DashboardBiggestMoleCell *cell1_biggestMole = (DashboardBiggestMoleCell*)[_tableView dequeueReusableCellWithIdentifier:@"DashboardBiggestMoleCell"];
    
    cell1_biggestMole = nil;
    
    if (cell1_biggestMole == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardBiggestMoleCell" owner:self options:nil];
        cell1_biggestMole = [nib objectAtIndex:0];
    }
    /////
    
    //DashboardZoneDocumentationCell
    DashboardZoneDocumentationCell *cell2_zones = (DashboardZoneDocumentationCell *)[_tableView dequeueReusableCellWithIdentifier:@"DashboardZoneDocumentationCell"];
  
     
    cell2_zones = nil;
    
    if (cell2_zones == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardZoneDocumentationCell" owner:self options:nil];
        cell2_zones = [nib objectAtIndex:0];
    }
    /////
    
    
    //DashboardSizeOvertimeCell
    DashboardSizeOvertimeCell *cell3_sizeOverTime = (DashboardSizeOvertimeCell*)[_tableView dequeueReusableCellWithIdentifier:@"DashboardSizeOvertimeCell"];
    
    cell3_sizeOverTime = nil;
    
    if (cell3_sizeOverTime == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardSizeOvertimeCell" owner:self options:nil];
        cell3_sizeOverTime = [nib objectAtIndex:0];
    }
    
    
    //cell0_uvExposure.clipsToBounds = YES;
    cell0_measures.clipsToBounds = YES;
    cell1_biggestMole.clipsToBounds = YES;
    cell2_zones.clipsToBounds = YES;
    cell3_sizeOverTime.clipsToBounds = YES;
    
    
    //[_cellList addObject:cell0_uvExposure];
    [_cellList addObject:cell0_measures];
    [_cellList addObject:cell1_biggestMole];
    [_cellList addObject:cell2_zones];
    [_cellList addObject:cell3_sizeOverTime];
    
    
    /*DashboardActivityCompletionCell Removed 9/8/16 but potentially still useful
     
     DashboardActivityCompletionCell *cell1 = (DashboardActivityCompletionCell *)[_tableView dequeueReusableCellWithIdentifier:@"DashboardActivityCompletionCell"];
     
     cell1 = nil;
     
     if (cell1 == nil)
     {
     NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardActivityCompletionCell" owner:self options:nil];
     cell1 = [nib objectAtIndex:0];
     }
     /////  
     
     //DashboardMolyestZone  Removed octoober 2015, probably not useful but keeping it anyway
     DashboardMolyEstZone *cell6 = (DashboardMolyEstZone*)[_tableView dequeueReusableCellWithIdentifier:@"DashboardMolyEstZone"];
     
     cell6 = nil;
     
     if (cell6 == nil)
     {
     NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DashboardMolyEstZone" owner:self options:nil];
     cell6 = [nib objectAtIndex:0];
     }*/

    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row == 0)
    {
        
        //[(DashboardActivityCompletionCell*)[_cellList objectAtIndex:indexPath.row] setDataToProgressView:numb];
    }
    
    if (indexPath.row == 0)
    {
        //[(DashboardZoneDocumentationCell*)[_cellList objectAtIndex:indexPath.row] setDataToProgressView:0.95];
    }
    
    /*if (indexPath.row == 5)
    {
        [(DashboardMolyEstZone*)[_cellList objectAtIndex:indexPath.row] setDataToChart];
    }*/
    
    return [_cellList objectAtIndex:indexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSNumber *height = 0;
    
    /*
    if (indexPath.row == 0)
    {
        DashboardUVExposure* cell = (DashboardUVExposure*)[_cellList objectAtIndex:indexPath.row];
        height = @(cell.bounds.size.height);
    }
     */
    
    if (indexPath.row == 0)
    {
        DashBoardMeasurementCell* cell = (DashBoardMeasurementCell*)[_cellList objectAtIndex:indexPath.row];
        cell.dashBoardViewController = self;
        height = @(cell.bounds.size.height);
    }
    
    if (indexPath.row == 1)
    {
        DashboardBiggestMoleCell* cell = (DashboardBiggestMoleCell*)[_cellList objectAtIndex:indexPath.row];
        height = @(cell.bounds.size.height);
    }
    
    if (indexPath.row == 2)
    {
        DashboardZoneDocumentationCell* cell = (DashboardZoneDocumentationCell*)[_cellList objectAtIndex:indexPath.row];
        height = @(cell.bounds.size.height);
    }
    
    if (indexPath.row == 3)
    {
        DashboardSizeOvertimeCell* cell = (DashboardSizeOvertimeCell*)[_cellList objectAtIndex:indexPath.row];
        
        //probably nondebug
        NSDictionary *moleDictionary = [[DashboardModel sharedInstance] rankedListOfMoleSizeChangeAndMetadata];
        cell.allMolesDicitionary = moleDictionary;
        cell.dashBoardViewController = self;
        height = @(([moleDictionary count] + 1) * 62);
        
        CGRect bounds = [cell.tableViewInside bounds];
        [cell.tableViewInside setBounds:CGRectMake(bounds.origin.x,
                                        bounds.origin.y,
                                        bounds.size.width,
                                        (bounds.size.height + [moleDictionary count] * 62))];
    }
    
    return [height floatValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Change the selected background view of the cell.
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}



@end
