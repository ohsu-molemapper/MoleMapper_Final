//
//  DashBoardMeasurementCell.m
//  MoleMapper
//
//  Created by Karpács István on 16/09/15.
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


#import "DashBoardMeasurementCell.h"
#import "MoleMapper_All-Swift.h"

@class MoleMeasurement30;
@class Mole30;

@implementation DashBoardMeasurementCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    //_dbModel = [[DashboardModel alloc] init];
    _header.backgroundColor = [[DashboardModel sharedInstance] getColorForHeader];
    _headerTitle.textColor = [[DashboardModel sharedInstance] getColorForDashboardTextAndButtons];
    
    _viewMoleBtn.layer.cornerRadius = 5; // this value vary as per your desire
    _viewMoleBtn.clipsToBounds = YES;
    if ([[[DashboardModel sharedInstance] nameForBiggestMole] isEqualToString:@"No moles measured yet!"])
    {
        _viewMoleBtn.enabled = NO;
        _viewMoleBtn.alpha = 0.5;
        _viewMoleBtn.backgroundColor = [UIColor grayColor];
    }
    else {_viewMoleBtn.enabled = YES;}
    
}

-(CGRect) getPositionOfLabels: (float) biggestFloat offsetFloat: (float) offset withHalfOfLabel: (float) half withLabel:(UILabel*) label
{
    float multiplier = _lineOfMeasurement.bounds.size.width / biggestFloat;
    NSInteger posx = _lineOfMeasurement.bounds.origin.x + offset * multiplier;
    CGRect rect = label.frame;
    rect.origin.x = posx;
    return rect;
}

- (void)resetChart
{
    [self createDotsOnBar];
    [self setupLabels];
}

- (void)setupLabels
{
    NSString* biggestMoleName = [[DashboardModel sharedInstance] nameForBiggestMole];
    NSString* zoneMoleName = [[DashboardModel sharedInstance] zoneNameForBiggestMole];
    
    //debug version
    //NSString* biggestMoleName = @"Holy Mollie";
    //NSString* zoneMoleName = @"left upper arm";
    
    _biggestMoleLabel.text = biggestMoleName;
    _locatedMoleLabel.text = @"";
    
    if (![biggestMoleName isEqualToString:@"No moles measured yet!"])
    {
        _biggestMoleLabel.text = [NSString stringWithFormat:@"Your biggest mole is %@ and is", biggestMoleName];
        _locatedMoleLabel.text = [NSString stringWithFormat:@"located in the %@ zone.", zoneMoleName];
        
        [self updateStringColorWithLabel:_biggestMoleLabel withString:biggestMoleName];
        [self updateStringColorWithLabel:_locatedMoleLabel withString:zoneMoleName];
    }
}

- (void) updateStringColorWithLabel:(UILabel*) label withString:(NSString*) string
{
    UIColor *c_bcolor = [[DashboardModel sharedInstance] getColorForDashboardTextAndButtons];
    
    NSMutableAttributedString *text =
    [[NSMutableAttributedString alloc]
     initWithAttributedString: label.attributedText];
    
    NSRange range = [text.string rangeOfString:string];
    if (range.location == NSNotFound) {
        NSLog(@"string was not found");
    } else {
        [text addAttribute:NSForegroundColorAttributeName
                     value:c_bcolor
                     range:NSMakeRange(range.location, [string length])];
        [label setAttributedText: text];
    }
}

- (void)createDotsOnBar
{
    NSArray* dotsArray = [[DashboardModel sharedInstance] allMoleMeasurements];// [_dbModel allMoleMeasurements];
    // Remove any existing dots/labels
    if (_dotSubviews != nil) {
        for (int i = 0; i < [dotsArray count]; ++i)
        {
            [[_dotSubviews objectAtIndex:i] removeFromSuperview];
        }
        [_dotSubviews removeAllObjects];
    }
    if (_tickSubviews != nil) {
        for (int i = 0; i < [_tickSubviews count]; ++i)
        {
            [[_tickSubviews objectAtIndex:i] removeFromSuperview];
        }
        [_tickSubviews removeAllObjects];
    }
    
    float lastFloat = ceilf([[[DashboardModel sharedInstance] sizeOfBiggestMole] floatValue]);
    int endValue = (int) lastFloat;
    bool mult4 = (endValue % 4) == 0;
    bool mult5 = (endValue % 5) == 0;
    while (!(mult4 || mult5)) {
        endValue += 1;
        mult4 = (endValue % 4) == 0;
        mult5 = (endValue % 5) == 0;
    }
    int delta = (int) endValue / 5;
    int ticks = 6;  // 5 + 1 e.g. "0  1  2  3  4  5"
    float pixelsPerMM = _lineOfMeasurement.bounds.size.width / (float)endValue;  // = pixels per mm
    float pixelsPerTickGap = _lineOfMeasurement.bounds.size.width / (float)(ticks-1);
    if (mult4) {
        delta = (int) endValue / 4;
        ticks = 5;
        pixelsPerTickGap = _lineOfMeasurement.bounds.size.width / (float)(ticks-1);
    }
    
    if (_tickSubviews == nil) {
        _tickSubviews = [[NSMutableArray alloc] init];
    }
    for (int n=0; n < ticks; n += 1) {
        float posx = _lineOfMeasurement.frame.origin.x + (float)n * pixelsPerTickGap;  // TBD: minus 1/2 the label width
        UILabel *tickLabel = [[UILabel alloc] initWithFrame:CGRectMake(posx, 120, 10, 10)];
        tickLabel.text = [NSString stringWithFormat:@"%d", n * delta];
        tickLabel.textAlignment = NSTextAlignmentCenter;
        tickLabel.font = [UIFont systemFontOfSize:15];
        [tickLabel sizeToFit];
        CGPoint pt = tickLabel.center;
        pt.x = posx;
        tickLabel.center = pt;
        
        [_tickSubviews addObject:tickLabel];
        [self addSubview:tickLabel];
    }
    
    int width = 7;
    if ([dotsArray count] > 10) {
        width = 5;
    }
    if (_dotSubviews == nil) {
        _dotSubviews = [[NSMutableArray alloc] init];
    }
    for (int i = 0; i < [dotsArray count]; ++i)
    {
        NSInteger posx = _lineOfMeasurement.bounds.origin.x + [[dotsArray objectAtIndex:i] floatValue] * pixelsPerMM;
        UIImageView *myImage = [[UIImageView alloc] initWithFrame:CGRectMake(posx, 95, width, width)];
        myImage.image = [UIImage imageNamed:@"dot.png"];
        myImage.alpha = 0.0;
        [_dotSubviews addObject:myImage];
        [self addSubview:myImage];
    }
    // Animate the dots (just alpha pops, no size wizardry)
    float duration = 1.5 / [_dotSubviews count];
    for (int i = 0; i < [_dotSubviews count]; ++i)
    {
        UIImageView* dot = (UIImageView*)[_dotSubviews objectAtIndex:i];
        [UIView animateWithDuration:duration delay:(duration * i * .75) options:UIViewAnimationOptionCurveEaseIn animations:^{
            dot.alpha = 1.0;
        } completion:^(BOOL finished) {
            // Anything left to do?
        }];
    }
    //[self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    //_dbModel = [[DashboardModel alloc] init];
    
//    [self createDotsOnBar];
//    [self setupLabels];
    
    /* //POSSIBLE HIDE FOR LATER USE
     NSNumber *biggestSize = [[DashboardModel sharedInstance] sizeOfBiggestMole];
    if ([biggestSize integerValue] > 0)
        [self setupLabels];
    else {
        
    }*/
}

- (IBAction)presentMoleViewController:(UIButton *)sender {
    MoleMeasurement30* measurementForBiggestMole = [MoleMeasurement30 biggestMoleMeasurement];
    
    // Replace "measurement" with "mole" in dictionary object
    Mole30* mole = measurementForBiggestMole.whichMole;
    
    NSString* zoneID = mole.whichZone.zoneID;
    NSString* zoneTitle = [Zone30 zoneNameForZoneID:zoneID];
    MeasurementController* destinationVC = [[MeasurementController alloc] initWithZoneID:zoneID zoneTitle:zoneTitle moleToShow:mole measureType:MeasureTypesRemeasure];
    
    CATransition* transition = [CATransition animation];
    transition.duration = 0.5;
    transition.type = kCATransitionFade;
    [self.dashBoardViewController.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.dashBoardViewController.navigationController showViewController:destinationVC sender:nil];
}
@end
