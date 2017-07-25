//
//  ProfileTableViewController.m
//  MoleMapper
//
//  Created by Dan Webster on 9/11/15.
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


#import "ProfileTableViewController.h"
#import "AppDelegate.h"
#import "MMUser.h"
#import "SBBUserProfile+MoleMapper.h"
#import "PDFViewerViewController.h"
#import "ProfileRKLaunchPad.h"
#import "ExternalIDRKModule.h"

@interface ProfileTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *enrollmentStatus;
@property (weak, nonatomic) IBOutlet UITableViewCell *sharingOptions;

@property (weak, nonatomic) NSString *pdfFilename;  // to pass to the PDF viewer

@end

@implementation ProfileTableViewController

static NSString *const NAME_OF_MM_CONSENT_FORM = @"16038_Consent_ex2018_04_13";
static NSString *const NAME_OF_MCR_CONSENT_FORM = @"10561_Consent_ex2017-12-28";

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"moleMapperLogo"]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    //Set up any customized labels here if needed
    
    AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
//    BOOL userHasEnrolled = ad.user.hasEnrolled;
    BOOL userHasEnrolled = ad.user.hasConsented || ad.user.hasMCRConsented;
    if (userHasEnrolled == YES)
    {
        self.enrollmentStatus.textLabel.text = @"Leave Study";
        int consentCount = 0;
        if (ad.user.hasConsented) {
            consentCount++;
        }
        if (ad.user.hasMCRConsented) {
            consentCount++;
        }
        NSString *msg = [NSString stringWithFormat:@"Participating %d of 2", consentCount];
        self.enrollmentStatus.detailTextLabel.text = msg;
        self.enrollmentStatus.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:(122.0/255.0) blue:255.0 alpha:1.0];
        self.sharingOptions.userInteractionEnabled = YES;
        self.sharingOptions.textLabel.enabled = YES;
        self.sharingOptions.detailTextLabel.enabled = YES;
        self.sharingOptions.textLabel.alpha = 1.0;
    }
    else
    {
        self.enrollmentStatus.textLabel.text = @"Join Study";
        self.enrollmentStatus.detailTextLabel.text = @"Not Participating";
        self.enrollmentStatus.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:(122.0/255.0) blue:255.0 alpha:1.0];
        self.sharingOptions.userInteractionEnabled = NO;
        self.sharingOptions.textLabel.enabled = NO;
        self.sharingOptions.detailTextLabel.enabled = NO;
        self.sharingOptions.textLabel.alpha = 0.5;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        [self leaveOrJoinResearchStudyTapped:nil];
    }
    if (indexPath.section == 2)
    {
        [self showChoiceForReviewConsent];
    }
}

-(void)showChoiceForReviewConsent
{
    UIAlertController *leaveOnboarding = [UIAlertController alertControllerWithTitle:@"Which consent would you like to review?" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *screens = [UIAlertAction actionWithTitle:@"Melanoma Registry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        self.pdfFilename = NAME_OF_MCR_CONSENT_FORM;
    
        [self performSegueWithIdentifier:@"consentForm" sender:self];
        
    }];
    
    UIAlertAction *form = [UIAlertAction actionWithTitle:@"Mole Mapper" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        self.pdfFilename = NAME_OF_MM_CONSENT_FORM;

        [self performSegueWithIdentifier:@"consentForm" sender:self];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
    }];
    
    [leaveOnboarding addAction:screens];
    [leaveOnboarding addAction:form];
    [leaveOnboarding addAction:cancel];
    
    [self presentViewController:leaveOnboarding animated:YES completion:nil];
}
/*
UIAlertController *alert = [UIAlertController simpleAlertWithTitle:NSLocalizedString(@"Email Verification Resent", @"") message:error.localizedDescription];

[self presentViewController:alert animated:YES completion:nil];
*/

- (void)leaveOrJoinResearchStudyTapped:(id)sender
{
    AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
//    BOOL userHasEnrolled = ad.user.hasEnrolled;
    BOOL userHasEnrolled = ad.user.hasConsented || ad.user.hasMCRConsented;
    
    if (userHasEnrolled) //They would be tapping to leave study
    {
        UIAlertController *leaveStudy = [UIAlertController alertControllerWithTitle:@"Leave Study" message:@"Are you sure you want to leave the study?\nThis action cannot be undone and you will need to provide consent in order to re-enroll." preferredStyle:UIAlertControllerStyleActionSheet];
        
    
        //
        // Leave MoleMapper Study Option
        //
        UIAlertAction *leaveMoleMapperStudy = [UIAlertAction actionWithTitle:@"Leave Mole Mapper Study" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
 
            if (ad.user.hasConsented == YES) {
                [ad.bridgeManager signInAndWithdrawConsentForSubpopulationWithCompletionBlock: BridgeManager.MoleMapper_Subpopulation_GUID
                                                                           andCompletionBlock:^(id responseObject, NSError *error) {
                    ad.user.hasConsented = NO;
                }];
            }

            //self.enrollmentStatus.textLabel.text = @"Join Study"; // Can't join study again (until next install?)
            if (ad.user.hasMCRConsented == YES) {
                // assumes withdrawal from MM went fine...
                self.enrollmentStatus.detailTextLabel.text = @"Participating 1 of 2";
            } else {
                self.enrollmentStatus.detailTextLabel.text = @"Participating 0 of 2";
            }
            self.enrollmentStatus.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:(122.0/255.0) blue:255.0 alpha:1.0];
            
            self.sharingOptions.userInteractionEnabled = NO;
            self.sharingOptions.textLabel.enabled = NO;
            self.sharingOptions.detailTextLabel.enabled = NO;
            self.sharingOptions.textLabel.alpha = 0.5;
        }];
        
        //
        // Leave Melanoma Community Registry Option
        //
        UIAlertAction *leaveRegistry = [UIAlertAction actionWithTitle:@"Leave Melanoma Registry" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            
            if (ad.user.hasMCRConsented == YES) {
                [ad.bridgeManager signInAndWithdrawConsentForSubpopulationWithCompletionBlock: BridgeManager.MCR_Subpopulation_GUID
                                                                           andCompletionBlock:^(id responseObject, NSError *error) {
                   ad.user.hasMCRConsented = NO;
                }];
            }
            if (ad.user.hasConsented == YES) {
                // assumes withdrawal from MM went fine...
                self.enrollmentStatus.detailTextLabel.text = @"Participating 1 of 2";
            } else {
                self.enrollmentStatus.detailTextLabel.text = @"Participating 0 of 2";
            }
            self.enrollmentStatus.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:(122.0/255.0) blue:255.0 alpha:1.0];
            
            self.sharingOptions.userInteractionEnabled = NO;
            self.sharingOptions.textLabel.enabled = NO;
            self.sharingOptions.detailTextLabel.enabled = NO;
            self.sharingOptions.textLabel.alpha = 0.5;

        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
        if (ad.user.hasConsented) {
            [leaveStudy addAction:leaveMoleMapperStudy];
        }
        if (ad.user.hasMCRConsented) {
            [leaveStudy addAction:leaveRegistry];
        }
        [leaveStudy addAction:cancel];
        
        [self presentViewController:leaveStudy animated:YES completion:nil];
    }
    else //User wants to enroll in the study
    {
        UIAlertController *joinStudy = [UIAlertController alertControllerWithTitle:@"Join Study" message:@"Tap 'Join Study' to learn more about the research study, your eligibility, and the consent process" preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *join = [UIAlertAction actionWithTitle:@"Join Study" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            [ad setOnboardingBooleansBackToInitialValues];
            [ad showCorrectOnboardingScreenOrBodyMap];
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
        [joinStudy addAction:join];
        [joinStudy addAction:cancel];
        
        [self presentViewController:joinStudy animated:YES completion:nil];
    }
    
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"consentForm"])
    {
        PDFViewerViewController *destVC = (PDFViewerViewController *)[segue destinationViewController];
        destVC.filename = self.pdfFilename;
    }
    
    else if ([segue.identifier isEqualToString:@"feedback"])
    {
        ProfileRKLaunchPad *destVC = (ProfileRKLaunchPad *)[segue destinationViewController];
        destVC.shouldShowFeedback = YES;
    }
    
    else {
        NSLog(@"Untrapped condition: ProfileTableViewController.prepareForSegue");
    }
    
}


@end
