//
//  Migrator22to30.m
//  MoleMapper
//
// Copyright (c) 2016, 2017 OHSU. All rights reserved.
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

#import "Migrator22to30.h"
#import "AppDelegate.h"
#import "Zone.h"
#import "Zone+MakeAndMod.h"
#import "Mole.h"
#import "Mole+MakeAndMod.h"
#import "Measurement.h"
#import "Measurement+MakeAndMod.h"
#import "MoleMapper_All-Swift.h"

@implementation Migrator22to30

@class Zone30;
@class ZoneMeasurement30;
@class Mole30;
@class MoleMeasurement30;
@class MMUser;
@class V2xStackFactory;
@class V30StackFactory;
@class V2xStack;
@class V30Stack;

- (void)migrate22to30
{

    V2xStack *v2Stack = [V2xStackFactory createV2xStack];
    V30Stack *v3Stack = [V30StackFactory createV30Stack];
    NSManagedObjectContext *v2xContext = v2Stack.managedContext;
    NSManagedObjectContext *v30Context = v3Stack.managedContext;
    NSDictionary *refLookup = @{@"Penny":@1,@"Nickel":@5,@"Dime":@10,@"Quarter":@25};
   
//    [v2Stack dumpModel];
//    NSLog(@"   ------------------- Before -------------------");
//    [v3Stack dumpModel];
    
    
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Keep dictionaries of persistent data during the migration
    
    //mole.moleID (NSNumber) -> mole30.moleID (string UUID)
    NSMutableDictionary *mole2xMoleIDToMole30moleID = [NSMutableDictionary new];
    NSMutableDictionary *molesThatHaveBeenMigrated = [NSMutableDictionary new];
    
    /**
     
     Here's the story. Because in 3.0 we display the most recent ZoneMeasurement30.displayPhotoFilename
     when we show a zone for re-measurement, we copy the 2.x Zone.zonePhoto for each ZoneMeasurement30
     we create and initialize each MoleMeasurement30's moleMeasurementX/Y from the 2.x Mole's moleX/Y
     properties. We also clip the mole image from the original zonePhoto in the cases where we don't
     have a Measurement object for that Mole. 
     HOWEVER, if we *do* have a Measurement in 2.x, we clip the MoleMeasurement30 image from that
     measurementPhoto using its measurementX/Y properties. The ZoneMeasurement30 location is still
     initialized from the Mole.moleX/Y properties (relative, again, to the Zone.zonePhoto).
     
    */
    
    //**********   ZONES   **********//
    
    NSFetchRequest *zoneFetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Zone" inManagedObjectContext:v2xContext];
    [zoneFetchRequest setEntity:entity];
    zoneFetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"zoneID" ascending:YES]];
    NSError *zoneError = nil;
    NSArray *zoneMatches = [v2xContext executeFetchRequest:zoneFetchRequest error:&zoneError];
    
    if (!zoneMatches || [zoneMatches count] == 0) {NSLog(@"Couldn't fetch any matches for zones in v22 model");}
    
    for (Zone *zone in zoneMatches)
    {
        NSLog(@"Processing zone %@", zone.zoneID);
        //fetch the existing Zone30 object corresponding to the v2Zone
        Zone30 *zone30 = [Zone30 zoneForZoneID:zone.zoneID];
        
        //if a v2Zone had no moles documented, need to create a zoneMeasurement here for display purposes (but which has no mole measurements. The rest will get taken care of when migrating moles/measurements)
        if ((zone.moles.count == 0) && ([Zone hasValidImageDataForZoneID:zone.zoneID]))
        {
            // Useless debugger
//            NSLog(@"zone.zonePhoto: %@\n", zone.zonePhoto);
//            NSLog(@"imageFullFilepathForZoneID: %@", [Zone imageFullFilepathForZoneID:zone.zoneID]);
            ZoneMeasurement30 *zm30 = [ZoneMeasurement30 create];
            zm30.displayPhotoFilename = zone.zonePhoto;
            zm30.whichZone = zone30;
            zm30.date = [NSDate date];
            NSLog(@"zm30 full path for resized photo: %@",[zm30 imageFullPathNameForDisplayPhoto]);
            // DEBUG
            UIImage *img = [Zone imageForZoneName:zone.zoneID];
//            NSLog(@"image orientation %ld",(long)img.imageOrientation);
//            NSLog(@"image width, height: (%f,%f)",img.size.width,img.size.height);
            //
        }
        [[V30StackFactory createV30Stack] saveContext];
    }
    
    
    //**********   MOLES   **********//
    
    NSFetchRequest *moleRequest = [NSFetchRequest fetchRequestWithEntityName:@"Mole"];
    moleRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"moleID" ascending:YES]];
    
    NSError *moleError = nil;
    NSArray *moleMatches = [v2xContext executeFetchRequest:moleRequest error:&moleError];
    
    if (!moleMatches || [moleMatches count] == 0) {NSLog(@"Couldn't fetch any matches for moles in v22 model");}
    
    for (Mole *mole in moleMatches)
    {
        // Dump mole attributes
        NSLog(@"Mole with ID %d named %@ at %d, %d", mole.moleID.intValue, mole.moleName, mole.moleX.intValue, mole.moleY.intValue);
        NSInteger measurementCount = mole.measurements.count;
        NSLog(@"Mole measurements: %zd", measurementCount);     // https://stackoverflow.com/questions/4405006/nslog-printf-specifier-for-nsinteger
        Mole30 *mole30 = [Mole30 create]; //[In create function] mole30.moleID to new UUID
        //(dictionary here for the old mole.moleID (int) to the new mole30.moleID (UUID)
        [mole2xMoleIDToMole30moleID setValue:mole30.moleID forKey:[mole.moleID stringValue]];
        mole30.moleName = mole.moleName;
        Zone30 *thisMolesZone = [Zone30 zoneForZoneID:mole.whichZone.zoneID];
        mole30.whichZone = thisMolesZone;
        
        // A mole has previously been identified on a Zone but no pictures/measurements have been taken.
        if (mole.measurements.count == 0)
        {
            ZoneMeasurement30 *zm30 = [ZoneMeasurement30 create];
            zm30.displayPhotoFilename = mole.whichZone.zonePhoto;
            zm30.whichZone = thisMolesZone;
            zm30.date = [NSDate date];
            
            NSLog(@"zone.zonePhoto: %@\n", mole.whichZone.zonePhoto);
            NSLog(@"imageFullFilepathForZoneID: %@", [Zone imageFullFilepathForZoneID:mole.whichZone.zoneID]);
            NSLog(@"zm30 full path for resized photo: %@",[zm30 imageFullPathNameForDisplayPhoto]);

            
            MoleMeasurement30 *mm30 = [MoleMeasurement30 create];
            mm30.date = zm30.date;
            mm30.calculatedMoleDiameter = @0;
            mm30.moleMeasurementDiameterInPoints = @0;
            mm30.calculatedSizeBasis = @0;


            NSLog(@"Change the moleMeasurementPhoto here to be the old zonePhoto cropped plus border!");
            
            /****************************************************************************
             *  Wait, does this really make sense? We are ficitiously creating a mole
             *  diameter that has nothing to do with the mole and not only will it crop
             *  the wrong amount of the image, it will show up in the stats (if we're not careful).
             *
             *  Having a MoleMeasurement30 object with no image (or radius) could still
             *  be used (if coded for) to place pins on the Augmented Reality screen
             *  but be ignored on the Mole History screen. Part of decision would ideally
             *  come from understanding how many people took lots of zone pictures but never
             *  took mole measurements?
             ****************************************************************************/
            // get cropped, scaled mole image
            CGFloat radius = 20.0;      // Arbitrary (currently not displayed on Zone...yet)
            CGPoint moleCenter = CGPointMake([mole.moleX floatValue], [mole.moleY doubleValue]);
            CirclePosition *moleLocation = [[CirclePosition alloc] initWithCenter:moleCenter radius:radius];
            // TODO: May need to translate X/Y coordinates from landscape to portrait first...
            UIImage *photo = [Zone imageForZoneName:mole.whichZone.zoneID];
            if (photo != nil) {
                BOOL rotateFlag = NO;
                if (photo.size.width > photo.size.height) {
                    rotateFlag = YES;
                    // static func rotatePoint(portraitPoint: CGPoint, imageSize: CGSize) -> CGPoint {
                    CGPoint rotatedPoint = [TranslateUtils rotatePointWithPortraitPoint:moleCenter imageSize:photo.size];
                    moleCenter.x = rotatedPoint.x;
                    moleCenter.y = rotatedPoint.y;
                }

                UIImage *cropped = [TranslateUtils cropMoleInImageWithSourceImage: photo
                                                                     moleLocation: moleLocation     // original location relative to unrotated image
                                                                         rotate90: rotateFlag
                                                                        rescaleTo: 320];
                // save as file
                [mm30 saveDataAsJPEGWithJpegData: UIImageJPEGRepresentation(cropped, 1.0)];   // automatically updates moleMeasurementPhoto
            }
            
            mm30.moleMeasurementX = @(moleCenter.x);
            mm30.moleMeasurementY = @(moleCenter.y);
            mm30.whichMole = mole30;
            mm30.whichZoneMeasurement = zm30;
            [molesThatHaveBeenMigrated setObject:@1 forKey:[mole.moleID stringValue]];
            [[V30StackFactory createV30Stack] saveContext];
        }
        else    // Mole has one or more measurements
        {
            BOOL zonePhotoIsLandscape = NO;
            for (Measurement2x *measurement in mole.measurements) {
                //create a mole measurement with the measurementPhoto (with cropping) and couple it to a ZoneMeasurement
                // As per comment above, the measurementPhoto is cropped from the Measurement photo but the ZoneMeasurement
                // photo is "copied" from the Zone photo and the MoleMeasurement30's moleMeasurementX/Y positions are relative
                // to that photo.
                CGPoint measurementCenter = CGPointMake([mole.moleX doubleValue], [mole.moleY doubleValue]);
                
                MoleMeasurement30 *mm30 = [MoleMeasurement30 create];
                mm30.date = measurement.date;
                mm30.calculatedMoleDiameter = measurement.absoluteMoleDiameter;
                mm30.moleMeasurementDiameterInPoints = measurement.measurementDiameter;
                mm30.calculatedSizeBasis = @1;

                // Deal with different zone photo orientations
                UIImage *zonePhoto = [Zone imageForZoneName:mole.whichZone.zoneID];
                if (zonePhoto != nil) {
                    if (zonePhoto.size.width > zonePhoto.size.height) {
                        zonePhotoIsLandscape = YES;
                        CGPoint rotatedPoint = [TranslateUtils rotatePointWithPortraitPoint:measurementCenter imageSize:zonePhoto.size];
                        measurementCenter.x = rotatedPoint.x;
                        measurementCenter.y = rotatedPoint.y;
                    }
                }

                // Deal with different measurement photo orientations
                UIImage *measurementPhoto = [Measurement imageForMeasurement:measurement];
                if (measurementPhoto != nil) {
                    BOOL rotateFlag = NO;
                    if (measurementPhoto.size.width > measurementPhoto.size.height) {
                        rotateFlag = YES;
                    }
                    // get cropped, scaled mole image
                    CGFloat radius = [measurement.measurementDiameter doubleValue] / 2.0;
                    CGPoint croppedCenter = CGPointMake([measurement.measurementX doubleValue], [measurement.measurementY doubleValue]);
                    CirclePosition *moleMeasurementLocation = [[CirclePosition alloc] initWithCenter:croppedCenter radius:radius];
                    UIImage *cropped = [TranslateUtils cropMoleInImageWithSourceImage: measurementPhoto
                                                                         moleLocation: moleMeasurementLocation
                                                                             rotate90: rotateFlag
                                                                            rescaleTo: 320];
                    UIImageOrientation croppeddir = cropped.imageOrientation;   // DEBUG
                    // save as file
                    [mm30 saveDataAsJPEGWithJpegData: UIImageJPEGRepresentation(cropped, 1.0)];   // automatically updates moleMeasurementPhoto
                }
                mm30.moleMeasurementX = @(measurementCenter.x);                // These are needed by the Zone viewer
                mm30.moleMeasurementY = @(measurementCenter.y);
                mm30.whichMole = mole30;
                
                // create a zoneMeasurements for EACH measurement; they will share the same zonePhoto for correct pin placement
                ZoneMeasurement30 *zm30 = [ZoneMeasurement30 create];
                zm30.displayPhotoFilename = mole.whichZone.zonePhoto;
                zm30.whichZone = thisMolesZone;
                zm30.date = measurement.date;

                // Reference migration
                zm30.referenceDiameterInPoints = measurement.referenceDiameter;
                zm30.referenceDiameterInMillimeters = measurement.absoluteReferenceDiameter;
                CGPoint refCenter = CGPointMake([measurement.referenceX doubleValue], [measurement.referenceY doubleValue]);
                if (zonePhotoIsLandscape) {
                    CGPoint rotatedPoint = [TranslateUtils rotatePointWithPortraitPoint:refCenter imageSize:zonePhoto.size];
                    refCenter.x = rotatedPoint.x;
                    refCenter.y = rotatedPoint.y;
                }
                zm30.referenceX = @(refCenter.x);
                zm30.referenceY = @(refCenter.y);
                if (refLookup[measurement.referenceObject])
                {
                    zm30.referenceObject = measurement.referenceObject;
                }
                else
                {
                    zm30.referenceObject = 0;
                }
                zm30.lensPosition = @-1;
                mm30.whichZoneMeasurement = zm30;
            }
        }
        [[V30StackFactory createV30Stack] saveContext];
    }
    
    [[V30StackFactory createV30Stack] saveContext];    // safety call!

//    NSLog(@"   ------------------- After -------------------");
//    [v3Stack dumpModel];
}

- (void)createTestDataIn22Model
{
    //Get v22 ManagedObjectContext (how to do this with the swift V2xStack?
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *v22context = ad.managedObjectContext;
    
    //Add zonePhoto for right chest
    [self createZoneImage:@"zoneDemoDrag" forZoneID:@"1250" inContext:v22context];
    
    //Add in 2 mole objects in the right chest zone (1250)
    Zone *rightChest = [Zone zoneForZoneID:@"1250" withZonePhotoFileName:nil inManagedObjectContext:v22context];
    
    Mole *mole1 = [Mole moleWithMoleID:@1
                          withMoleName:@"testMole1"
                               atMoleX:@150
                               atMoleY:@150
                                inZone:rightChest
                inManagedObjectContext:v22context];
    
    UIImage *moleImage1 = [UIImage imageNamed:@"preReq"];
    [self createTestMeasurementForMole:mole1 withImage:moleImage1 withMoleDiameter:@2.5];
    
    //Wait for 1 second, then add an additional measurement for mole1 to have longitudinal data
    [NSThread sleepForTimeInterval:1.0f];
    UIImage *moleImage1_2 = [UIImage imageNamed:@"measureDemoPhoto"];
    [self createTestMeasurementForMole:mole1 withImage:moleImage1_2 withMoleDiameter:@3.5];
    
    Mole *mole2 = [Mole moleWithMoleID:@2
                          withMoleName:@"testMole2"
                               atMoleX:@200
                               atMoleY:@200
                                inZone:rightChest
                inManagedObjectContext:v22context];
    
    UIImage *moleImage2 = [UIImage imageNamed:@"zoneViewAnnotated"];
    [self createTestMeasurementForMole:mole2 withImage:moleImage2 withMoleDiameter:@4.5];
    
    //add zonePhoto for right hand
    [self createZoneImage:@"zoneDemoMeasure" forZoneID:@"1850" inContext:v22context];
    
    //Add in 1 mole object in the right hand zone (1850)
    Zone *rightHand = [Zone zoneForZoneID:@"1850" withZonePhotoFileName:nil inManagedObjectContext:v22context];
    
    Mole *mole3 = [Mole moleWithMoleID:@3
                          withMoleName:@"testMole3"
                               atMoleX:@150
                               atMoleY:@150
                                inZone:rightHand
                inManagedObjectContext:v22context];
    
    UIImage *moleImage3 = [UIImage imageNamed:@"zoneDemoPin"];
    [self createTestMeasurementForMole:mole3 withImage:moleImage3 withMoleDiameter:@5.5];
    
}

- (void)createZoneImage:(NSString *)imageName forZoneID:(NSString *)zoneID inContext:(NSManagedObjectContext *)context
{
    UIImage *testZoneImage = [UIImage imageNamed:imageName];
    dispatch_queue_t imageSaveQ = dispatch_queue_create("imageSaveToFileSystem", NULL);
    dispatch_async(imageSaveQ, ^{
        NSData *pngData = UIImagePNGRepresentation(testZoneImage);
        NSString *fileName = [Zone imageFilenameForZoneID:zoneID];
        NSString *filePath = [Zone imageFullFilepathForZoneID:zoneID];
        
        //Write the changes into Core Data
        [Zone zoneForZoneID:zoneID withZonePhotoFileName:fileName inManagedObjectContext:context];
        
        [pngData writeToFile:filePath atomically:YES]; //Write the file
        
    });
}



/* Creates and saves Measurement info into core data,
 The name format looks like this:
 2delimitDec_29,_2014_17colon45colon56.png
 */
-(void) createTestMeasurementForMole:(Mole *)mole withImage:(UIImage *)imageName withMoleDiameter:(NSNumber *)diameter
{
    //Get v22 ManagedObjectContext (how to do this with the swift V2xStack?
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *v22context = ad.managedObjectContext;
    
    //Convoluted way in which the measurement name is created based on the current date/time
    NSString *moleIDString = [mole.moleID stringValue];
    NSDate *now = [[NSDate alloc] init];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MMM_dd,_yyyy_HH:mm:ss"];
    NSString *dateString = [format stringFromDate:now];
    NSString *measurementName = [NSString stringWithFormat:@"%@delimit%@.png",moleIDString,dateString];
    measurementName = [measurementName stringByReplacingOccurrencesOfString:@":" withString:@"colon"];
    
    //This serves to both create the measurement in core data in v22 context
    
    [Measurement moleMeasurementForMole:mole
                               withDate:now
                              withPhoto:measurementName
                withMeasurementDiameter:@20.0
                       withMeasurementX:@150
                       withMeasurementY:@150
                  withReferenceDiameter:@10
                         withReferenceX:@250
                         withReferenceY:@250
                      withMeasurementID:measurementName
          withAbsoluteReferenceDiameter:@17.91
               withAbsoluteMoleDiameter:diameter
                    withReferenceObject:@"Dime"
                 inManagedObjectContext:v22context];
    
    NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",docsDirectory,measurementName];
    
    dispatch_queue_t imageSaveQ = dispatch_queue_create("imageSaveToFileSystem", NULL);
    dispatch_async(imageSaveQ,^{
        NSData *pngData = UIImagePNGRepresentation(imageName);
        [pngData writeToFile:filePath atomically:YES];}); //Write the file
    
}


@end
