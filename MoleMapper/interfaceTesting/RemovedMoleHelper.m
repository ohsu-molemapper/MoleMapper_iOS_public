//
// RemovedMoleHelper.m
// MoleMapper
//
// Created by Tracy Petrie on 2/15/17.
// Copyright (c) 2017, OHSU. All rights reserved.
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


#import "RemovedMoleHelper.h"

@implementation RemovedMoleHelper

///
// One-based indexes (aka "Natural index") reserving zero for
// invalid or unanswered (skipped) answer
//
// Note: currently these functions operate on a simple index == numeric answer
// model but once deployed, these can never change. Changing the order of the
// questions will require a more intricate mapping scheme to keep these first
// answers with these ordinal values.
//
+(NSNumber*) indexFromAnswer:(NSString*)answer fromChoices:(NSArray*)choices
{
    int index = 0;
    for (NSString *choice in choices)
    {
        index += 1;
        if ([answer isEqualToString:(choice)])
        {
            break;
        }
    }
    if (index > [choices count])
    {
        index = 0;
    }
    
    return [NSNumber numberWithInt:index];
}

+(NSNumber*) indexFromOutcomeAnswer:(NSString*)answer
{
    return [RemovedMoleHelper indexFromAnswer:answer fromChoices:[RemovedMoleHelper getOutcomeAnswers]];
}

+(NSNumber*) indexFromInitiatorAnswer:(NSString*)answer
{
    return [RemovedMoleHelper indexFromAnswer:answer fromChoices:[RemovedMoleHelper getInitiatorAnswers]];
}

+(NSString *) answerFromOutcomeIndex:(NSNumber *)index
{
    NSArray *outcomeAnswers = [RemovedMoleHelper getOutcomeAnswers];
    if ((index >= 0) && ([index integerValue] < [outcomeAnswers count]))
    {
        return [outcomeAnswers objectAtIndex:index];
    } else {
        return nil;
    }
}

+(NSString *) answerFromInitiatorIndex:(NSNumber *)index
{
    NSArray *initiateAnswers = [RemovedMoleHelper getInitiatorAnswers];
    if ((index >= 0) && ([index integerValue] < [initiateAnswers count]))
    {
        return [initiateAnswers objectAtIndex:index];
    } else {
        return nil;
    }
}


+(NSArray *) getOutcomeDescriptions
{
    return @[@"It WAS cancer, and they needed to remove more.",
             @"It was NOT cancer, but they needed to remove more." ,
             @"It was benign/normal and didn't need more treatment.",
             @"I'm not sure what the results were."];
}

+(NSArray *) getOutcomeAnswers
{
    return @[@"cancer", @"other", @"benign", @"unknown"];
}

+(NSArray *) getInitiatorDescriptions {
    return @[@"I did.",
             @"My doctor did.",
             @"We both did."];
}

+(NSArray *) getInitiatorAnswers {
    return @[@"me",@"doctor",@"both"];
}

+(NSDictionary *)createFromNumericAnswers:(NSNumber*)moleID andWithOutcome:(NSNumber*)outcomeAnswer andWithInitiator:(NSNumber *)initiatorAnswer {
    NSDictionary *response = @{@"moleID" : moleID,
                               @"outcome" : outcomeAnswer,
                               @"initiator" : initiatorAnswer};
    
    return response;
}

//+(RemovedMoleHelper *)initWithTextAnswers:(NSString*)moleID andWithOutcome:(NSString*)outcomeAnswer andWithInitiate:(NSString *)initiateAnswer {
//    RemovedMoleHelper *rcd = [[RemovedMoleHelper alloc] init];
//
//    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
//    fmt.numberStyle = NSNumberFormatterDecimalStyle;
//    
//    rcd.moleID = [fmt numberFromString:moleID];
//    rcd.outcomeAnswer = [RemovedMoleHelper indexFromOutcomeAnswer:outcomeAnswer];
//    rcd.initiateAnswer = [RemovedMoleHelper indexFromInitiateAnswer:initiateAnswer];
//    
//    return rcd;
//}

///
// Returns a dictionary with the keys needed to push to the Bridge server
//-(NSDictionary *)asBridgeDictionary
//{
//    NSString *strMoleID = [self.moleID stringValue];
//    NSDictionary *response = @{@"moleID" : strMoleID,
//                               @"outcome" : self.outcomeAnswer,
//                               @"initiator" : self.initiateAnswer};
//    
//    return response;
//}
//

@end
