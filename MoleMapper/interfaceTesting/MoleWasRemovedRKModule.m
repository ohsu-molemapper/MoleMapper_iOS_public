//
//  MoleWasRemovedRKModule.m
//  MoleMapper
//
//  Created by Dan Webster on 9/25/15.
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


#import "MoleWasRemovedRKModule.h"
#import "AppDelegate.h"
#import "RemovedMoleHelper.h"

@implementation MoleWasRemovedRKModule

-(void)showMoleRemoved
{
    ORKOrderedTask *task = nil;
    
    // What was the outcome?
    NSArray *choiceDescriptions = [RemovedMoleHelper getOutcomeDescriptions];
    NSArray *choiceValues = [RemovedMoleHelper getOutcomeAnswers];
    NSMutableArray *outcomeChoices = [NSMutableArray arrayWithCapacity:[choiceValues count]];
    for (uint indx=0; indx < [choiceValues count]; indx++)
    {
        ORKTextChoice *question = [ORKTextChoice choiceWithText:choiceDescriptions[indx] value:choiceValues[indx]];
        [outcomeChoices addObject:question];
    }
    ORKTextChoiceAnswerFormat *outcome = [ORKAnswerFormat choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice textChoices:outcomeChoices];
    
    ORKQuestionStep *outcomeStep = [ORKQuestionStep questionStepWithIdentifier:@"outcome"
                                                                            title:@"What was the outcome of your mole removal?"
                                                                           answer:outcome];
    
    // Who initiated?
    choiceDescriptions = [RemovedMoleHelper getInitiatorDescriptions];
    choiceValues = [RemovedMoleHelper getInitiatorAnswers];
    NSMutableArray *initiatorChoices = [NSMutableArray arrayWithCapacity:[choiceValues count]];
    for (uint indx=0; indx < [choiceValues count]; indx++)
    {
        ORKTextChoice *question = [ORKTextChoice choiceWithText:choiceDescriptions[indx] value:choiceValues[indx]];
        [initiatorChoices addObject:question];
    }

    ORKTextChoiceAnswerFormat *who = [ORKAnswerFormat choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice textChoices:initiatorChoices];
    
    ORKQuestionStep *whoStep = [ORKQuestionStep questionStepWithIdentifier:@"who"
                                                                     title:@"Who initiated the removal?"
                                                                    answer:who];
    
    // Site Photo Request Step
    ORKInstructionStep *sitePhotoStep = [[ORKInstructionStep alloc] initWithIdentifier:@"sitePhoto"];
    sitePhotoStep.title = @"Biopsy Site Photo";
    sitePhotoStep.text = @"When it is safe to do so without a bandage, please measure the area where the mole was removed in the same way you would measure your mole.\n\nThis will help us understand the results of your procedure.";
    sitePhotoStep.image = [UIImage imageNamed:@"photoOfScar"];
    
    // Thank You Step
    ORKInstructionStep *thankYouStep = [[ORKInstructionStep alloc] initWithIdentifier:@"thankYou"];
    thankYouStep.title = @"Thank you";
    thankYouStep.text = @"\nThe data you are contributing to this research will help us to understand and prevent skin cancer.";

    // Assemble and present
    task = [[ORKOrderedTask alloc] initWithIdentifier:@"task" steps:@[outcomeStep,whoStep,sitePhotoStep,thankYouStep]];
    
    ORKTaskViewController *taskViewController =
    [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = self;
    [self.presentingVC presentViewController:taskViewController animated:YES completion:nil];

}

- (void)taskViewController:(ORKTaskViewController *)taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason
                     error:(NSError *)error
{
    
    ORKTaskResult *taskResult = [taskViewController result];
    
    switch (reason)
    {
        case ORKTaskViewControllerFinishReasonCompleted:
        {
            //Structure of internal data for removedMolesToDiagnoses
            // Old structure:
            // "moleID" -> (NSNumber *)moleID,
            // "diagnoses -> (NSArray *)[array of diagnoses (NSStrings)]
            // New structure:
            // "moleID" -> (NSNumber *)moleID,
            // "outcome" -> (NSNumber *)moleID,
            // "initiator" -> (NSNumber *)moleID,


            NSDictionary *parsedData = [self parsedDataFromTaskResult:taskResult];
            NSNumber *moleID = self.removedMole.moleID;
            NSDictionary *removedMoleRecord = [RemovedMoleHelper createFromNumericAnswers:moleID
                                                                           andWithOutcome:parsedData[@"outcome"]
                                                                         andWithInitiator:parsedData[@"initiator"] ];
            AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
            NSMutableArray *removedMolesToDiagnoses = [ad.user.removedMolesToDiagnoses mutableCopy];
            NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
            for (int index = 0; index < removedMolesToDiagnoses.count; index++)
            {
                //Remove old record that has no diagnosis information in it
                NSDictionary *record = removedMolesToDiagnoses[index];
                //NSNumber *recordID = [record objectForKey:@"moleID"];
                if ([[record objectForKey:@"moleID"] isEqualToNumber: moleID])
                //if ([recordID intValue] == [moleID intValue])
                {
                    //[removedMolesToDiagnoses replaceObjectAtIndex:i withObject:removedMoleRecord];
                    //removedMolesToDiagnoses[i] = removedMoleRecord;
                    [indexes addIndex:index];
                }
            }
            [removedMolesToDiagnoses removeObjectsAtIndexes:indexes];
            
            //Store updated set of records in user object
            ad.user.removedMolesToDiagnoses = removedMolesToDiagnoses;
            
            [ad.bridgeManager signInAndSendRemovedMoleData:removedMoleRecord];
            
            break;
            
        }
            
        case ORKTaskViewControllerFinishReasonFailed:
        {
            break;
        }
        case ORKTaskViewControllerFinishReasonDiscarded:
        {
            break;
        }
            
        case ORKTaskViewControllerFinishReasonSaved:
        {
            break;
        }
    }
    
    [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
}

-(NSDictionary *)parsedDataFromTaskResult:(ORKTaskResult *)taskResult
{
    NSMutableDictionary *parsedData = [NSMutableDictionary dictionary];
    NSArray *answer = @[];
    NSNumber *outcome = @0;
    NSNumber *initiator = @0;
    
    NSArray *firstLevelResults = taskResult.results;
    for (ORKCollectionResult *firstLevel in firstLevelResults)
    {
        if ([firstLevel.identifier isEqualToString:@"outcome"])
        {
            for (ORKStepResult *secondLevel in firstLevel.results)
            {
                if ([secondLevel isKindOfClass:[ORKChoiceQuestionResult class]])
                {
                    answer = ((ORKChoiceQuestionResult*)secondLevel).choiceAnswers;
                    if ((answer != nil) && ([answer count] > 0))
                    {
                        NSString *choice = answer[0];
                        outcome = [RemovedMoleHelper indexFromOutcomeAnswer:choice];
                    }
               }
            }
        }
        else if ([firstLevel.identifier isEqualToString:@"who"])
        {
            for (ORKStepResult *secondLevel in firstLevel.results)
            {
                if ([secondLevel isKindOfClass:[ORKChoiceQuestionResult class]])
                {
                    answer = ((ORKChoiceQuestionResult*)secondLevel).choiceAnswers;
                    if ((answer != nil) && ([answer count] > 0))
                    {
                        NSString *choice = answer[0];
                        initiator = [RemovedMoleHelper indexFromInitiatorAnswer:choice];
                    }
                }
            }
        }
    }
    
    
    [parsedData setValue:outcome forKey:@"outcome"];
    [parsedData setValue:initiator forKey:@"initiator"];
    
    return parsedData;
}

@end
