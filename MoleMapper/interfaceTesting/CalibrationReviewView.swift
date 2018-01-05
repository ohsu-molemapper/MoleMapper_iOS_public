//
// CalibrationReviewView.swift
// MoleMapper
//
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

import UIKit

protocol CalibrationCoinReviewDelegate: class {
    func updateReviewingIndex(index: Int)
}

class CalibrationReviewView: UIView, UIScrollViewDelegate {

    weak var delegate: (CalibrationCoinReviewDelegate & CalibrationReviewAutosizedViewProtocol)?
    
    let numberOfViews = 3
    
    var pageControl: UIPageControl!
    var scrollView: UIScrollView!
    var reviewSubviews = [CalibrationReviewAutosizedView]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .black
        self.autoresizesSubviews = false
        
        scrollView = UIScrollView(frame: frame)
        scrollView.delegate = self
        scrollView.isDirectionalLockEnabled = true
        scrollView.backgroundColor = UIColor.black
        self.addSubview(scrollView)

        for viewindex in 0..<numberOfViews {
            let xOrigin: CGFloat = CGFloat(viewindex) * self.frame.width
            let tmpView = CalibrationReviewAutosizedView(frame: CGRect(x: xOrigin, y: 0, width: frame.width, height: frame.height))
            scrollView.addSubview(tmpView)
            reviewSubviews.append(tmpView)
        }
        scrollView.contentSize = CGSize(width: CGFloat(numberOfViews) * self.frame.width, height: self.frame.height)
        scrollView.isPagingEnabled = true
        
        pageControl = UIPageControl()
        pageControl.numberOfPages = numberOfViews
        pageControl.currentPage = 0
        pageControl.addTarget(self, action: #selector(self.changePage), for: .valueChanged)
        self.addSubview(pageControl)
        
        pageControl.snp.makeConstraints { (ctl) in
            ctl.width.equalTo(60)
            ctl.centerX.equalTo(self.snp.centerX)
            ctl.bottom.equalTo(self.snp.bottom).offset(-10)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    // Does this copy the images (value vs. reference type)??
    func loadImageData(imageDataSet: [CalibrationData]) {
        for viewindex in 0..<imageDataSet.count {
            reviewSubviews[viewindex].setImage(image: imageDataSet[viewindex].fixableData.fixableImage)
            reviewSubviews[viewindex].addCoin(imageDataSet[viewindex].fixableData.fixableCircle)
            reviewSubviews[viewindex].delegate = self.delegate
        }
    }

    func finalizeFix(frame: CGRect) {
        print("CalibrationReviewView.finalizeFix : \(frame)")
    }
    

    /**
    circlePosition is relative to image
    */
    func updateCirclePosition(circlePosition: CirclePosition, viewIndex: Int) {
        reviewSubviews[viewIndex].updateCoin(newPosition: circlePosition)
    }

    // MARK - UIScrollViewDelegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        if page != self.pageControl.currentPage {
            self.pageControl.currentPage = page
            delegate?.updateReviewingIndex(index: page)
        }
    }
    
    func changePage() {
        let contentXOffset: CGFloat = CGFloat(self.pageControl.currentPage) * CGFloat(self.scrollView.frame.size.width)
        self.scrollView.setContentOffset(CGPoint(x: contentXOffset, y: CGFloat(0.0)), animated: true)
    }
    
}
