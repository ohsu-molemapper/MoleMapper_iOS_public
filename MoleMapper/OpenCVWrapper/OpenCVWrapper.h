//
//  OpenCVWrapper.h
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
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface CCStats : NSObject
{
    int _cc_count;
    int32_t *_pStats;
    double *_pCentroids;
}
@property int ccCount;
@property int32_t *pStats;
@property double *pCentroids;
@end


@interface OpenCVWrapper : NSObject

// Helper constants
// NOTE: OpenCV _typically_ loads in images in BGR order. That is how it is documented and how it works in the Python version
// of OpenCV on the Mac. Of course on the iPhone it behaves differently. It loads RGB.
typedef NS_ENUM(NSUInteger, ColorChannels) {
    kBlueChannel = 2,
    kGreenChannel = 1,
    kRedChannel = 0
};

// OpenCV interface

// get OpenCV Version
+(NSString *) VersionString;
+(UIImage *) makeGrayFromImage:(UIImage *) image;
+(UIImage *) extractChannelFromBGRImage:(UIImage *) image channel:(ColorChannels)channel;
+(UIImage *) gaussianBlur:(UIImage *)image kernelSize:(CGSize)kernelSize sigmaX:(double)sigmaX sigmaY:(double)sigmaY borderType:(int)borderType;
+(UIImage *) adaptiveThreshold:(UIImage*)image blockSize:(int)blockSize offset:(int)C thresholdType:(int)thresholdType;
+(UIImage *) getStructuringElement:(int)shape ksize:(CGSize)ksize;
+(UIImage *) morphologyEx:(UIImage*)image operation:(int)operation kernel:(UIImage *)kernel;
+(UIImage *) connectedComponentsWithStats:(UIImage*)image stats:(CCStats*)stats;
+(UIImage *) floodFillCCs:(UIImage*) labels ccCount:(int)ccCount;
+(UIImage *) whiteFillCCs:(UIImage*) labels ccCount:(int)ccCount;
+(UIImage *) erode:(UIImage*)image kernel:(UIImage *)kernel;
+(UIImage *) dilate:(UIImage*)image kernel:(UIImage *)kernel;
+(UIImage *) circle:(UIImage*)image center:(CGPoint) pt radius:(double) radius;
+(void) findEnclosingCircle:(UIImage*) labels stats:(CCStats*)stats seedPoint:(CGPoint) seedPoint ptrCenter:(CGPoint*) pCenter ptrRadius:(double*) pRadius ptrBlobArea:(double*) pBlobArea;
+(UIImage *) pruneEdgelikeComponents:(UIImage*) labels stats:(CCStats*)stats biggerThan:(int)sizeThreshold;
@end

