// CoachMarkDisplayManager.swift
//
// Copyright (c) 2015 Frédéric Maquin <fred@ephread.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/// This class deals with the layout of coach marks.
internal class CoachMarkDisplayManager {
    //MARK: - Public properties
    weak var dataSource: CoachMarksControllerDataSource!

    unowned let coachMarksController: CoachMarksController

    //MARK: - Private properties
    /// The coach mark metadata
    fileprivate var coachMark: CoachMark!

    /// The coach mark view (the one displayed)
    fileprivate var coachMarkView: CoachMarkView!

    /// The overlayView (covering everything and showing cutouts)
    fileprivate let overlayView: OverlayView

    /// The view holding the coach marks
    fileprivate let instructionsTopView: UIView

    //MARK: - Initialization
    /// Allocate and initialize the manager.
    ///
    /// - Parameter overlayView: the overlayView (covering everything and showing cutouts)
    /// - Parameter instructionsTopView: the view holding the coach marks
    init(coachMarksController: CoachMarksController, overlayView: OverlayView, instructionsTopView: UIView) {
        self.coachMarksController = coachMarksController
        self.overlayView = overlayView
        self.instructionsTopView = instructionsTopView
    }

    func createCoachMarkViewFromCoachMark(_ coachMark: CoachMark, withIndex index: Int) -> CoachMarkView {
        // Asks the data source for the appropriate tuple of views.
        let coachMarkComponentViews = self.dataSource!.coachMarksController(coachMarksController, coachMarkViewsForIndex: index, coachMark: coachMark)

        // Creates the CoachMarkView, from the supplied component views.
        // CoachMarkView() is not a failable initializer. We'll force unwrap
        // currentCoachMarkView everywhere.
        return CoachMarkView(bodyView: coachMarkComponentViews.bodyView, arrowView: coachMarkComponentViews.arrowView, arrowOrientation: coachMark.arrowOrientation, arrowOffset: coachMark.gapBetweenBodyAndArrow)
    }

    /// Hides the given CoachMark View
    ///
    /// - Parameter coachMarkView: the coach mark to hide
    /// - Parameter animationDuration: the duration of the fade
    /// - Parameter completion: a block to execute after the coach mark was hidden
    func hideCoachMarkView(_ coachMarkView: UIView?, animationDuration: TimeInterval, completion: (() -> Void)? = nil) {
        overlayView.hideCutoutPathViewWithAnimationDuration(animationDuration)

        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            coachMarkView?.alpha = 0.0
        }, completion: {(finished: Bool) -> Void in
            coachMarkView?.removeFromSuperview()
            completion?()
        })
    }

    /// Display the given CoachMark View
    ///
    /// - Parameter coachMarkView: the coach mark view to show
    /// - Parameter coachMark: the coach mark metadata
    func displayCoachMarkView(_ coachMarkView: CoachMarkView, coachMark: CoachMark, noAnimation: Bool = false, completion: (() -> Void)? = nil) {

        self.storeCoachMark(coachMark, coachMarkView: coachMarkView, overlayView: overlayView,
                            instructionsTopView: instructionsTopView)

        self.prepareCoachMarkForDisplay()
        self.overlayView.disableOverlayTap = coachMark.disableOverlayTap

        self.clearStoredData()

        // The view shall be invisible, 'cause we'll animate its entry.
        coachMarkView.alpha = 0.0

        // Animate the view entry
        overlayView.showCutoutPathViewWithAnimationDuration(coachMark.animationDuration)

        if noAnimation {
            coachMarkView.alpha = 1.0
            completion?()
        } else {
            UIView.animate(withDuration: coachMark.animationDuration, animations: { () -> Void in
                coachMarkView.alpha = 1.0
            }, completion: {(finished: Bool) -> Void in
                completion?()
            })
        }
    }

    //MARK: - Private methods

    /// Store the necessary data (rather than passing them across all private
    /// methods.)
    ///
    /// - Parameter coachMark: the coach mark metadata
    /// - Parameter coachMarkView: the coach mark view (the one displayed)
    /// - Parameter overlayView: the overlayView (covering everything and showing cutouts)
    /// - Parameter instructionsTopView: the view holding the coach marks
    fileprivate func storeCoachMark(_ coachMark: CoachMark, coachMarkView: CoachMarkView, overlayView: OverlayView, instructionsTopView: UIView) {
        self.coachMark = coachMark
        self.coachMarkView = coachMarkView
    }

    /// Clear the stored data.
    fileprivate func clearStoredData() {
        self.coachMark = nil
        self.coachMarkView = nil
    }

    /// Add the current coach mark to the view, making sure it is
    /// properly positioned.
    fileprivate func prepareCoachMarkForDisplay() {

        // Add the view and compute its associated constraints.
        instructionsTopView.addSubview(coachMarkView)

        instructionsTopView.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "H:[currentCoachMarkView(<=\(coachMark.maxWidth))]", options: NSLayoutFormatOptions(rawValue: 0),
                metrics: nil, views: ["currentCoachMarkView": coachMarkView])
        )

        // No cutoutPath, no arrow.
        if let cutoutPath = coachMark.cutoutPath {
            let offset = coachMark.gapBetweenCoachMarkAndCutoutPath

            // Depending where the cutoutPath sits, the coach mark will either
            // stand above or below it.
            if coachMark.arrowOrientation! == .bottom {
                let coachMarkViewConstraint = NSLayoutConstraint(item: coachMarkView, attribute: .bottom, relatedBy: .equal, toItem: instructionsTopView, attribute: .bottom, multiplier: 1, constant: -(instructionsTopView.frame.size.height - cutoutPath.bounds.origin.y + offset))
                instructionsTopView.addConstraint(coachMarkViewConstraint)
            } else {
                let coachMarkViewConstraint = NSLayoutConstraint(item: coachMarkView, attribute: .top, relatedBy: .equal, toItem: instructionsTopView, attribute: .top, multiplier: 1, constant: (cutoutPath.bounds.origin.y + cutoutPath.bounds.size.height) + offset)
                instructionsTopView.addConstraint(coachMarkViewConstraint)
            }

            self.positionCoachMarkView()
            
            overlayView.updateCutoutPath(cutoutPath)
        } else {
            overlayView.updateCutoutPath(nil)
        }
    }

    /// Position the coach mark view.
    /// TODO: Improve the layout system. Make it smarter.
    fileprivate func positionCoachMarkView() {
        let layoutDirection: UIUserInterfaceLayoutDirection

        if #available(iOS 9, *) {
            layoutDirection = UIView.userInterfaceLayoutDirection(for: instructionsTopView.semanticContentAttribute)
        } else {
            layoutDirection = .leftToRight
        }

        let segmentIndex = self.computeSegmentIndexForLayoutDirection(layoutDirection)

        let horizontalMargin = coachMark.horizontalMargin
        let maxWidth = coachMark.maxWidth

        switch(segmentIndex) {
        case 1:
            instructionsTopView.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==\(horizontalMargin))-[currentCoachMarkView(<=\(maxWidth))]-(>=\(horizontalMargin))-|", options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil, views: ["currentCoachMarkView": coachMarkView])
            )

            let offset = arrowOffsetForLayoutDirection(layoutDirection, segmentIndex: segmentIndex)

            coachMarkView.changeArrowPositionTo(.leading, offset: offset)
        case 2:
            instructionsTopView.addConstraint(NSLayoutConstraint(item: coachMarkView, attribute: .centerX, relatedBy: .equal, toItem: instructionsTopView, attribute: .centerX, multiplier: 1, constant: 0))

            instructionsTopView.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=\(horizontalMargin))-[currentCoachMarkView(<=\(maxWidth)@1000)]-(>=\(horizontalMargin))-|", options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil, views: ["currentCoachMarkView": coachMarkView])
            )

            let offset = arrowOffsetForLayoutDirection(layoutDirection, segmentIndex: segmentIndex)

            coachMarkView.changeArrowPositionTo(.center, offset: offset)

        case 3:
            instructionsTopView.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=\(horizontalMargin))-[currentCoachMarkView(<=\(maxWidth))]-(==\(horizontalMargin))-|", options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: nil, views: ["currentCoachMarkView": coachMarkView])
            )

            let offset = arrowOffsetForLayoutDirection(layoutDirection, segmentIndex: segmentIndex)

            coachMarkView.changeArrowPositionTo(.trailing, offset: offset)
        default:
            break
        }
    }

    /// Returns the arrow offset, based on the layout and the
    /// segment in which the coach mark will be.
    ///
    /// - Parameter layoutDirection: the layout direction (RTL or LTR)
    /// - Parameter: segmentIndex the segment index (either 1, 2 or 3)
    fileprivate func arrowOffsetForLayoutDirection(_ layoutDirection: UIUserInterfaceLayoutDirection, segmentIndex: Int) -> CGFloat {

        let pointOfInterest = coachMark.pointOfInterest!

        var arrowOffset: CGFloat

        switch(segmentIndex) {
        case 1:
            if layoutDirection == .leftToRight {
                arrowOffset = pointOfInterest.x - coachMark.horizontalMargin
            } else {
                arrowOffset = instructionsTopView.bounds.size.width - pointOfInterest.x - coachMark.horizontalMargin
            }
        case 2:
            if layoutDirection == .leftToRight {
                arrowOffset = instructionsTopView.center.x - pointOfInterest.x
            } else {
                arrowOffset = pointOfInterest.x - instructionsTopView.center.x
            }
        case 3:
            if layoutDirection == .leftToRight {
                arrowOffset = instructionsTopView.bounds.size.width - pointOfInterest.x - coachMark.horizontalMargin
            } else {
                arrowOffset = pointOfInterest.x - coachMark.horizontalMargin
            }
            
        default:
            arrowOffset = 0
            break
        }
        
        return arrowOffset
    }

    /// Compute the segment index (for now the screen is separated
    /// in three horizontal areas and depending in which one the coach
    /// mark stand, it will be layed out in a different way.
    ///
    /// - Parameter layoutDirection: the layout direction (RTL or LTR)
    ///
    /// - Returns: the segment index (either 1, 2 or 3)
    fileprivate func computeSegmentIndexForLayoutDirection(_ layoutDirection: UIUserInterfaceLayoutDirection) -> Int {
        let pointOfInterest = coachMark.pointOfInterest!
        var segmentIndex = 3 * pointOfInterest.x / instructionsTopView.bounds.size.width

        if layoutDirection == .rightToLeft {
            segmentIndex = 3 - segmentIndex
        }

        return Int(ceil(segmentIndex))
    }
}
