//
//  ContainerAnimation.swift
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

import UIKit

/**
    Animations
 
    - toLeft: new ViewController comes in from the right pushing the old ViewController off to the left.
        Good for "next" transitions.
    - toRight: new ViewController comes in from the left pushing the old ViewController off to the right. 
        Good for "back" transitions.
    - none: no animation, just immediately display the new VC over the old VC.
 */
enum ContainerTransitionDirection {
    case toLeft, toRight, none
}

/**
    Helper methods to manage transitions for container controllers.
 */
class ContainerTransitions {

    /**
     Directly switches to new ViewController (no animation). 
     
     - Parameters:
     - startingVC: the ViewController to be swapped out
     - endingVC: the ViewController to swap in
     
     - Returns: nothing
     */
    class func switchTo(containerVC: UIViewController, fromVC: UIViewController, toVC: UIViewController) {
        fromVC.willMove(toParentViewController: nil)
        fromVC.view.removeFromSuperview()
        fromVC.removeFromParentViewController()
        
        containerVC.addChildViewController(toVC)
        toVC.view.frame = UIScreen.main.bounds
        containerVC.view.addSubview(toVC.view)
        toVC.didMove(toParentViewController: containerVC)
    }

    /**
        Helper method for Container View Controllers to transition contained VCs in an animated fashion (akin to
        NavigationControllers but potentially extendable in the future).
     
        - Parameters:
            - containerVC: the ContainerVC that gets children VCs added.
            - fromVC: the ViewController that will disappear
            - toVC: the ViewController that will appear
     */
    class func switchToWithAnimation(containerVC: UIViewController, fromVC: UIViewController, toVC: UIViewController, direction: ContainerTransitionDirection) {
        if direction == .none {
            ContainerTransitions.switchTo(containerVC: containerVC, fromVC: fromVC, toVC: toVC)
        } else {
            fromVC.willMove(toParentViewController: nil)
            containerVC.addChildViewController(toVC)
//            let finalFrame = UIScreen.main.bounds
            // NOTE: the choice to use the frame or the bounds is pathologically tied to whether the navigation bar
            // is set to transparent or not!!
            let finalFrame = containerVC.view.bounds
            var exitingFrame = finalFrame
            var enteringFrame = finalFrame
            if direction == .toLeft {
                exitingFrame.origin.x -= finalFrame.size.width
                enteringFrame.origin.x += finalFrame.size.width
            } else {
                exitingFrame.origin.x += finalFrame.size.width
                enteringFrame.origin.x -= finalFrame.size.width
            }
            toVC.view.frame = enteringFrame
            containerVC.view.addSubview(toVC.view)
            containerVC.transition(from: fromVC , to: toVC, duration: 0.25, options: .curveEaseOut, animations: {
                fromVC.view.frame = exitingFrame
                toVC.view.frame = finalFrame
            }, completion:  { (Bool) in
                fromVC.removeFromParentViewController()
                fromVC.view.removeFromSuperview()
                toVC.didMove(toParentViewController: containerVC)
            } )
        }
    }
}
