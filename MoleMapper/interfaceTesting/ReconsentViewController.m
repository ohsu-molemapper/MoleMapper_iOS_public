//
//  ReconsentViewController.m
//  MoleMapper
//
//  Created by Dan Webster on 5/27/16.
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


#import "ReconsentViewController.h"
#import "AppDelegate.h"
#import "BridgeManager.h"
#import <BridgeSDK/BridgeSDK.h>
#import "PDFViewerViewController.h"
#import "ConsentRKModule.h"     // for consent form string

@interface ReconsentViewController ()

@end

@implementation ReconsentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"moleMapperLogo"]];
    // Do any additional setup after loading the view.

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:YES  forKey:@"reconsent2017seen"];
}



- (IBAction)leaveStudyPressed:(id)sender
{
    //mimick what happens when leave study from Profile
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    UIAlertController *leaveStudy = [UIAlertController alertControllerWithTitle:@"Leave Study" message:@"Are you sure you want to leave the study?\nThis action cannot be undone and you will need to provide consent in order to re-enroll." preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *leave = [UIAlertAction actionWithTitle:@"Leave Study" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
        [ad.bridgeManager signInAndChangeSharingToScope:@0];
        
        ad.user.sharingScope = @0;
        ad.user.hasEnrolled = NO;
        ad.user.hasConsented = NO;
        ad.user.bridgeSignInEmail = nil;
        ad.user.bridgeSignInPassword = nil;
        [ad showBodyMap];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
    [leaveStudy addAction:leave];
    [leaveStudy addAction:cancel];
        
    [self presentViewController:leaveStudy animated:YES completion:nil];
    
}

- (IBAction)continueSharingPressed:(id)sender
{
    //recapitulate the entire behind the scenes onboarding that takes place after confirming registration, but don't show the onboarding process
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *email = @"";
    NSString *password = @"";
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    

    email = ad.user.bridgeSignInEmail;
    password = ad.user.bridgeSignInPassword;

    // Reset key tracking variables
    ad.user.hasConsented = NO;
    ad.user.hasMCRConsented = NO;

    //NSLog(@"Remember that you need register for the study first here. Turn off the reconsent module in AppDelegate and consent in first.");
    [ud setBool:NO forKey:@"shouldShowEligibilityTest"];
    [ud setBool:NO forKey:@"shouldShowInfoScreens"];
    [ud setBool:NO forKey:@"shouldShowQuiz"];
    [ud setBool:YES forKey:@"shouldShowConsent"];           /* Need to capture user name; this is done in the Show Consent code */
    [ud setBool:YES forKey:@"shouldShowBridgeSignup"];      /* Note: SignUp now checks to see if account already exists */
    [ud setBool:YES forKey:@"shouldShowInitialSurvey"];
    [ud setBool:YES forKey:@"sendConsent"];

    [ad showOnboarding];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"consentForm"])
    {
        PDFViewerViewController *destVC = (PDFViewerViewController *)[segue destinationViewController];
        destVC.filename = NAME_OF_JOINT_CONSENT_FORM;
    }
}


@end
