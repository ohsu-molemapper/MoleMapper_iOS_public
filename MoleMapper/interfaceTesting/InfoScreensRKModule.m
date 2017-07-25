//
//  InfoScreensRKModule.m
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

#import "InfoScreensRKModule.h"
#import "AppDelegate.h"
#import "QuizQuestionViewController.h"

@interface InfoScreensRKModule ()

@property (strong,nonatomic) ORKConsentDocument *consentDocument;

// TODO: read these in dynamically from a resource.
@property (strong,nonatomic) NSString *protectingYourDataDetails;
@property (strong,nonatomic) NSString *issuesToConsiderDetails;
@property (strong,nonatomic) NSString *followupDetails;

@end

@implementation InfoScreensRKModule

-(ORKConsentDocument *)consentDocument
{
    if (!_consentDocument)
    {
        _consentDocument = [ORKConsentDocument new];
    }
    return _consentDocument;
}

-(void)showInfoScreens
{
    
    ORKOrderedTask *task = nil;
    
    ORKConsentSection *overview =
    [[ORKConsentSection alloc] initWithType:ORKConsentSectionTypeOverview];
    overview.title = @"Consent Walkthrough";
    overview.summary = @"\nThe next few screens will explain the research study and help you decide whether or not you want to participate\n\nAfter the walkthrough, we'll briefly test your understanding to make sure you know what is involved\n";
    overview.customLearnMoreButtonTitle = @"";
    
    ORKConsentSection *issues = [[ORKConsentSection alloc] initWithType:ORKConsentSectionTypeCustom];
    issues.title = @"Issues to Consider";
    issues.summary = @"Mole Mapper doesn’t replace your medical care. It is a research study and doesn’t provide diagnosis or treatment recommendations.";
    issues.customImage = [UIImage imageNamed:@"visitingDoctor"];
    issues.content = self.issuesToConsiderDetails;
    issues.customLearnMoreButtonTitle = @"Learn more about issues to consider";
    //issues.customAnimationURL = [[NSBundle mainBundle] URLForResource: @"visitingDoctor@2x" withExtension:@"m4v"];
    
    ORKConsentSection *secure = [[ORKConsentSection alloc] initWithType:ORKConsentSectionTypeCustom];
    secure.title = @"Protecting Your Data";
    secure.summary = @"Your study data will be encrypted on the phone and all identifying information will be separated before storing on a secure cloud server.";
    secure.customImage = [UIImage imageNamed:@"secureDatabase"];
    secure.content = self.protectingYourDataDetails;
    secure.customLearnMoreButtonTitle = @"Learn more about data protection";
    //secure.customAnimationURL = [[NSBundle mainBundle] URLForResource: @"secureDatabase@2x" withExtension:@"m4v"];

    ORKConsentSection *recontact = [[ORKConsentSection alloc] initWithType:ORKConsentSectionTypeCustom];
    recontact.title = @"Follow Up";
    recontact.summary = @"Your name and contact information will be included in the OHSU War on Melanoma Community Registry. You can opt out of this registry at any time.";
    recontact.customImage = [UIImage imageNamed:@"recontact"];
    recontact.content = self.followupDetails;
    recontact.customLearnMoreButtonTitle = @"Learn more about follow up";
    
    self.consentDocument.sections = @[overview,issues,secure,recontact];
    
    ORKVisualConsentStep *visualConsentStep =
    [[ORKVisualConsentStep alloc] initWithIdentifier:@"visualConsent" document:self.consentDocument];
    
    self.consentDocument.title = @"Research Consent";
    self.consentDocument.signaturePageTitle = @"Participant Signature";
    self.consentDocument.signaturePageContent = @"Providing your signature is the final step to consenting to your participation in this research study";
    
    task = [[ORKOrderedTask alloc] initWithIdentifier:@"task" steps:@[visualConsentStep]];
    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = self;
    [self.presentingVC presentViewController:taskViewController animated:YES completion:nil];
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason
                     error:(NSError *)error
{
    
    //ORKTaskResult *taskResult = [taskViewController result];
    
    switch (reason)
    {
        case ORKTaskViewControllerFinishReasonCompleted:
        {
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            [ud setBool:YES forKey:@"shouldShowQuiz"];
            [ud setBool:NO forKey:@"shouldShowInfoScreens"];
            
            AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
            [ad showOnboarding];
            break;
            
        }
            
        case ORKTaskViewControllerFinishReasonFailed:
        {
            [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
            [self leaveOnboardingByCancelTapped];
            break;
        }
        case ORKTaskViewControllerFinishReasonDiscarded:
        {
            [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
            [self leaveOnboardingByCancelTapped];
            break;
        }
            
        case ORKTaskViewControllerFinishReasonSaved:
        {
            [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
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
    
    // Stop asking user to consent
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:NO forKey:@"shouldShowOnboarding"];
    [ud setBool:YES forKey:@"shouldShowBeaker"];        // explicitly request beaker (rather than state-logic)
    
    UIAlertController *leaveOnboarding = [UIAlertController alertControllerWithTitle:@"Go to Body Map" message:@"You can come back to the study enrollment process at any time by tapping the Beaker icon at the top of the Body Map." preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *leave = [UIAlertAction actionWithTitle:@"Go to Body Map" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [ad showBodyMap];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        [self showInfoScreens];
    }];
    
    [leaveOnboarding addAction:leave];
    [leaveOnboarding addAction:cancel];
    
    [self.presentingVC presentViewController:leaveOnboarding animated:YES completion:nil];
    
}

-(NSDictionary *)parsedDataFromTaskResult:(ORKTaskResult *)taskResult
{
    NSMutableDictionary *parsedData = [NSMutableDictionary dictionary];
    
    ORKConsentSignature *consentSignature;
    
    NSNumber *sharingWithOtherInstitutions;
    
    //These identifiable values will go to OHSU for the WarOnMelanoma
    NSString *firstName = @"";
    NSString *lastName = @"";
    
    NSArray *firstLevelResults = taskResult.results;
    for (ORKCollectionResult *firstLevel in firstLevelResults)
    {
        if ([firstLevel.identifier isEqualToString:@"visualConsent"])
        {
            continue;
            
        }
        else if ([firstLevel.identifier isEqualToString:@"sharingStep"])
        {
            for (ORKStepResult *secondLevel in firstLevel.results)
            {
                if ([secondLevel isKindOfClass:[ORKChoiceQuestionResult class]])
                {
                    ORKChoiceQuestionResult *sharingResult = (ORKChoiceQuestionResult *)secondLevel;
                    sharingWithOtherInstitutions = sharingResult.choiceAnswers[0];
                }
            }
            
        }
        else if ([firstLevel.identifier isEqualToString:@"consentReview"])
        {
            for (ORKStepResult *secondLevel in firstLevel.results)
            {
                if ([secondLevel isKindOfClass:[ORKConsentSignatureResult class]])
                {
                    ORKConsentSignatureResult *signatureResult = (ORKConsentSignatureResult *)secondLevel;
                    consentSignature = signatureResult.signature;
                    firstName = signatureResult.signature.givenName;
                    lastName = signatureResult.signature.familyName;
                }
            }
        }
        
    }
    
    //Consider storing some of this data locally in NSUserDefaults?
    [parsedData setValue:sharingWithOtherInstitutions forKey:@"sharingWithOtherInstitutions"];
    
    [parsedData setValue:firstName forKey:@"firstName_IDDATA"];
    [parsedData setValue:lastName forKey:@"lastName_IDDATA"];
    
    return parsedData;
}

#pragma mark - Learn more text

-(NSString *)issuesToConsiderDetails
{
    return @"This study will NOT provide you with information related to your specific health or melanoma risks.\n\n"
    
    "This is NOT a medical diagnostic tool and isn’t designed to provide medical advice, professional diagnosis, opinion, treatment or healthcare services.\n\n"
    
    "You should not use the information provided in Mole Mapper or the study documentation in place of a consultation with your physician or health care provider.\n\n"
    
    "If you have any questions or concerns related to your health, you should seek the advice of a medical professional.";
    
}

-(NSString *)protectingYourDataDetails
{
    return @"If you join this research study, we will ask you to share your mole measurements collected using Mole Mapper. You will:\n\n"
    "1- Take pictures of your moles with your smartphone camera\n"
    "2- Map them to zones on the Mole Mapper body map \n"
    "3- Measure their size relative to a reference object like a coin photographed next to the mole.\n\n"
    
    "We will prompt you to re-measure your moles each month. If you have had a mole removed in a given month, we will ask you to take a photo and measurement of the biopsy site. We will add these data to your regular mole measurements as described below.\n\n"
    
    "You can track your moles at your convenience, track more or fewer moles or stop sharing your mole measurements at any time.\n\n"
    
    "Your privacy is important to us. The data collected through the app will be encrypted on the phone. Your un-named and coded study data (the answers you provide on surveys and your mole data (photos, location, size) will be combined with the similarly de-identified data from other study participants.\n\n"
    
    "By analyzing the data from many Mole Mapper app users we hope to better understand the variation in mole growth and cancer risks, and whether a mobile device can help people measure moles accurately and manage skin health.\n\n"
    
    "The OHSU study team may query the data to identify and re-contact people with certain mole characteristics, and invite them to join specific melanoma-related opportunity or events that may be of interest to them through the War on Melanoma Community Registry.\n\n"
    
    "Your information will not be used for commercial advertising.\n\n"
    
    "We will use strict information technology procedures to safeguard your data and prevent improper access.\n\n"
    
    "Your data will be stored by our vendor Sage Bionetworks and OHSU on separate secure Cloud servers in a manner that keeps your information as safe as possible and prevents unauthorized people from getting to your data.\n\n"
    
    "Your coded study data may be shared with researchers in other countries, including countries that may have different data protection laws than your country of residence.";
}

-(NSString *)followupDetails
{
    return @"The study team may re-contact you. Your name, contact information and your unique HealthCode will be added to the War on Melanoma™ Community Registry that was created by researchers at Oregon Health & Science University. The War on Melanoma™ Community Registry is a confidential registry for melanoma patients, family members and friends determined to find answers and reduce deaths caused by melanoma.\n\n"
    
    "By joining the registry you can help researchers figure out how best to prevent, treat and detect melanoma.  You will receive information about upcoming events in your community and get notified about future melanoma education and research opportunities.";
}

@end
