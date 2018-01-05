//
//  OpenCVWrapper.mm
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
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"

static const unsigned int STAT_COLS = 5;    // for 3.0; somewhere by 3.3 it became 6
////
//
//  CCStats Implementation
//
//

@implementation CCStats
-(id)init {
    if (self = [super init]) {
        self.pStats = NULL;
        self.pCentroids = NULL;
        self.ccCount = 0;
        return self;
    } else {
        return nil;
    }
}

-(id)initWithData:(int) ccs statsPtr:(int32_t*)statsPtr centsPtr:(double*)centsPtr
{
    if (self = [super init]) {
        self.pStats = statsPtr;
        self.pCentroids = centsPtr;
        self.ccCount = ccs;
        return self;
    } else {
        return nil;
    }
    
}

-(void)finalize
{
    if (NULL != self.pStats) { free(self.pStats); }
    if (NULL != self.pCentroids) { free(self.pCentroids); }
    [super finalize];
}

@end

////
//
//  OpenCVWrapper Implementation
//
//

@implementation OpenCVWrapper

+(NSString *) VersionString
{
    cv::Mat x;
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

+(UIImage *) makeGrayFromImage:(UIImage *) image
{
    cv::Mat imageMat;
    UIImageToMat(image, imageMat);
    
    // If image was already grayscale, return it
    if (imageMat.channels() == 1) return image;
    
    cv::Mat grayMat;
    cv::cvtColor(imageMat, grayMat, CV_BGR2GRAY);
    
    return MatToUIImage(grayMat);
}

+(UIImage *) extractChannelFromBGRImage:(UIImage *) image channel:(ColorChannels)channel
{
    cv::Mat imageMat;
    UIImageToMat(image, imageMat);
    
    // If image was already grayscale, return it
    if (imageMat.channels() == 1) return image;
    
    cv::Mat grayMat;
    cv::extractChannel(imageMat, grayMat, channel);
    
    return MatToUIImage(grayMat);
}

+(UIImage *) gaussianBlur:(UIImage *)image kernelSize:(CGSize)kernelSize sigmaX:(double)sigmaX sigmaY:(double)sigmaY borderType:(int)borderType
{
    cv::Mat imageMat;
    UIImageToMat(image, imageMat);
    UIImage *blurredImage;
    
    if (imageMat.channels() == 1) {
        cv::Mat blurredMat = imageMat.clone();
        cv::Size ksize = cv::Size(kernelSize.width, kernelSize.height);
        cv::GaussianBlur(imageMat, blurredMat, ksize, sigmaX, sigmaY, borderType);
        blurredImage = MatToUIImage(blurredMat);
    } else {
        // TBD; look at split and merge
    }
    
    return blurredImage;
}


+(UIImage *) adaptiveThreshold:(UIImage*)image blockSize:(int)blockSize offset:(int)C thresholdType:(int)thresholdType
{
    cv::Mat imageMat;
    UIImageToMat(image, imageMat);
    UIImage *thresholdImage;
    
    if (imageMat.channels() == 1) {
        cv::Mat threshMat = imageMat.clone();
        if (thresholdType == 0) {
            cv::adaptiveThreshold(imageMat, threshMat, 255, cv::AdaptiveThresholdTypes::ADAPTIVE_THRESH_MEAN_C, cv::ThresholdTypes::THRESH_BINARY, blockSize, C);
        } else {
            cv::adaptiveThreshold(imageMat, threshMat, 255, cv::AdaptiveThresholdTypes::ADAPTIVE_THRESH_MEAN_C, cv::ThresholdTypes::THRESH_BINARY_INV, blockSize, C);
        }
        
        thresholdImage = MatToUIImage(threshMat);
    } else {
        // TBD; look at split and merge
    }
    
    return thresholdImage;
}

+(UIImage *) getStructuringElement:(int)shape ksize:(CGSize)elementSize
{
    cv::Size ksize;
    ksize.width = elementSize.width;
    ksize.height = elementSize.height;
    cv::Mat sel = cv::getStructuringElement(shape,ksize);
    
    return MatToUIImage(sel);
}

+(UIImage *) morphologyEx:(UIImage*)image operation:(int)operation kernel:(UIImage *) kernel;
{
    cv::Mat imgSrcMat;
    cv::Mat imgDestMat;
    cv::Mat kMat;
    
    UIImageToMat(image, imgSrcMat);
    imgDestMat = imgSrcMat.clone();
    UIImageToMat(kernel, kMat);
    
    cv::morphologyEx(imgSrcMat, imgDestMat, operation, kMat);
    
    return MatToUIImage(imgDestMat);
}


+(UIImage *) connectedComponentsWithStats:(UIImage*)image stats:(CCStats*)stats
{
    cv::Mat imageMat;
    cv::Mat labelsMat;
    cv::Mat statsMat;
    cv::Mat centroidsMat;
    UIImageToMat(image, imageMat);
    imageMat.copyTo(labelsMat);
    int CCCount = cv::connectedComponentsWithStats(imageMat,labelsMat,statsMat,centroidsMat);
    stats.ccCount = CCCount;
    
    // allocate and copy stats
    stats.pStats = (int32_t*)calloc(CCCount * STAT_COLS, sizeof(int32_t));
    // allocate and copy centroids
    stats.pCentroids = (double*)calloc(CCCount * 2, sizeof(double));
    // WHERE ARE THESE DEALLOCATED?
    
    int *pStats = stats.pStats;
    int *pCVStats = (int*)statsMat.ptr(0);
    double *pCentroids = stats.pCentroids;
    double *pCVCentroids = (double*)centroidsMat.ptr(0);
    double *dbg;
    for (int ccs=0; ccs < CCCount; ccs++) {
        // Making assumption for now that memory is continuous and we don't need to worry about strides
        for (int statcount=0; statcount < STAT_COLS; statcount++) {
            *pStats++ = *pCVStats++;
        }
        for (int centcount=0; centcount < 2; centcount++) {
            *pCentroids++ = *pCVCentroids++;
        }
        dbg = stats.pCentroids;
    }
    
    return MatToUIImage(labelsMat);
}

+(UIImage *) floodFillCCs:(UIImage*) labels ccCount:(int)ccCount
{
    cv::Mat rgbMat;
    cv::Mat labelsMat;
    uint8_t *RGB = (uint8_t*)calloc(ccCount*3, sizeof(uint8_t));
    
    // Create color image
    UIImageToMat(labels, labelsMat);
    rgbMat.create( labelsMat.rows, labelsMat.cols, CV_8UC3);
    
    // Create RGB color list
    uint8_t R,G,B;
    // first label is always black. Calloc makes it so...
    for (int n=1; n < ccCount; n++) {
        R = arc4random() % 255;
        G = arc4random() % 255;
        B = arc4random() % 255;
        
        unsigned int ndx = n*3;
        RGB[ndx] = R;
        RGB[ndx+1] = G;
        RGB[ndx+2] = B;
    }
    
    // Now color in the pixels by label
    for (int row = 0; row < rgbMat.rows; ++row)
    {
        uchar *rgbptr = rgbMat.ptr(row);
        uint32_t *labelptr = (uint32_t*)labelsMat.ptr(row);
        for (int col = 0; col < rgbMat.cols; col++)
        {
            unsigned int ndx = (*labelptr) * 3;
            rgbptr[0] = RGB[ndx];
            rgbptr[1] = RGB[ndx+1];
            rgbptr[2] = RGB[ndx+2];
            rgbptr += 3;
            labelptr++;
        }
    }
    
    free(RGB);
    return MatToUIImage(rgbMat);
    
}

+(UIImage *) whiteFillCCs:(UIImage*) labels ccCount:(int)ccCount
{
    cv::Mat binaryMat;
    cv::Mat labelsMat;
    
    // Create color image
    UIImageToMat(labels, labelsMat);
    binaryMat.create( labelsMat.rows, labelsMat.cols, CV_8UC1);
    
    // Now color in the pixels by label
    for (int row = 0; row < binaryMat.rows; ++row)
    {
        uchar *binptr = binaryMat.ptr(row);
        uint32_t *labelptr = (uint32_t*)labelsMat.ptr(row);
        for (int col = 0; col < binaryMat.cols; col++)
        {
            if (*labelptr > 0) {
                *binptr = 255;
            } else {
                *binptr = 0;
            }
            binptr++;
            labelptr++;
        }
    }
    
    return MatToUIImage(binaryMat);
}

+(UIImage *) erode:(UIImage*)image kernel:(UIImage *)kernel
{
    cv::Mat imgSrcMat;
    cv::Mat imgDestMat;
    cv::Mat kMat;
    
    UIImageToMat(image, imgSrcMat);
    imgDestMat = imgSrcMat.clone();
    UIImageToMat(kernel, kMat);
    
    cv::erode(imgSrcMat, imgDestMat, kMat);
    
    return MatToUIImage(imgDestMat);
}

+(UIImage *) dilate:(UIImage*)image kernel:(UIImage *)kernel
{
    cv::Mat imgSrcMat;
    cv::Mat imgDestMat;
    cv::Mat kMat;
    
    UIImageToMat(image, imgSrcMat);
    imgDestMat = imgSrcMat.clone();
    UIImageToMat(kernel, kMat);
    
    cv::dilate(imgSrcMat, imgDestMat, kMat);
    
    return MatToUIImage(imgDestMat);
}

+(UIImage *) circle:(UIImage*)image center:(CGPoint) pt radius:(double) radius
{
    cv::Mat imgSrcMat;
    cv::Mat imgDestMat;
    
    UIImageToMat(image, imgSrcMat);
    
    cv::circle(imgSrcMat, cv::Point(pt.x, pt.y), radius, cv::Scalar(255,0,255), 3);
    
    return MatToUIImage(imgSrcMat);
}

+(void) findEnclosingCircle:(UIImage*) labels stats:(CCStats*)stats seedPoint:(CGPoint) seedPoint ptrCenter:(CGPoint*) pCenter ptrRadius:(double*) pRadius ptrBlobArea:(double*) pBlobArea {
    // Find centroid closest to seed point
    int ccs = stats.ccCount;
    double x,y;
    int bestCentroid = -1;
    double closestDistance = DBL_MAX;
    cv::Mat labelsMat;
    UIImageToMat(labels, labelsMat);
    
    double currentDistance;
    for (int n=1; n < ccs; n++) {       // Always ignore 1st CC (background)
        x = stats.pCentroids[n*2+0];
        y = stats.pCentroids[n*2+1];
        //        NSLog(@"Centroid: %f, %f",x,y);
        currentDistance = pow((x - seedPoint.x),2) + pow((y - seedPoint.y),2);    // sqrt is monotonic, no need to waste CPU cycles
        if (currentDistance < closestDistance) {
            closestDistance = currentDistance;
            bestCentroid = n;
        }
    }
    
    // Now assemble array of points with that label. So much simpler in Python :-(
    // See minarea.cpp in OpenCV examples
    std::vector<cv::Point> points;
    int pointcount = 0;
    for (int row = 0; row < labelsMat.rows; ++row)
    {
        uint32_t *labelptr = (uint32_t*)labelsMat.ptr(row);
        for (int col = 0; col < labelsMat.cols; col++)
        {
            if (*labelptr == bestCentroid) {
                pointcount++;
                cv::Point pt;
                pt.x = col;         // Is this orientation dependent? In the end, probably not (given we're looking for R)
                pt.y = row;
                
                points.push_back(pt);
            }
            labelptr++;
        }
    }
    // Store in Mat structure
    cv::Mat pointsMat = cv::Mat(points);
    
    cv::Point2f center;
    float R;
    cv::minEnclosingCircle(pointsMat, center, R);
    pCenter->x = center.x;
    pCenter->y = center.y;
    *pRadius = R;
    if (bestCentroid > 0) {
        *pBlobArea = stats.pStats[bestCentroid * STAT_COLS + cv::CC_STAT_AREA];
    } else {
        *pBlobArea = 0;
    }
}

+(UIImage *) pruneEdgelikeComponents:(UIImage*) labels stats:(CCStats*)stats biggerThan:(int)sizeThreshold {
    // Find centroid closest to seed point
    int ccs = stats.ccCount;
    cv::Mat prunedLabelsMat;
    cv::Mat labelsMat;
    UIImageToMat(labels, labelsMat);
    // Create color image
    //    prunedLabelsMat = labelsMat.clone();
    int rowcount = labelsMat.rows;
    int colcount = labelsMat.cols;
    //    prunedLabelsMat.create( labelsMat.rows, labelsMat.cols, CV_32SC1);
    prunedLabelsMat.create( rowcount, colcount, CV_32SC1);
    uint32_t *bigCCs = (uint32_t*)calloc(stats.ccCount, sizeof(uint32_t));
    unsigned int bigCCcount = 0;
    
    
    for (int n=1; n < ccs; n++) {       // Always ignore 1st CC (background)
        int width = stats.pStats[n*STAT_COLS + cv::CC_STAT_WIDTH];
        int height = stats.pStats[n*STAT_COLS + cv::CC_STAT_HEIGHT];
        if ((width > sizeThreshold) || (height > sizeThreshold)) {
            //            NSLog(@"pruning cc with width = %d and height = %d", width,height);
            bigCCs[bigCCcount] = n;
            bigCCcount++;
        } else {
            //            NSLog(@"NOT pruning cc with width = %d and height = %d", width,height);
        }
    }
    // First, copy ALL the labels
    for (int row = 0; row < prunedLabelsMat.rows; ++row)
    {
        uint32_t *labelptr = (uint32_t*)labelsMat.ptr(row);
        uint32_t *prunedLabelptr = (uint32_t*)prunedLabelsMat.ptr(row);
        for (int col = 0; col < prunedLabelsMat.cols; col++)
        {
            uint32_t label = *labelptr;
            for (int cc=0; cc < bigCCcount; cc++) {
                if (*labelptr == bigCCs[cc]) {
                    label = 0;
                }
            }
            *prunedLabelptr = label;
            labelptr++;
            prunedLabelptr++;
        }
    }
    free(bigCCs);
    return MatToUIImage(prunedLabelsMat);
}

@end
