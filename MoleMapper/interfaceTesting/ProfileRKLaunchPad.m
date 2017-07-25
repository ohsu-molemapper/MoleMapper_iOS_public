//
//  ProfileRKLaunchPad.m
//  MoleMapper
//
//  Created by Dan Webster on 9/15/15.
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


#import "ProfileRKLaunchPad.h"
#import "AppDelegate.h"
#import "SharingOptionsOnlyRKModule.h"
#import "ExternalIDRKModule.h"
#import "FeedbackRKModule.h"

@interface ProfileRKLaunchPad ()

@property (nonatomic, strong) SharingOptionsOnlyRKModule *sharingModule;
@property (nonatomic, strong) ExternalIDRKModule *externalIDModule;
@property (nonatomic, strong) FeedbackRKModule *feedbackModule;

@end

@implementation ProfileRKLaunchPad

-(void)viewDidLoad
{
    if (self.shouldShowSharingOptions)
    {
        self.shouldShowSharingOptions = NO;
        self.sharingModule = [[SharingOptionsOnlyRKModule alloc] init];
        self.sharingModule.presentingVC = self;
        [self.sharingModule showSharing];
    }
//    else if (self.shouldShowReviewConsent)
//    {
//        self.shouldShowReviewConsent = NO;
//        self.consentOnlyModule = [[ReviewConsentOnlyRKModule alloc] init];
//        self.consentOnlyModule.presentingVC = self;
//        [self.consentOnlyModule showConsentReview];
//    }
    else if (self.shouldShowExternalID)
    {
        self.shouldShowExternalID = NO;
        self.externalIDModule = [[ExternalIDRKModule alloc] init];
        self.externalIDModule.presentingVC = self;
        [self.externalIDModule showExternalID];
    }
    else if (self.shouldShowFeedback)
    {
        self.shouldShowFeedback = NO;
        self.feedbackModule = [[FeedbackRKModule alloc] init];
        self.feedbackModule.presentingVC = self;
        [self.feedbackModule showFeedback];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
