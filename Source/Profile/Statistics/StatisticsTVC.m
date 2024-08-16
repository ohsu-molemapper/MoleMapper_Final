//
//  StatisticsTVC.m
//  MoleMapper
//
//  Created by Dan Webster on 12/9/13.
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


#import "StatisticsTVC.h"
#import "BodyMapViewController.h"
#import "AppDelegate.h"
#import "MoleMapper_All-Swift.h"

@class Zone30;
@class Mole30;
@class MoleMeasurement30;

@interface StatisticsTVC ()

@property (nonatomic, weak) IBOutlet UITableViewCell *zonesDocumented;
@property (nonatomic, weak) IBOutlet UITableViewCell *totalMolesDocumented;
@property (nonatomic, weak) IBOutlet UITableViewCell *measurementsTaken;
@property (nonatomic, weak) IBOutlet UITableViewCell *averageMoleSize;
@property (nonatomic, weak) IBOutlet UITableViewCell *biggestMole;
@property (nonatomic, weak) IBOutlet UITableViewCell *moleyestZone;

@end

@implementation StatisticsTVC

#pragma mark - View Controller Life Cycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.context = ad.managedObjectContext;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    self.zonesDocumented.detailTextLabel.text = [self zonesDocumentedLabelString];
    self.totalMolesDocumented.detailTextLabel.text = [self numberOfMolesDocumented];
    self.measurementsTaken.detailTextLabel.text = [self numberOfMeasurementsDocumented];
    self.averageMoleSize.detailTextLabel.text = [self avgMoleSize];
    self.biggestMole.detailTextLabel.text = [self subtitleForBiggestMole];
    self.moleyestZone.detailTextLabel.text = [self subtitleForMolyestZone];
}


#pragma mark - Retrieving Data

-(NSString *)zonesDocumentedLabelString
{
    int numberOfZonesDocumented = 0;
    NSUInteger totalNumberOfZones = [[Zone30 allZoneIDs] count] - 2;
    numberOfZonesDocumented = [[Zone30 zonesMeasured] intValue];
    
    NSString *label = [NSString stringWithFormat:@"%d / %lu",numberOfZonesDocumented , (unsigned long)totalNumberOfZones];
    return label;
}

-(NSString *)numberOfMolesDocumented
{
    NSNumber* numberOfMolesDocumented = [Mole30 moleCount];
    NSString *moleString = [NSString stringWithFormat:@"%d",[numberOfMolesDocumented intValue]];
    return moleString;
}

-(NSString *)numberOfMeasurementsDocumented
{
    NSNumber *numberOfMeasurementsDocumented = [MoleMeasurement30 measurementCount];
    NSString *measurementsString = [NSString stringWithFormat:@"%d",[numberOfMeasurementsDocumented intValue]];
    return measurementsString;
}

-(NSString *)avgMoleSize
{
    //Note: the proceeding comes from: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreData/Articles/cdFetching.html#//apple_ref/doc/uid/TP40002484-SW6
    NSNumber *averageMoleSize = @0;
    NSString *averageMoleSizeString = @"N/A";

    averageMoleSize = [Mole30 averageMoleSize];
    if ([averageMoleSize floatValue] > 0.0) {
        NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
        [fmt setMaximumFractionDigits:2];
        averageMoleSizeString = [fmt stringFromNumber:averageMoleSize];
        averageMoleSizeString = [averageMoleSizeString stringByAppendingString:@" mm"];
    }
    
    return averageMoleSizeString;
}

-(NSString *)subtitleForBiggestMole {
    MoleMeasurement30 *biggest = [MoleMeasurement30 biggestMoleMeasurement];
    NSString *subtitle = @"No moles measured with reference yet";
    if (biggest != nil)
    {
        NSString *moleName = biggest.whichMole.moleName;
        NSString *zoneName = [Zone30 zoneNameForZoneID:biggest.whichMole.whichZone.zoneID];
        NSNumber *moleArea = biggest.calculatedMoleDiameter;
        NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
        [fmt setMaximumFractionDigits:2];
        NSString *moleAreaString = [fmt stringFromNumber:moleArea];
        NSString *measurement = [moleAreaString stringByAppendingString:@" mm"];
        subtitle = [NSString stringWithFormat:@"%@, %@, %@",moleName,zoneName,measurement];
    }
    return subtitle;
}

- (NSString *)subtitleForMolyestZone {
    Zone30 *zone = [Zone30 moliestZone];
    NSString *subtitle = @"No moles added to a zone yet";
    if (zone) {
        NSString *zoneName = [Zone30 zoneNameForZoneID:zone.zoneID];
        NSUInteger numberOfMolesInMolyestZone = zone.moles.count;
        subtitle = [NSString stringWithFormat:@"%@, %@ moles",zoneName, @(numberOfMolesInMolyestZone)];
    }
    return subtitle;
}

#pragma mark - Table view data source

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 6;
}

// TODO
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell;
}


#pragma mark - Navigation
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // Hijack the storyboard segue process....
    if ([identifier isEqualToString:@"statsSegueToZoneView"])
    {
        if (![Zone30 moliestZone]) {
            return NO;
            
        } else {
            Zone30 *zoneForSegue = [Zone30 moliestZone];
            NSString* zoneID = zoneForSegue.zoneID;
            NSString* zoneTitle = [Zone30 zoneNameForZoneID:zoneID];

            MeasurementController* destinationVC = [[MeasurementController alloc] initWithZoneID:zoneID
                                                                                       zoneTitle:zoneTitle
                                                                                      moleToShow:nil
                                                                                     measureType:MeasureTypesRemeasure];
            
            CATransition *transition = [CATransition animation];
            transition.duration = 0.5;
            transition.type = kCATransitionFade;
            [self.navigationController.view.layer addAnimation:transition forKey:nil];
            [self.navigationController showViewController:destinationVC sender:nil];
            
            return NO;
        }
    }
    else if ([identifier isEqualToString:@"statsSegueToMoleView"])
    {
        if (![MoleMeasurement30 biggestMoleMeasurement]) {return NO;}
        else
        {
            MoleMeasurement30 *measurementForSegue = [MoleMeasurement30 biggestMoleMeasurement];
            Mole30 *moleForSegue = measurementForSegue.whichMole;
            
            NSString* zoneID = moleForSegue.whichZone.zoneID;
            NSString* zoneTitle = [Zone30 zoneNameForZoneID:zoneID];
            MeasurementController* destinationVC = [[MeasurementController alloc] initWithZoneID:zoneID zoneTitle:zoneTitle moleToShow:moleForSegue measureType:MeasureTypesRemeasure];
            
            CATransition* transition = [CATransition animation];
            transition.duration = 0.5;
            transition.type = kCATransitionFade;
            [self.navigationController.view.layer addAnimation:transition forKey:nil];
            [self.navigationController showViewController:destinationVC sender:nil];
           
            return NO;
        }
    }
    else {return YES;}
//#endif
    return NO;
}

//// In a story board-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
////#ifdef TO_FINISH
//    //NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
////    NSNumber *zoneID = @([zoneForSegue.zoneID intValue]);
//    
//    if ([segue.identifier isEqualToString:@"statsSegueToZoneView"])
//    {
//        Zone30 *zoneForSegue = [Zone30 moliestZone];
//        NSString* zoneID = zoneForSegue.zoneID;
//        NSString* zoneTitle = [Zone30 zoneNameForZoneID:zoneID];
//        RemeasureZoneViewController *destinationVC = [[RemeasureZoneViewController alloc] initWithZoneID: zoneID zoneTitle: zoneTitle];
//        
//        CATransition* transition = [CATransition animation];
//        transition.duration = 0.5;
//        transition.type = kCATransitionFade;
//        [self.navigationController.view.layer addAnimation:transition forKey:nil];
//        [self.navigationController showViewController:destinationVC sender:nil];
//    }
//    else if ([segue.identifier isEqualToString:@"statsSegueToMoleView"])
//    {
//        MoleMeasurement30 *measurementForSegue = [MoleMeasurement30 biggestMoleMeasurement];
//        Mole30 *moleForSegue = measurementForSegue.whichMole;
//        
//        NSString* zoneID = moleForSegue.whichZone.zoneID;
//        NSString* zoneTitle = [Zone30 zoneNameForZoneID:zoneID];
//        RemeasureZoneViewController *destinationVC = [[RemeasureZoneViewController alloc] initWithZoneID: zoneID zoneTitle: zoneTitle];
//        
//        CATransition* transition = [CATransition animation];
//        transition.duration = 0.5;
//        transition.type = kCATransitionFade;
//        [self.navigationController.view.layer addAnimation:transition forKey:nil];
//        [self.navigationController showViewController:destinationVC sender:nil];
//
//
////        MoleViewController *destVC = segue.destinationViewController;
////        destVC.mole = moleForSegue;
////        destVC.moleID = moleForSegue.moleID;
////        destVC.moleName = moleForSegue.moleName;
////        destVC.context = self.context;
////        destVC.zoneID = moleForSegue.whichZone.zoneID;
////        
////        NSNumber *zoneIDForSegue = @([moleForSegue.whichZone.zoneID intValue]);
////        
////        destVC.zoneTitle = [Zone zoneNameForZoneID:zoneIDForSegue];
////        destVC.measurement = measurementForSegue;
//    }
////#endif
//}


@end
