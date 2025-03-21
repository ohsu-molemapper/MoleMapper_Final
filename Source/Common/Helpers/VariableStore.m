//
//  VariableStore.m
//  Created by David Reese on 7/12/13.
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


#import "VariableStore.h"
#import "BaseZone.h"
#import "TagZone.h"
#import "UIImage+Resize.h"
#import "MoleMapper_All-Swift.h"

@interface VariableStore ()

@end

@implementation VariableStore
+ (VariableStore *)sharedVariableStore
{
    static VariableStore *sharedVariableStore;
    @synchronized(self)
    {
        if (!sharedVariableStore) {
            sharedVariableStore = [[VariableStore alloc] init];
        }
        return sharedVariableStore;
    }
}

- (id)init
{
    _drawingScale = 1.0;
    _baseZones = [self buildBaseZones];
    _tagZones = [[NSMutableDictionary alloc] init];
    
//    float bodyImageWidth = 216.0;
//    float bodyImageHeight = 404.0;
        
    return self;
}


- (NSDictionary *)buildBaseZones
//  Creates a dictionary of BaseZone objects.
//  Each BaseZone has a UIBezierPath, and three images:
//              shapeForHighlighted
//              shapeForNoImage
//              shapeForHasImage
{
    NSArray *structureData = [self baseZoneStructureData];
    NSMutableDictionary *baseZones = [NSMutableDictionary dictionaryWithCapacity:32];

    for (int row = 0; row < [structureData count]; row++)  // For each BaseZone...
    {
        int baseID = (int)[structureData[row][0] integerValue];
        NSArray *frameSizeArray = structureData[row][1];
        NSArray *coords = structureData[row][2];
        BaseZone *bz = [[BaseZone alloc] initWithBaseID:baseID frameSizeAt1x:frameSizeArray andCoordinates:coords atDrawingScale:self.drawingScale];
        NSString *key = [NSString stringWithFormat:@"%d",bz.baseID];
        [baseZones setObject:bz forKey:key];
    }
    
    
    return [NSDictionary dictionaryWithDictionary:baseZones];
}


- (NSDictionary *)BuildTagZoneDictionaryAndButtonsWithStructureData:(NSArray *)structureData forView:(UIImageView *)view
{
    NSMutableDictionary *tagZones = [NSMutableDictionary dictionaryWithCapacity:28];

    // NSDate *start = [NSDate date];  // for TESTING

    for (int row = 0; row < [structureData count]; row++)  // For each TagZone...
    {
        int tagID = (int)[structureData[row][0] integerValue];
        int baseID = (int)[structureData[row][3] integerValue];
        NSString *baseKey = [NSString stringWithFormat:@"%d",baseID];
        BaseZone * bz =  [self.baseZones objectForKey:baseKey];
        NSArray *tagZoneOriginArray = structureData[row][1];
        NSString *titleText = structureData[row][2];
        TagZone *tz = [[TagZone alloc] initWithTagID:tagID baseZone:bz originAt1x:tagZoneOriginArray andTitleBarText:titleText atDrawingScale:self.drawingScale];
        [self addButtonWithTagZone:tz toView:view];
        NSString *key = [NSString stringWithFormat:@"%d",tz.tagID];
        [tagZones setObject:tz forKey:key];
    }
        
    [self.tagZones addEntriesFromDictionary:tagZones];
    return [NSDictionary dictionaryWithDictionary:tagZones];
}


//Helper method to see if file exists at 
-(BOOL)imageFileExistsForZoneID:(NSString *)zoneID
{
    BOOL fileExists;
    if ([zoneID isEqualToString:@"1100"] || [zoneID isEqualToString:@"2100"]) {  // If the zoneID is Head(front view) or Head(back view)...
        fileExists = YES;
    } else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
        NSString *filename = [zoneID stringByAppendingString:@".png"];
        NSString *filePath = [NSString stringWithFormat:@"%@/zone%@",documentsPath,filename];
        fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    }
    
    return fileExists;
}


- (void)addButtonWithTagZone:(TagZone *)tz toView:(UIImageView *)view  // 
{
    BaseZone *bz = tz.baseZonePtr;
    OBShapedButton *button = [[OBShapedButton alloc] initWithFrame:tz.frameAtScale];
    
    [button setImage:bz.shapeForHighlighted forState:UIControlStateHighlighted];
    
    button.tag = tz.tagID;
    tz.button = button;  // Connect the button created above to the .button property in this TagZone object.
    [button addTarget:self.myViewController action:@selector(zoneButtonTappedWithSender:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:button];
}

//Update the transparency depending on the status of the zone being documented or not
- (void)updateButtonWithTagZone:(TagZone *)tz
{
    OBShapedButton *button = tz.button;
    BaseZone *bz = tz.baseZonePtr;
    UIImage *shapeForNormal;
    NSString *zoneID = [NSString stringWithFormat:@"%d",tz.tagID];
    
    if ([Zone30 hasValidImageDataForZoneID:zoneID])
    {
        shapeForNormal = bz.shapeForHasImage;
    }
    else
    {
        shapeForNormal = bz.shapeForNoImage;  //no photo taken yet for this zone
    }
    
    
    [button setImage:shapeForNormal forState:UIControlStateNormal];
}


//Will search the given zone for moles that need re-measuring.  In the future, when it is zone-centric,
//can switch this to check hasValidImage and measuredWithinTheCurrentMonth
//Note that the tagZone.tagID is identical to the zoneID, but it is accessed differently (component in an
// array vs. a property on an object.
- (void)updateBadgeStatusOfTagZone:(TagZone *)tz
{
    //Grab the actual button that overlays the bodyMapViewZone
    OBShapedButton *zoneButton = tz.button;
    
    //Remove any badges first and they may or may not be replaced
    for (UIView *subView in zoneButton.subviews)
    {
        if ([subView isKindOfClass:[UILabel class]])
        {
            [subView removeFromSuperview];
        }
    }
    
    // if the zoneID is for the front head or back head, cycle through the head zones and gather their number
    
    NSString *zoneID = [NSString stringWithFormat:@"%d",tz.tagID];
    
    int badgeNumber = 0;
    //if zone for head area (front or back), add up all 4 head zone moles needing remeasurement
    if ([zoneID isEqualToString:@"1100"] || [zoneID isEqualToString:@"2100"])
    {
        int totalForHeadZones = 0;
        NSString *faceLeftSideZone = @"3150";
        totalForHeadZones += [Zone30 numberOfMolesNeedingRemeasurementInZone:faceLeftSideZone];
        NSString *faceRightSideZone = @"3151";
        totalForHeadZones += [Zone30 numberOfMolesNeedingRemeasurementInZone:faceRightSideZone];
        NSString *faceTopOfHeadZone = @"3170";
        totalForHeadZones += [Zone30 numberOfMolesNeedingRemeasurementInZone:faceTopOfHeadZone];
        NSString *faceFrontZone = @"3171";
        totalForHeadZones += [Zone30 numberOfMolesNeedingRemeasurementInZone:faceFrontZone];
        NSString *faceBackZone = @"3172";
        totalForHeadZones += [Zone30 numberOfMolesNeedingRemeasurementInZone:faceBackZone];
        
        badgeNumber = totalForHeadZones;
    }
    else
    {
        int numberOfMolesNeedingRemeasurement = [Zone30 numberOfMolesNeedingRemeasurementInZone:zoneID];
        
        if (numberOfMolesNeedingRemeasurement)
        {
            badgeNumber = numberOfMolesNeedingRemeasurement;
        }
    }
    
    if (badgeNumber == 0) {return;} //don't re-apply a badge if it is gone now
    else
    {
        UILabel *badge = [self badgeWithNumber:badgeNumber];
        [zoneButton addSubview:badge];
    }

}

-(UILabel *)badgeWithNumber:(int)badgeNumber
{
    UILabel *badge = [[UILabel alloc]initWithFrame:CGRectMake(23,0, 13, 13)];
    badge.textColor = [UIColor whiteColor];
    badge.textAlignment = NSTextAlignmentCenter;
    badge.text = [NSString stringWithFormat:@"%d",badgeNumber];
    badge.layer.borderWidth = 1;
    badge.layer.cornerRadius = 8;
    badge.layer.masksToBounds = YES;
    badge.layer.borderColor =[[UIColor clearColor] CGColor];
    badge.layer.shadowColor = [[UIColor clearColor] CGColor];
    badge.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    badge.layer.shadowOpacity = 0.0;
    badge.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:25.0/255.0 blue:25.0/255.0 alpha:1.0];
    badge.font = [UIFont fontWithName:@"ArialMT" size:11];
    return badge;
}

- (void)updateToHasImageForZoneID:(NSString *)zoneID toView:(UIImageView *)view
{
    TagZone *tz = [self.tagZones objectForKey:zoneID];
    OBShapedButton *button = tz.button;
    BaseZone *bz = tz.baseZonePtr;
    UIImage *shapeForNormal;
    shapeForNormal = bz.shapeForHasImage;
    
    [button setImage:shapeForNormal forState:UIControlStateNormal];
    [button addTarget:self.myViewController action:@selector(zoneButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:button];
}

//Update the transparency depending on the status of the zone being documented or not
- (void)updateZoneButtonImages
{
    NSDictionary *zones = self.tagZones;
    NSString *key;
    for (key in zones)
    {
        TagZone *tz = [zones objectForKey: key];
        [self updateButtonWithTagZone:tz];
        [self updateBadgeStatusOfTagZone:tz];
    }
}

-(void)animateTransparencyOfZonesWithPhotoDataOverDuration:(float)crossFadeDuration
{
    NSDictionary *zones = self.tagZones;
    NSString *key;
    for (key in zones)
    {
        TagZone *tz = [zones objectForKey: key];
        OBShapedButton *button = tz.button;
        BaseZone *bz = tz.baseZonePtr;
        
        UIImage *imageForHasData = bz.shapeForHasImage;
        UIImage *imageForNoData = bz.shapeForNoImage;
        NSString *zoneID = [NSString stringWithFormat:@"%d",tz.tagID];

        if ([Zone30 hasValidImageDataForZoneID:zoneID])
        {
            [button setImage:imageForNoData forState:UIControlStateNormal];
            CABasicAnimation *crossFade = [CABasicAnimation animationWithKeyPath:@"contents"];
            crossFade.duration = crossFadeDuration;
            crossFade.fromValue = (__bridge id)(imageForNoData.CGImage);
            crossFade.toValue = (__bridge id)(imageForHasData.CGImage);
            [button.imageView.layer addAnimation:crossFade forKey:@"animateContents"];
            [button setImage:imageForHasData forState:UIControlStateNormal];
        }
    }
}

-(void)clearTransparencyOfAllZones
{
    NSDictionary *zones = self.tagZones;
    NSString *key;
    for (key in zones)
    {
        TagZone *tz = [zones objectForKey: key];
        OBShapedButton *button = tz.button;
        BaseZone *bz = tz.baseZonePtr;
        UIImage *imageForNoData = bz.shapeForNoImage;
        [button setImage:imageForNoData forState:UIControlStateNormal];
        
    }
}

- (NSArray *)baseZoneStructureData
// LEGEND:
//   structureData[n][0] = baseZoneID
//   structureData[n][1][0] & [n][1][1] = size
//   structureData[n][2][0][0] & [n][2][0][1] = moveTo
//   structureData[n][2][1...][0] & [n][2][1...][1] = lineTo
{
    NSArray *coords;
    
    coords = @[
               @[
                   @10,                 // 10 - Head (master)
                   @[@50.0f, @50.0f],	// Size
                   @[
                       
                       @[@50.0f, @50.0f],	// MoveTo
                       @[@0.0f, @50.0f],	// LineTo
                       @[@0.0f, @0.0f],
                       @[@50.0f, @0.0f],
                       @[@50.0f, @50.0f],
                       
                       ],
                   ],
               
               @[
                   @15,                 // 15 - Face Detail, Face Sides
                   @[@42.0f, @43.0f],	// Size
                   @[
                       
                       @[@0.0f, @43.0f],	// MoveTo
                       @[@42.0f, @43.0f],	// LineTo
                       @[@42.0f, @0.0f],
                       @[@0.0f, @0.0f],
                       @[@0.0f, @43.0f],
                       
                       ],
                   ],
               
               @[
                   @17,                 // 17 - Face Detail, Face-Front; Head Top, Back
                   @[@35.5f, @43.0f],	// Size
                   @[
                       
                       @[@35.5f, @0.0f],	// MoveTo
                       @[@0.0f, @0.0f],	// LineTo
                       @[@0.0f, @43.0f],
                       @[@35.5f, @43.0f],
                       @[@35.5f, @0.0f],
                       
                       ],
                   ],
               
               @[
                   @40,                 // 40 - Upper Thigh (back)
                   @[@45.5f, @35.0f],	// Size
                   @[
                       
                       @[@45.5f, @35.0f],	// MoveTo
                       @[@0.0f, @35.0f],	// LineTo
                       @[@0.0f, @0.0f],
                       @[@45.5f, @0.0f],
                       @[@45.5f, @35.0f],
                       
                       ],
                   ],
               
               @[
                   @45,                 // 45 - Lower Thigh & Knee
                   @[@40.0f, @44.0f],	// Size
                   @[
                       
                       @[@40.0f, @44.0f],	// MoveTo
                       @[@0.0f, @44.0f],	// LineTo
                       @[@0.0f, @0.0f],
                       @[@40.0f, @0.0f],
                       @[@40.0f, @44.0f],
                       
                       ],
                   ],
               
               @[
                   @50,                 // 50 - Upper Calf
                   @[@35.0f, @30.5f],	// Size
                   @[
                       
                       @[@35.0f, @30.5f],	// MoveTo
                       @[@0.0f, @30.5f],	// LineTo
                       @[@0.0f, @0.0f],
                       @[@35.0f, @0.0f],
                       @[@35.0f, @30.5f],
                       
                       ],
                   ],
               
               @[
                   @55,                 // 55 - Lower Calf
                   @[@31.0f, @28.0f],	// Size
                   @[
                       
                       @[@31.0f, @28.0f],	// MoveTo
                       @[@0.0f, @28.0f],	// LineTo
                       @[@0.0f, @0.0f],
                       @[@31.0f, @0.0f],
                       @[@31.0f, @28.0f],
                       
                       ],
                   ],
               
               @[
                   @60,                 // 60 - Ankle & Foot
                   @[@34.0f, @45.0f],	// Size
                   @[
                       
                       @[@34.0f, @0.0f],	// MoveTo
                       @[@0.0f, @0.0f],	// LineTo
                       @[@0.0f, @45.0f],
                       @[@34.0f, @45.0f],
                       @[@34.0f, @0.0f],
                       
                       ],
                   ],
               
               @[
                   @300,                // 300 - Abdomen, Lower Back
                   @[@37.0f, @39.0f],	// Size
                   @[
                       
                       @[@0.0f, @4.46094f],	// MoveTo
                       @[@0.0f, @39.0f],	// LineTo
                       @[@37.0f, @39.0f],
                       @[@37.0f, @0.0f],
                       @[@0.80664f, @0.0f],
                       @[@0.0f, @4.46094f],
                       
                       ],
                   ],
               
               @[
                   @301,                    // 301 - Abdomen, Lower Back
                   @[@37.0f, @39.0f],       // Size
                   @[
                       
                       @[@37.0f, @4.46094f],	// MoveTo
                       @[@37.0f, @39.0f],	// LineTo
                       @[@0.0f, @39.0f],
                       @[@0.0f, @0.0f],
                       @[@36.1934f, @0.0f],
                       @[@37.0f, @4.46094f],
                       
                       ],
                   ],
               
               @[
                   @650,                    // 650 - Shoulder
                   @[@47.6611f, @45.6953f],	// Size
                   @[
                       
                       @[@29.8516f, @21.9092f],	// MoveTo
                       @[@26.0254f, @45.6953f],	// LineTo
                       @[@0.0f, @35.2754f],
                       @[@9.80566f, @10.2275f],
                       @[@43.2168f, @0.0f],
                       @[@45.2188f, @0.0f],
                       @[@47.6611f, @14.6387f],
                       @[@29.8516f, @21.9092f],
                       
                       ],
                   ],
               
               @[
                   @651,	// 651 - Shoulder
                   @[@47.6611f, @45.6953f],	// Size
                   @[
                       
                       @[@17.8096f, @21.9092f],	// MoveTo
                       @[@21.6357f, @45.6953f],	// LineTo
                       @[@47.6611f, @35.2754f],
                       @[@37.8555f, @10.2275f],
                       @[@4.44434f, @0.0f],
                       @[@2.44238f, @0.0f],
                       @[@0.0f, @14.6387f],
                       @[@17.8096f, @21.9092f],
                       
                       ],
                   ],
               
               @[
                   @700,	// 700 - Upper Arm
                   @[@36.7207f, @46.6055f],	// Size
                   @[
                       
                       @[@28.7383f, @46.6055f],	// MoveTo
                       @[@31.0684f, @40.4463f],	// LineTo
                       @[@36.7207f, @9.23047f],
                       @[@13.6592f, @0.0f],
                       @[@0.0f, @35.7324f],
                       @[@28.7383f, @46.6055f],
                       
                       ],
                   ],
               
               @[
                   @701,	// 701 - Upper Arm
                   @[@36.7207f, @46.6055f],	// Size
                   @[
                       
                       @[@7.98242f, @46.6055f],	// MoveTo
                       @[@5.65234f, @40.4463f],	// LineTo
                       @[@0.0f, @9.23047f],
                       @[@23.0605f, @0.0f],
                       @[@36.7207f, @35.7324f],
                       @[@7.98242f, @46.6055f],
                       
                       ],
                   ],
               
               @[
                   @750,	// 750 - Upper Forearm, Elbow
                   @[@38.4746f, @36.6104f],	// Size
                   @[
                       
                       @[@28.7383f, @36.6104f],	// MoveTo
                       @[@0.0f, @25.7363f],	// LineTo
                       @[@9.73633f, @0.0f],
                       @[@38.4746f, @10.873f],
                       @[@28.7383f, @36.6104f],
                       
                       ],
                   ],
               
               @[
                   @751,	// 751 - Upper Forearm, Elbow
                   @[@38.4746f, @36.6104f],	// Size
                   @[
                       
                       @[@9.73633f, @36.6104f],	// MoveTo
                       @[@38.4746f, @25.7363f],	// LineTo
                       @[@28.7383f, @0.0f],
                       @[@0.0f, @10.873f],
                       @[@9.73633f, @36.6104f],
                       
                       ],
                   ],
               
               @[
                   @800,	// 800 - Lower Forearm
                   @[@38.7881f, @36.7227f],	// Size
                   @[
                       
                       @[@28.7383f, @36.7227f],	// MoveTo
                       @[@0.0f, @25.8486f],	// LineTo
                       @[@10.0498f, @0.0f],
                       @[@38.7881f, @10.874f],
                       @[@28.7383f, @36.7227f],
                       
                       ],
                   ],
               
               @[
                   @801,	// 801 - Lower Forearm
                   @[@38.7881f, @36.7227f],	// Size
                   @[
                       
                       @[@10.0498f, @36.7227f],	// MoveTo
                       @[@38.7881f, @25.8486f],	// LineTo
                       @[@28.7383f, @0.0f],
                       @[@0.0f, @10.874f],
                       @[@10.0498f, @36.7227f],
                       
                       ],
                   ],
               
               @[
                   @850,	// 850 - Hand
                   @[@46.9922f, @61.7402f],	// Size
                   @[
                       
                       @[@46.9912f, @30.457f],	// MoveTo
                       @[@35.1543f, @61.7393f],	// LineTo
                       @[@0.0f, @48.4395f],
                       @[@0.0f, @31.2852f],
                       @[@11.8389f, @0.0f],
                       @[@46.9922f, @13.3018f],
                       @[@46.9912f, @30.457f],
                       
                       ],
                   ],
               
               @[
                   @851,	// 851 - Hand
                   @[@46.9922f, @61.7402f],	// Size
                   @[
                       
                       @[@0.0f, @30.457f],	// MoveTo
                       @[@11.8379f, @61.7393f],	// LineTo
                       @[@46.9922f, @48.4395f],
                       @[@46.9912f, @31.2852f],
                       @[@35.1533f, @0.0f],
                       @[@0.0f, @13.3018f],
                       @[@0.0f, @30.457f],
                       
                       ],
                   ],
               
               @[
                   @1200,	// 1200 - Neck & Center Chest (front)
                   @[@29.1172f, @60.915f],	// Size
                   @[
                       
                       @[@2.00195f, @9.65234f],	// MoveTo
                       @[@10.5547f, @60.915f],	// LineTo
                       @[@18.5625f, @60.915f],
                       @[@27.1152f, @9.65234f],
                       @[@29.1172f, @9.65234f],
                       @[@29.1172f, @0.0f],
                       @[@0.0f, @0.0f],
                       @[@0.0f, @9.65234f],
                       @[@2.00195f, @9.65234f],
                       
                       ],
                   ],
               
               @[
                   @1250,	// 1250 - Pectorals (front)
                   @[@36.1934f, @55.5898f],	// Size
                   @[
                       
                       @[@0.0f, @55.5898f],	// MoveTo
                       @[@36.1934f, @55.5898f],	// LineTo
                       @[@36.1934f, @36.624f],
                       @[@32.1895f, @36.624f],
                       @[@26.0781f, @0.0f],
                       @[@8.26953f, @7.27051f],
                       @[@0.0f, @55.5898f],
                       
                       ],
                   ],
               
               @[
                   @1251,	// 1251 - Pectorals (front)
                   @[@36.1934f, @55.5898f],	// Size
                   @[
                       
                       @[@36.1934f, @55.5898f],	// MoveTo
                       @[@0.0f, @55.5898f],	// LineTo
                       @[@0.0f, @36.624f],
                       @[@4.00391f, @36.624f],
                       @[@10.1133f, @0.0f],
                       @[@27.9238f, @7.27051f],
                       @[@36.1934f, @55.5898f],
                       
                       ],
                   ],
               
               @[
                   @1350,	// 1350 - Pelvis (front) **DTR 2013.08.22 Changed coords to "Close the Gap"
                   @[@44.5f, @49.8569f],	// Size
                   @[
                       
                       @[@44.5f, @49.8569f],  // MoveTo
                       @[@0.0f, @33.2471f],   // LineTo
                       @[@7.5f, @0.0f],
                       @[@44.5f, @0.0f],
                       @[@44.5f, @49.8569f],
                       
                       ],
                   ],
               
               @[
                   @1351,	// 1351 - Pelvis (front) **DTR 2013.08.22 Changed coords to "Close the Gap"
                   @[@44.5f, @49.8569f],	// Size
                   @[
                       
                       @[@0.0f, @49.8569f],  // MoveTo
                       @[@44.5, @33.2471f],  // LineTo
                       @[@37.0f, @0.0f],
                       @[@0.0f, @0.0f],
                       @[@0.0f, @49.8569f],
                       
                       ],
                   ],
               
               @[
                   @1400,	// 1400 - Upper Thigh (front) **DTR 2013.08.22 Changed coords to "Close the Gap"
                   @[@46.5f, @51.2539f],	// Size
                   @[
                       
                       @[@46.5f, @16.6279f],  // MoveTo
                       @[@46.5f, @51.2539f],  // LineTo
                       @[@0.0f, @51.2539f],
                       @[@0.0f, @0.0f],
                       @[@2.0f, @0.0f],
                       @[@46.5f, @16.6279f],
                       
                       ],
                   ],
               
               @[
                   @1401,	// 1401 - Upper Thigh (front) **DTR 2013.08.22 Changed coords to "Close the Gap"
                   @[@46.5f, @51.2539f],	// Size
                   @[
                       
                       @[@0.0f, @16.6279f],  // MoveTo
                       @[@0.0f, @51.2539f],  // LineTo
                       @[@46.5f, @51.2539f],
                       @[@46.5f, @0.0f],
                       @[@44.5f, @0.0f],
                       @[@0.0f, @16.6279f],
                       
                       ],
                   ],
               
               @[
                   @2200,	// 2200 - Neck (back)
                   @[@29.1172f, @24.291f],	// Size
                   @[
                       
                       @[@24.6729f, @24.291f],	// MoveTo
                       @[@27.1162f, @9.65234f],	// LineTo
                       @[@29.1182f, @9.65234f],
                       @[@29.1172f, @0.0f],
                       @[@0.0f, @0.0f],
                       @[@0.00098f, @9.65234f],
                       @[@2.00293f, @9.65234f],
                       @[@4.44434f, @24.291f],
                       @[@24.6729f, @24.291f],
                       
                       ],
                   ],
               
               @[
                   @2250,	// 2250 - Upper Back (back)
                   @[@36.1934f, @55.5898f],	// Size
                   @[
                       
                       @[@36.1934f, @0.0f],	// MoveTo
                       @[@26.0791f, @0.0f],	// LineTo
                       @[@8.26953f, @7.27051f],
                       @[@0.0f, @55.5898f],
                       @[@36.1934f, @55.5898f],
                       @[@36.1934f, @0.0f],
                       
                       ],
                   ],
               
               @[
                   @2251,	// 2251 - Upper Back (back)
                   @[@36.1934f, @55.5898f],	// Size
                   @[
                       
                       @[@0.0f, @0.0f],	// MoveTo
                       @[@10.1133f, @0.0f],	// LineTo
                       @[@27.9238f, @7.27051f],
                       @[@36.1934f, @55.5898f],
                       @[@0.0f, @55.5898f],
                       @[@0.0f, @0.0f],
                       
                       ],
                   ],
               
               @[
                   @2350,	// 2350 - Glute (back)
                   @[@45.5f, @49.5f],	// Size
                   @[
                       
                       @[@8.5f, @0.0f],	// MoveTo
                       @[@45.5f, @0.0f],	// LineTo
                       @[@45.5f, @49.5f],
                       @[@0.0f, @49.5f],
                       @[@0.0f, @31.7139f],
                       @[@8.5f, @0.0f],
                       
                       ],
                   ],
               
               @[
                   @2351,	// 2351 - Glute (back)
                   @[@45.5f, @49.5f],	// Size
                   @[
                       
                       @[@37.0f, @0.0f],	// MoveTo
                       @[@0.0f, @0.0f],	// LineTo
                       @[@0.0f, @49.5f],
                       @[@45.5f, @49.5f],
                       @[@45.5f, @31.7139f],
                       @[@37.0f, @0.0f],
                       
                       ]
                   ]
               ];				// end of baseZoneCoordinates array
    
    
    return coords;
}


@end
