//
//  CircularTransition.swift
//  Spreebie
//
//  Created by Thabo David Klass on 14/02/2017.
//  Copyright © 2017 Spreebie, Inc. All rights reserved.
//

import UIKit

/// This is the circular transition used in the segue process
class CircularTransition: NSObject {
    var circle = UIView()
    
    var startingPoint = CGPoint.zero {
        didSet {
            circle.center = startingPoint
        }
    }
    
    var circleColor = UIColor.white
    var duration = 0.5
    
    enum CircularTransitionMode:Int {
        case present, dismiss, pop
    }
    
    var transitionMode: CircularTransitionMode = .present
    
    var forward = true
}


// The CircularTransition extension
extension CircularTransition: UIViewControllerAnimatedTransitioning {
    
    /**
     This deals with the duration of the transition.
     
     - Parameters:
     - transitionContext: The transition context
     
     - Returns: the duration in TimeInterval form.
     */
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    
    /**
     This actual transition animation.
     
     - Parameters:
     - transitionContext: The transition context
     
     - Returns: nothing.
     */
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        if self.forward {
            if let presentedView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
                let viewCenter = presentedView.center
                let viewSize = presentedView.frame.size
                
                circle = UIView()
                
                circle.frame = frameForCircle(withViewCenter: viewCenter, size: viewSize, startPoint: startingPoint)
                
                circle.layer.cornerRadius = circle.frame.size.height / 2
                circle.center = startingPoint
                circle.backgroundColor = circleColor
                circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                containerView.addSubview(circle)
                
                presentedView.center = startingPoint
                presentedView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                presentedView.alpha = 0
                containerView.addSubview(presentedView)
                
                UIView.animate(withDuration: duration, animations: {
                    self.circle.transform = CGAffineTransform.identity
                    presentedView.transform = CGAffineTransform.identity
                    presentedView.alpha = 1
                    presentedView.center = viewCenter
                }, completion: { (success: Bool) in
                    transitionContext.completeTransition(success)
                })
            }
        } else {
            guard
                let fromViewController = transitionContext.viewController(forKey: .from),
                let toViewController = transitionContext.viewController(forKey: .to)
                else {
                    return
            }
            
            transitionContext.containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
            
            let duration = self.transitionDuration(using: transitionContext)
            UIView.animate(withDuration: duration, animations: {
                fromViewController.view.alpha = 0
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
    
    /**
     This is the frame for the circle that contains the transition
     
     - Parameters:
     - viewCenter: The center or origin of the view
     - viewSize: The size of the view to be presented
     - startPoint: The starting point of the transition - where it starts to spread from
     
     - Returns: the "container" or "frame" in CGRect form.
     */
    func frameForCircle(withViewCenter viewCenter: CGPoint, size viewSize:CGSize, startPoint: CGPoint) -> CGRect {
        let xLength = fmax(startPoint.x, viewSize.width - startPoint.x)
        let yLength = fmax(startPoint.y, viewSize.height - startPoint.y)
        
        let offsetVector = sqrt(xLength * xLength + yLength * yLength) * 2
        let size = CGSize(width: offsetVector, height: offsetVector)
        
        return CGRect(origin: CGPoint.zero, size: size)
    }
}
