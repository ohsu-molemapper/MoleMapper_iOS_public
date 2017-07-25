//
//  InitialSurveyRKModule.m
//  MoleMapper
//
//  Created by Dan Webster on 8/29/15.
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


#import "InitialSurveyRKModule.h"
#import "AppDelegate.h"

@implementation InitialSurveyRKModule

-(void)showInitialSurvey
{
    
    ORKOrderedTask *task = nil;
    
    /*
    ORKInstructionStep *introStep =
    [[ORKInstructionStep alloc] initWithIdentifier:@"intro"];
    introStep.title = @"About You";
    introStep.text = @"We'd like to ask you a few questions to better understand potential melanoma risk.";
    */

    NSMutableArray *basicInfoItems = [NSMutableArray new];
    ORKFormStep *basicInfo =
    [[ORKFormStep alloc] initWithIdentifier:@"basicInfo"
                                      title:@"About You"
                                       text:@""];
    
    basicInfo.optional = NO;

    // HealthKit way
//    ORKAnswerFormat *dateOfBirthFormat =
//    [ORKHealthKitCharacteristicTypeAnswerFormat
//     answerFormatWithCharacteristicType:
//     [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth]];
//    ORKFormItem *dateOfBirthItem =
//    [[ORKFormItem alloc] initWithIdentifier:@"dateOfBirth"
//                                       text:@"Date of Birth"
//                               answerFormat:dateOfBirthFormat];
//    dateOfBirthItem.placeholder = @"DOB";
//    [basicInfoItems addObject:dateOfBirthItem];

    //ORKDateQuestionResult
    ORKDateAnswerFormat *dateOfBirthFormat = [[ORKDateAnswerFormat alloc] initWithStyle:ORKDateAnswerStyleDate];
    ORKFormItem *dateOfBirthItem =
    [[ORKFormItem alloc] initWithIdentifier:@"dateOfBirth"
                                       text:@"Date of Birth"
                               answerFormat:dateOfBirthFormat];
    dateOfBirthItem.placeholder = @"DOB";
    [basicInfoItems addObject:dateOfBirthItem];
    
    
    NSArray *options = @[[ORKTextChoice choiceWithText:@"Female" value:@"female"],
                           [ORKTextChoice choiceWithText:@"Male" value:@"male"]];
    ORKAnswerFormat *genderFormat = [ORKAnswerFormat choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice textChoices:options];
    
    [basicInfoItems addObject:[[ORKFormItem alloc] initWithIdentifier:@"gender"
                                                                 text:@"Gender"
                                                         answerFormat:genderFormat]];
    
    ORKNumericAnswerFormat *zipCode =
    [ORKNumericAnswerFormat integerAnswerFormatWithUnit:nil];
    [basicInfoItems addObject:[[ORKFormItem alloc] initWithIdentifier:@"zipCode"
                                                                 text:@"What is your zip code?"
                                                         answerFormat:zipCode]];
    
    basicInfo.formItems = basicInfoItems;
    
 
    NSMutableArray *medicalItems = [NSMutableArray new];
    ORKFormStep *medicalInfo =
    [[ORKFormStep alloc] initWithIdentifier:@"medicalInfo"
                                      title:@"Medical Information"
                                       text:@""];
    medicalInfo.optional = NO;
    
    ORKAnswerFormat *historyMelanoma = [ORKAnswerFormat booleanAnswerFormat];
    [medicalItems addObject:[[ORKFormItem alloc] initWithIdentifier:@"historyMelanoma"
                                                               text:@"Have you ever been diagnosed with melanoma?"
                                                       answerFormat:historyMelanoma]];
    
    ORKAnswerFormat *differentCancer = [ORKAnswerFormat booleanAnswerFormat];
    [medicalItems addObject:[[ORKFormItem alloc] initWithIdentifier:@"differentCancer"
                                                               text:@"Have you ever been diagnosed with a different cancer?"
                                                       answerFormat:differentCancer]];

    
    medicalInfo.formItems = medicalItems;
    
    ORKInstructionStep *thankYouStep = [[ORKInstructionStep alloc] initWithIdentifier:@"thankYou"];
    thankYouStep.title = @"Thank You!";
    thankYouStep.text = @"Your participation in this study is helping us to better understand melanoma risk and skin health\n\nYour task now is to map and measure your moles each month. You don't have to get them all, but the more the better!\n\nHappy Mapping!";
    
    task = [[ORKOrderedTask alloc] initWithIdentifier:@"task" steps:@[
                                                                      basicInfo,
                                                                      medicalInfo,
                                                                      thankYouStep
                                                                      ]];
    
    ORKTaskViewController *taskViewController =
    [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = self;
    [self.presentingVC presentViewController:taskViewController animated:YES completion:nil];
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController
stepViewControllerWillAppear:(ORKStepViewController *)stepViewController
{
    
        /*
         Example of customizing the back and cancel buttons in a way that's
         visibly obvious.
         */
        stepViewController.cancelButtonItem = nil;
    
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason
                     error:(NSError *)error
{
    
    ORKTaskResult *taskResult = [taskViewController result];
    NSDate *dateOfLastSurveyCompleted = taskResult.endDate;
    
    
    switch (reason)
    {
        case ORKTaskViewControllerFinishReasonCompleted:
        {
            
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud setValue:dateOfLastSurveyCompleted forKey:@"dateOfLastSurveyCompleted"];
            [ud setBool:YES forKey:@"showDemoInfo"];
            [ud setBool:NO forKey:@"shouldShowOnboarding"];
            [ud setBool:NO forKey:@"shouldShowBeaker"];        // explicitly request beaker (rather than state-logic)

            NSDictionary *parsedData = [self parsedDataFromTaskResult:taskResult];
            AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            
            [ad.bridgeManager signInAndSendInitialData:parsedData];
            
            [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
            [ad showBodyMap];
            break;
            
        }
            
        case ORKTaskViewControllerFinishReasonFailed:
        {
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud setBool:YES forKey:@"showDemoInfo"];
            [ud setBool:NO forKey:@"shouldShowOnboarding"];
            [self.presentingVC dismissViewControllerAnimated:NO completion:nil];
            [self leaveOnboardingByCancelTapped];
            break;
        }
        case ORKTaskViewControllerFinishReasonDiscarded:
        {
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud setBool:YES forKey:@"showDemoInfo"];
            [ud setBool:NO forKey:@"shouldShowOnboarding"];
            [self.presentingVC dismissViewControllerAnimated:NO completion:nil];
            [self leaveOnboardingByCancelTapped];
            break;
        }
            
        case ORKTaskViewControllerFinishReasonSaved:
        {
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud setBool:YES forKey:@"showDemoInfo"];
            [ud setBool:NO forKey:@"shouldShowOnboarding"];
            [self.presentingVC dismissViewControllerAnimated:NO completion:nil];
            [self leaveOnboardingByCancelTapped];
            break;
        }
    }
    // Then, dismiss the task view controller.
    //[self.presentingVC dismissViewControllerAnimated:YES completion:nil];
}

-(void)leaveOnboardingByCancelTapped
{
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UIAlertController *leaveOnboarding = [UIAlertController alertControllerWithTitle:@"Go to Body Map" message:@"You can come back to the study enrollment process at any time by tapping the Beaker icon at the top of the Body Map. Your progress has been saved." preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *leave = [UIAlertAction actionWithTitle:@"Go to Body Map" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [ad showBodyMap];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        [self showInitialSurvey];
    }];
    
    [leaveOnboarding addAction:leave];
    [leaveOnboarding addAction:cancel];
    
    [self.presentingVC presentViewController:leaveOnboarding animated:YES completion:nil];
    
}

//Schema expected by Bridge
/*
 initialData
 initialData.json.autoImmune - int
 initialData.json.birthyear - string
 initialData.json.eyeColor - string
 initialData.json.familyHistory - int
 initialData.json.gender - string
 initialData.json.hairColor - string
 initialData.json.immunocompromised - int
 initialData.json.melanomaDiagnosis - int
 initialData.json.moleRemoved - int
 initialData.json.profession - string
 initialData.json.shortenedZip - string
 */

-(NSDictionary *)parsedDataFromTaskResult:(ORKTaskResult *)taskResult
{
    NSMutableDictionary *parsedData = [NSMutableDictionary dictionary];
    
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //NSUInteger numberOfDigitsInDeidentifiedZipcode = 3;
    
    NSString *birthdate = @"";
    NSString *gender = @"";
    NSString *postalCode = @"";
    NSString *country = @"US";
    NSNumber *melanomaDiagnosis;
    NSNumber *differentCancer;
    
    NSArray *firstLevelResults = taskResult.results;
    for (ORKCollectionResult *firstLevel in firstLevelResults)
    {
        if ([firstLevel.identifier isEqualToString:@"intro"])
        {
            continue;
        }
        else if ([firstLevel.identifier isEqualToString:@"basicInfo"])
        {
            for (ORKStepResult *secondLevel in firstLevel.results)
            {
                if ([secondLevel.identifier isEqualToString:@"dateOfBirth"])
                {
                    if ([secondLevel isKindOfClass:[ORKDateQuestionResult class]])
                    {
                        ORKDateQuestionResult *dobResult = (ORKDateQuestionResult *)secondLevel;
                        NSDate *dob = dobResult.dateAnswer;
                        
                        //Profile data needs to have an NSDate
                        ad.user.birthdateForProfile = dob;
                        
                        // Old: Just birthyear here for de-identified data in Synapse
                        // New: Full dob is needed for Melanoma Community Registry;
                        //      HIPAA-ize to year (including > 89 aggregation) prior to posting on "Public" Synapse site.
                        
                        NSDateFormatter *formatForBirthdate = [[NSDateFormatter alloc] init];
                        [formatForBirthdate setDateFormat:@"yyyy-MM-dd"]; //FOR UNKNOWN REASONS THE MM MUST BE CAPITALIZED
                        birthdate = [formatForBirthdate stringFromDate:dob];
                        ad.user.birthdate = birthdate;
                    }
                }
                else if ([secondLevel.identifier isEqualToString:@"gender"])
                {
                    if ([secondLevel isKindOfClass:[ORKChoiceQuestionResult class]])
                    {
                        ORKChoiceQuestionResult *genderResult = (ORKChoiceQuestionResult *)secondLevel;
                        gender = genderResult.choiceAnswers[0];
                    }
                }
                else if ([secondLevel.identifier isEqualToString:@"zipCode"])
                {
                    if ([secondLevel isKindOfClass:[ORKNumericQuestionResult class]])
                    {
                        ORKNumericQuestionResult *zipResult = (ORKNumericQuestionResult *)secondLevel;
                        NSNumber *zip = zipResult.numericAnswer;
                        postalCode = [zip stringValue];
                        ad.user.zipCode = postalCode;
                        
                        // Old: Shortened zip code here for de-identified data going to Synapse
                        // New: Full postal code is needed for Melanoma Community Registry;
                        //      HIPAA-ize the code prior to posting on "Public" Synapse site.
                    }
                }
            }
        }
        else if ([firstLevel.identifier isEqualToString:@"medicalInfo"])
        {
            
            for (ORKStepResult *secondLevel in firstLevel.results)
            {
                if ([secondLevel.identifier isEqualToString:@"historyMelanoma"])
                {
                    if ([secondLevel isKindOfClass:[ORKBooleanQuestionResult class]])
                    {
                        ORKBooleanQuestionResult *booleanResult = (ORKBooleanQuestionResult *)secondLevel;
                        NSNumber *booleanAnswer = ([booleanResult.booleanAnswer isEqual:@1]) ? @1 : @0;
                        melanomaDiagnosis = booleanAnswer;
                        ad.user.melanomaStatus = [melanomaDiagnosis stringValue];
                    }
                }
                else if ([secondLevel.identifier isEqualToString:@"differentCancer"])
                {
                    if ([secondLevel isKindOfClass:[ORKBooleanQuestionResult class]])
                    {
                        ORKBooleanQuestionResult *booleanResult = (ORKBooleanQuestionResult *)secondLevel;
                        NSNumber *booleanAnswer = ([booleanResult.booleanAnswer isEqual:@1]) ? @1 : @0;
                        differentCancer = booleanAnswer;
                        ad.user.differentCancer = [differentCancer stringValue];
                    }
                }
            }
        }
        else if ([firstLevel.identifier isEqualToString:@"thankYou"])
        {
            continue;
            
        }
        else
        {
            NSLog(@"Unknown task with identifier: %@",firstLevel.identifier);
        }
    }
    
    [parsedData setValue:birthdate forKey:@"dateOfBirth"];
    [parsedData setValue:gender forKey:@"gender"];
    [parsedData setValue:postalCode forKey:@"postalCode"];
    [parsedData setValue:country forKey:@"country"];
    [parsedData setValue:melanomaDiagnosis forKey:@"historyOfMelanoma"];
    [parsedData setValue:differentCancer forKey:@"historyOfCancer"];
    
    return parsedData;
}


-(NSString *)iso8601stringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSString *iso8601String = [dateFormatter stringFromDate:date];
    return iso8601String;
}


@end
