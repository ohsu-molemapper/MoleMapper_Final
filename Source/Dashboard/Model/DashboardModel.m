//
//  DashboardModel.m
//  MoleMapper
//
//  Created by Andy Yeung on 9/12/15.
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

#import "MoleMapper_All-Swift.h"

#import "DashboardModel.h"
#import "math.h"
#import "MoleMapper_All-Swift.h"

@class Mole30;
@class MoleMeasurement30;
@class Zone30;
@class ZoneMeasurement30;

@implementation DashboardModel

-(instancetype)initModel{
    self = [super init];
    if (self) {
//        AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//        self.context = ad.managedObjectContext;
//        self.measurementForBiggestMole = [MoleMeasurement30 biggestMoleMeasurement];
    }
    return self;
}

+ (id)sharedInstance
{
    static dispatch_once_t p = 0;
    
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] initModel];
    });
    
    return _sharedObject;
}

#pragma mark - Statistics from local data

-(NSInteger) getAllZoneNumber
{
    //This needs to be (- 2) because the head detail in front and back is double-counted and has no actual measurement
    return [[Zone30 allZoneIDs] count] - 2;
}

-(UIColor*) getColorForHeader
{
    //203,229,255
    /*float rateRed = (203.0f / 255.0f) / (0.01f / 255.0f);
    float rateGreen = (229.0f / 255.0f) / (122.0f / 255.0f);
    
    UIColor* c = [self getColorForDashboardTextAndButtons];
    CGColorRef color = [c CGColor];
    
    int numComponents = (int)CGColorGetNumberOfComponents(color);
    
    if (numComponents == 4)
    {
        const CGFloat *components = CGColorGetComponents(color);
        CGFloat red = components[0];
        CGFloat green = components[1];
        //CGFloat blue = components[2];
        //CGFloat alpha = components[3];
        
        red /= rateRed;
        green /= rateGreen;
        
        c = [UIColor colorWithRed:red green:green blue:1.0 alpha:1.0];
    }*/
    
    UIColor* c = [UIColor colorWithRed:234 / 255.0 green:239.0 / 255.0 blue:1.0 alpha:1.0];
    return  c;
}

-(UIColor*) getColorForDashboardTextAndButtons
{
    UIColor* c = [UIColor colorWithRed:0 / 255.0 green:122.0 / 255.0 blue:1.0 alpha:1.0];
    return  c;
}

-(NSNumber *)daysUntilNextMeasurementPeriod
{
    NSDate *now = [NSDate date];
    NSDate *lastTimeAsurveyWasTaken;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    lastTimeAsurveyWasTaken = [ud valueForKey:@"dateOfLastSurveyCompleted"];
    
    NSInteger daysSinceLastSurvey = [self daysBetweenDate:lastTimeAsurveyWasTaken andDate:now];
    NSInteger daysUntilNextMeasurementPeriod = daysSinceLastSurvey % AppDelegate.numberOfDaysInFollowupPeriod;
    daysUntilNextMeasurementPeriod = AppDelegate.numberOfDaysInFollowupPeriod - daysUntilNextMeasurementPeriod;
    NSNumber *returnValue = [NSNumber numberWithInteger:daysUntilNextMeasurementPeriod];
    return returnValue;
}

-(NSNumber *)numberOfZonesDocumented
{
    return [Zone30 zonesMeasured];
}

//Returns an array of all current mole measurements (as NSNumbers but are decimals)
-(NSArray *)allMoleMeasurements
{
    NSMutableArray *allMoleMeasurements = [NSMutableArray array];
    
    for (Mole30 *mole in [Mole30 allMoles])
    {
        MoleMeasurement30 *measure = [mole mostRecentMeasurement:YES];
        if (measure != nil) {
            if ([measure.calculatedMoleDiameter doubleValue] > 0.0)
            {
                [allMoleMeasurements addObject:measure.calculatedMoleDiameter];
            }
        }
    }
    return allMoleMeasurements;
}

//Returns the human-readable name for the biggest measured mole, or "No moles measured yet!" if no valid measurements
-(NSString *)nameForBiggestMole
{
    NSString *moleName = @"No moles measured yet!";
    MoleMeasurement30* measurementForBiggestMole = [MoleMeasurement30 biggestMoleMeasurement];
    if (measurementForBiggestMole != nil)
    {
        moleName = measurementForBiggestMole.whichMole.moleName;
    }
    return moleName;
}

//Returns the human-readable name for the zone that contains the biggest measured mole, or "N/A" if no valid measurements
-(NSString *)zoneNameForBiggestMole
{
    NSString *zoneName = @"N/A";
    MoleMeasurement30* measurementForBiggestMole = [MoleMeasurement30 biggestMoleMeasurement];
    if (measurementForBiggestMole != nil)
    {
        NSString *zoneID = measurementForBiggestMole.whichMole.whichZone.zoneID;
        zoneName = [Zone30 zoneNameForZoneID:zoneID];
    }
    return zoneName;
}

//Returns the absolute diameter (in mm) of the biggest mole, or nil if no measurements
-(NSNumber *)sizeOfBiggestMole
{
    NSNumber *diameter = @0;
    MoleMeasurement30* measurementForBiggestMole = [MoleMeasurement30 biggestMoleMeasurement];
    if (measurementForBiggestMole != nil) {
        diameter = measurementForBiggestMole.calculatedMoleDiameter;
    }
    return diameter;
}

////Returns the absolute diameter (in mm) of the average mole, or 0 if no measurements
-(NSNumber *)sizeOfAverageMole
{
    NSNumber *averageMoleSize = [Mole30 averageMoleSize];
    
    return averageMoleSize;
}

/*
 - (NSMutableDictionary*)rankedListOfMoleSizeChangeAndMetadata {}
 - Return in order of highest upward variance //no need that from now on
 - Returns: [{"name": @"", "size": NSNumber*, "percentChange": NSNumber*, "mole": Mole30*}, ...]
 */

-(NSMutableDictionary*) rankedListOfMoleSizeChangeAndMetadata
{
    NSArray *sortedMoles = [self measurementsInOrderOfMostIncreasedPercentage];
    
    NSMutableDictionary *listOfMoles = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < sortedMoles.count; ++i)
    {
        NSString *key = [NSString stringWithFormat:@"%i",i];
        NSMutableDictionary *moleDict = sortedMoles[i];
        [listOfMoles setObject:moleDict forKey: key];
    }
    
    //USE FOR DEBUG ON SIMULATOR
    /*for (int i = 0; i < 10; ++i)
    {
        
        //NSDate *date = [NSDate date];
        
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setDay:27];
        [comps setMonth:2];
        [comps setYear:1987];
        NSDate* correctedDay = [[NSCalendar currentCalendar] dateFromComponents:comps];
        
        NSString *key = [NSString stringWithFormat:@"%i",i];
        NSMutableDictionary *moleDict = [NSMutableDictionary dictionary];
        [moleDict setObject:@"holymoly" forKey:@"name"];
        [moleDict setObject:[NSNumber numberWithFloat:i] forKey:@"size"];
        [moleDict setObject:[NSNumber numberWithFloat:i] forKey:@"percentChange"];
        [moleDict setObject:[NSDate date] forKey:@"measurement"];
        [listOfMoles setObject:moleDict forKey: key];
    }*/

    return listOfMoles;
}

-(NSArray *)measurementsInOrderOfMostIncreasedPercentage
{
    NSArray *measurementsOrderedByMostIncreasedPercentage = [NSMutableArray array];
    NSMutableArray *arrayOfMeasurementMetadata = [NSMutableArray array];
    
    for (Mole30 *mole in [Mole30 allMoles])
    {
        NSMutableDictionary *measurementMetadata = [NSMutableDictionary dictionary];
        
        NSSet *measurementsForMole = mole.moleMeasurements;
        [measurementMetadata setValue:mole.moleName forKey:@"name"];
        [measurementMetadata setValue:@0 forKey:@"size"];
        [measurementMetadata setValue:@0 forKey:@"percentChange"];
        [measurementMetadata setValue:mole forKey:@"mole"];                         // needed for display purposes
        MoleMeasurement30 *lastMeasurement = [mole mostRecentMeasurement:NO];       // most recently photographed
        [measurementMetadata setValue:lastMeasurement forKey:@"measurement"];
        
        if (measurementsForMole.count == 0)
        {
            NSLog(@"In new model this should never be reached.");
        }
        else if (measurementsForMole.count == 1) //Only 1 measurement, so no basis for comparison: 0% change
        {
            // get measurement that actually contains a _measurement_ (not just a photo)
            MoleMeasurement30 *onlyMeasurement = [mole mostRecentMeasurement:YES];
            if (onlyMeasurement != nil)
            {
                [measurementMetadata setValue:onlyMeasurement.calculatedMoleDiameter forKey:@"size"];
//                [measurementMetadata setValue:onlyMeasurement forKey:@"measurement"];       // needed for overdue calculation
            }
        }
        else if (measurementsForMole.count > 1)
        {
            // get measurement that actually contains a _measurement_ (not just a photo)
            MoleMeasurement30 *mostRecentMeasurement = [mole mostRecentMeasurement:YES];
            if (mostRecentMeasurement != nil)
            {
                NSNumber *percentChange = [self percentChangeInSizeForMole:mole];
                
                [measurementMetadata setValue:mostRecentMeasurement.calculatedMoleDiameter forKey:@"size"];
                [measurementMetadata setValue:percentChange forKey:@"percentChange"];
//                [measurementMetadata setValue:mostRecentMeasurement forKey:@"measurement"];
            }
        }
        else {NSLog(@"Strange situaiton in which you have a negative return value for fetching measurements for a mole.");}
    
        if (measurementsForMole.count > 0)
        {
            [arrayOfMeasurementMetadata addObject:measurementMetadata];
        }
    }
    
    NSSortDescriptor *sortByPercent = [[NSSortDescriptor alloc] initWithKey:@"percentChange" ascending:YES];
    sortByPercent = [sortByPercent reversedSortDescriptor];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByPercent];
    measurementsOrderedByMostIncreasedPercentage = [arrayOfMeasurementMetadata sortedArrayUsingDescriptors:sortDescriptors];
    
    return measurementsOrderedByMostIncreasedPercentage;
}

-(NSNumber *)percentChangeInSizeForMole:(Mole30 *)mole
{
    NSNumber *percentChange = @0;
    MoleMeasurement30 *oldestMeasurement = [mole oldestMeasurement:YES];
    MoleMeasurement30 *mostRecentMeasurement = [mole mostRecentMeasurement:YES];
    float oldestDiameter = -1.0;
    float mostRecentDiameter = -1.0;
    if (oldestMeasurement != nil) {
        oldestDiameter = [oldestMeasurement.calculatedMoleDiameter floatValue];
    }
    if (mostRecentMeasurement != nil) {
        mostRecentDiameter = [mostRecentMeasurement.calculatedMoleDiameter floatValue];
    }
    //Round the floating point values so that small changes in size don't look out of place due mismatch between user-visible measurement (1 decimal) vs. behind the scenes precision
    
    //float initialRounded = [self correctFloat:initialDiameter];
    //float mostRecentRounded = [self correctFloat:mostRecentDiameter];

    if ((oldestDiameter > 0.0f) && (mostRecentDiameter > 0.0f))
    {
        float percentChangeFloat = -1.0 * (((oldestDiameter - mostRecentDiameter)/ oldestDiameter) * 100.0f);
        //float percentChangeFloat = ((mostRecentDiameter / initialDiameter) * 100.0f) - 100.0f;
        //float percentChangeFloat = ((mostRecentRounded / initialRounded) * 100.0f) - 100.0f;
        float correctlyRoundedFloat = [self correctFloat:percentChangeFloat];
        percentChange = [NSNumber numberWithFloat:correctlyRoundedFloat];
    }
    return percentChange;
}

//If user has provided their zip code during initial onboarding, this will
//return their zip code as a string

//DEBUG test... 
/*-(NSString *)zipCodeForUser
{
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return ad.bridgeManager.bridgeProfileZipCode;
}*/

#pragma mark - Helper methods

-(NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

-(BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

-(float) correctFloat:(float) value
{
    return floorf(value * 10.0f + 0.5) / 10.0f;
}

-(UILabel*) getNoDataLabel
{
    UILabel *noDataLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 50, 0, 0)];
    [noDataLabel setBackgroundColor:[UIColor clearColor]];
    [noDataLabel setText:@"NO DATA AVAILABLE"];
    noDataLabel.textAlignment = NSTextAlignmentCenter;
    noDataLabel.textColor = [UIColor darkGrayColor];
    
    return noDataLabel;
}

-(NSData *)mostRecentStoredUVdata
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSData *mostRecentStoredUVdata = [ud objectForKey:@"mostRecentStoredUVdata"];
    return mostRecentStoredUVdata;
}

-(void)setMostRecentStoredUVdata:(NSData *)mostRecentStoredUVdata
{
    if (mostRecentStoredUVdata != nil)
    {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:mostRecentStoredUVdata forKey:@"mostRecentStoredUVdata"];
    }
}

@end
