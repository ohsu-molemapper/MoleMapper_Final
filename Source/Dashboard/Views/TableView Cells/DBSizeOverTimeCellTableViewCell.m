//
//  DBSizeOverTimeCellTableViewCell.m
//  MoleMapper
//
//  Created by Karpács István on 18/09/15.
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


#import "DBSizeOverTimeCellTableViewCell.h"
#import "DashboardModel.h"
#import "MoleMapper_All-Swift.h"

@class MoleMeasurement30;

@implementation DBSizeOverTimeCellTableViewCell

- (void)viewDidLoad {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    _moleProgressLabel.textColor = [[DashboardModel sharedInstance] getColorForDashboardTextAndButtons];
    
    NSString *key = [NSString stringWithFormat:@"%i",  (int)_idx];
    NSDictionary *moleDict = [_moleDictionary objectForKey:key];
    
    _moleNameLabel.text = [moleDict objectForKey:@"name"];
    //_moleNameLabel.text = @"Franklin D. Molesvelt";
    NSNumber* size = [moleDict objectForKey:@"size"];
    NSNumber* percentChange = [moleDict objectForKey:@"percentChange"];
    MoleMeasurement30* measurement = [moleDict objectForKey:@"measurement"];
    Mole30* mole = [moleDict objectForKey:@"mole"];
    NSDate* date = nil;
    if (measurement != nil) {
        date = measurement.date;
    }
    
    float sizeFloat = [[DashboardModel sharedInstance] correctFloat:[size floatValue]];
    
    // Check if the mole has been measured this month. If so, don't show the dot
    // If not, then show the dot

    NSString* dateString = @"n/a";
    if ([mole needsRemeasuring]) {
        // Set the image to a dot
        _needsMeasuringIndicator.image = [UIImage imageNamed:@"redDot"];
    } else {
        _needsMeasuringIndicator.image = [UIImage imageNamed:@"clearSquare"];
    }
    if (date != nil) {
        dateString = [NSString stringWithFormat:@"%@", [self getFormatedDate:date]];
    }
    
    if ([percentChange floatValue] > 0)
    {
        _arrowImageView.image = [UIImage imageNamed:@"arrowup"];
    }
    else if ([percentChange floatValue] < 0)
    {
        _arrowImageView.image = [UIImage imageNamed:@"arrowdown"];
    }
    else if ([percentChange floatValue] == 0)
    {
        _arrowImageView.image = [UIImage imageNamed:@"clearSquare"];
    }
    
    percentChange = [NSNumber numberWithFloat:fabsf([percentChange floatValue])];
    _moleSizeLabel.text = [NSString stringWithFormat:@"Size: %2.1f mm\nLast photo: %@", sizeFloat, dateString];
    _moleProgressLabel.text = [percentChange floatValue] > 0.0f ? [NSString stringWithFormat:@"%2.1f%%", [percentChange floatValue]] : @"0.0%";
    
    // Configure the view for the selected state
}

- (NSString*) getFormatedDate: (NSDate*) date;
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"MMM dd, yyyy";
    NSString* dateString = [formatter stringFromDate:date];
    
    return dateString;
}

- (BOOL) needsMeasuring: (NSDate*) date;
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM"];
    int currentMonth = [[dateFormatter stringFromDate:[NSDate date]] intValue];
    int lastMonthMeasured = [[dateFormatter stringFromDate:date] intValue];
    
    if (currentMonth == lastMonthMeasured) {
        return false;
    } else {
        return true;
    }
    
}

@end
