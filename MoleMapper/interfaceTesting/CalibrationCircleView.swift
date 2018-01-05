//
// CalibrationCircleView.swift
// MoleMapper
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

import UIKit

class CalibrationCircleView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        //self.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        self.backgroundColor = UIColor.clear
        self.layer.borderColor = UXConstants.mmRed.cgColor
        self.layer.borderWidth = 2.0
    }
    
    convenience init(position: CirclePosition) {
        let frame = CGRect(x: position.center.x - position.radius,
                           y: position.center.y - position.radius,
                           width: position.radius * 2.0,
                           height: position.radius * 2.0)
        self.init(frame: frame)
    }
    
    convenience init() {
        let frame = CGRect(x: -10,
                           y: -10,
                           width: 5,
                           height: 5)
        self.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func repositionCircle(position: CirclePosition) {
        let diameter = position.radius * 2.0        
        self.snp.remakeConstraints { (make) in
            make.width.equalTo(diameter)
            make.height.equalTo(diameter)
            make.left.equalTo(self.superview!.snp.left).offset(position.center.x - position.radius)
            make.top.equalTo(self.superview!.snp.top).offset(position.center.y - position.radius)
        }
        self.layer.cornerRadius = position.radius
    }
    
    func setBorderColor(borderColor: CGColor) {
        self.layer.borderColor = borderColor
    }
}
