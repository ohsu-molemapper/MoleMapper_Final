//
//  DashboardModel.h
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


#import <Foundation/Foundation.h>

@class MoleMeasurement30;

@interface DashboardModel : NSObject

@property (strong, nonatomic) NSManagedObjectContext *context;
// This doesn't work quite right; it's good for efficiency but if someone measures a new
// mole, this isn't updated. For now, we'll just re-calculate each time and then
// implement a cache-and-update strategy later.
//@property (strong, nonatomic) MoleMeasurement30 *measurementForBiggestMole;

//local cache of the most recent UV data while fetching from EPA on refresh
@property (strong, nonatomic) NSData *mostRecentStoredUVdata;

+ (id)sharedInstance;
-(NSNumber *)daysUntilNextMeasurementPeriod;
-(NSNumber *)numberOfZonesDocumented;
-(NSArray *)allMoleMeasurements;
-(NSString *)nameForBiggestMole;
-(NSString *)zoneNameForBiggestMole;
-(NSNumber *)sizeOfBiggestMole;
-(NSNumber *)sizeOfAverageMole;
-(NSMutableDictionary*) rankedListOfMoleSizeChangeAndMetadata;
-(NSInteger) getAllZoneNumber;

-(float) correctFloat:(float) value;
-(UIColor*) getColorForDashboardTextAndButtons;
-(UIColor*) getColorForHeader;

@end
