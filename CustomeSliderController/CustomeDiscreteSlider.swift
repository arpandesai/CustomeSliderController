//
//  CustomeDiscreteSlider.swift
//  CustomeSliderController
//
//  Created by Umangi on 08/12/17.
//  Copyright © 2017 mobileFirst. All rights reserved.
//

import UIKit

public enum ComponentStyle:Int {
    case iOS = 0
    case rectangular
    case rounded
    case image
}

//  Interface builder hides the IBInspectable for UIControl
#if TARGET_INTERFACE_BUILDER
public class CUSTOMESLIDER_INTERFACE_BUILDER:UIView {
    }
#else // !TARGET_INTERFACE_BUILDER
    public class CUSTOMESLIDER_INTERFACE_BUILDER:UIControl {
    }
#endif // TARGET_INTERFACE_BUILDER

@IBDesignable
public class CustomeDiscreteSlider:CUSTOMESLIDER_INTERFACE_BUILDER {

    /**
       It return tickSize
     
     - Parameter width: Width of tick
     - Parameter height: Height of tick
     */
    @IBInspectable public var tickSize:CGSize = CGSize(width:1, height:6) {
        didSet {
            tickSize.width = max(0, tickSize.width)
            tickSize.height = max(0, tickSize.height)
            layoutTrack()
        }
    }
    
    /**
        It return total count of ticks
     */
    @IBInspectable public var tickCount:Int = 11 {
        didSet {
            tickCount = max(2, tickCount)
            layoutTrack()
        }
    }

    /**
        Increase thickness of track
     */
    @IBInspectable public var trackThickness:CGFloat = 2 {
        didSet {
            trackThickness = max(0, trackThickness)
            layoutTrack()
        }
    }

    /**
        Return min track tint color
     */
   @IBInspectable public var minimumTrackTintColor:UIColor? = nil {
       didSet {
            layoutTrack()
       }
   }
    /**
        Return max track tint color
     */
   @IBInspectable public var maximumTrackTintColor:UIColor = UIColor(white: 0.71, alpha: 1) {
        didSet {
           layoutTrack()
       }
    }
    
    /**
        Return thumb tint color
     */
    @IBInspectable public var thumbTintColor:UIColor? = nil {
        didSet {
            layoutTrack()
        }
    }
    
    /**
        Return thumb text color
     */
    @IBInspectable public var thumbTextTintColor:UIColor? = nil {
        didSet {
            layoutTrack()
        }
    }
    
    /**
        Return thumb shadow radious
     */
    @IBInspectable public var thumbShadowRadius:CGFloat = 0 {
        didSet {
            layoutTrack()
        }
    }
    
    /**
        Return thumb shadow size
     */
    @IBInspectable public var thumbShadowOffset:CGSize = CGSize.zero {
        didSet {
            layoutTrack()
        }
    }

    /**
        Return increment value
     */
    @IBInspectable public var incrementValue:Int = 1 {
        didSet {
            if(0 == incrementValue) {
                incrementValue = 1;  // nonZeroIncrement
            }
            layoutTrack()
        }
    }
    
    /**
        Return minimum thumbValue
     */
    @IBInspectable public var minimumValue:CGFloat {
        get {
            return CGFloat(intMinimumValue)
        }
        set {
            intMinimumValue = Int(newValue)
            layoutTrack()
        }
    }
    
    /**
        Return thumbValue
     */
    @IBInspectable public var value:CGFloat {
        get {
            return CGFloat(intValue)
        }
        set {
            intValue = (Int(newValue))
            layoutTrack()
            sliderthumbLabel(valueChange: intValue)
        }
    }

    // MARK: @IBInspectable adapters

    public var tickComponentStyle:ComponentStyle {
        get {
            return ComponentStyle(rawValue: 1)!
        }
    }

    public var trackComponentStyle:ComponentStyle {
        get {
            return ComponentStyle(rawValue: 1)!
        }
    }

    public var thumbComponentStyle:ComponentStyle {
        get {
            return ComponentStyle(rawValue: 3)!
        }
    }

    // MARK: Properties

    public override var tintColor: UIColor! {
        didSet {
            layoutTrack()
        }
    }

    public override var bounds: CGRect {
        didSet {
            layoutTrack()
        }
    }
    
    /**
        Set updated thumb value using Protocol
     */
    public var ticksListener:CustomeSliderTicksProtocol? {
        didSet {
            ticksListener?.tgpValueChanged(value: UInt(intValue))
        }
    }
    var intValue:Int = 0
    var intMinimumValue = 0
    
    var ticksAbscisses:[CGPoint] = []
    var thumbAbscisse:CGFloat = 0
    var thumbLayer = CATextLayer()
    var leftTrackLayer = CALayer()
    var rightTrackLayer = CALayer()
    var trackLayer = CALayer()
    var ticksLayer = CALayer()
    var trackRectangle = CGRect.zero
    var touchedInside = false
    var thumbValue = UILabel()
    var thumbSize:CGSize = CGSize(width:10, height:10)

    let iOSThumbShadowRadius:CGFloat = 4
    let iOSThumbShadowOffset = CGSize(width:0, height:3)

    /**
        UIControl
    */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initProperties()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initProperties()
    }

    public override func draw(_ rect: CGRect) {
        drawTrack()
        drawTicks()
        drawThumb()
    }

   
    /**
        Automatic UIControlEventValueChanged notification
    */

    func sendActionsForControlEvents() {
        
        if let ticksListener = ticksListener {
            ticksListener.tgpValueChanged(value: (UInt(value)))
            sliderthumbLabel(valueChange: intValue)
        }
    }

    /**
        Initialise properties method
    */

    func initProperties() {
        // Track is a clear clipping layer, and left + right sublayers, which brings in free animation
        trackLayer.masksToBounds = true
        trackLayer.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(trackLayer)
        if let backgroundColor = tintColor {
            leftTrackLayer.backgroundColor = backgroundColor.cgColor
        }
        trackLayer.addSublayer(leftTrackLayer)
        rightTrackLayer.backgroundColor = maximumTrackTintColor.cgColor
        trackLayer.addSublayer(rightTrackLayer)

        // Ticks in between track and thumb
        layer.addSublayer(ticksLayer)

        // The thumb is its own CALayer, which brings in free animation
        layer.addSublayer(thumbLayer)

        isMultipleTouchEnabled = false
        layoutTrack()
    }

    /**
        This method used for draw ticks
    */
    
    func drawTicks() {
        ticksLayer.frame = bounds
        if let backgroundColor = tintColor {
            ticksLayer.backgroundColor = backgroundColor.cgColor
        }
        let path = UIBezierPath()

        switch tickComponentStyle {

        case .rectangular:
            fallthrough

        case .image:
            for originPoint in ticksAbscisses {
                let rectangle = CGRect(x: originPoint.x-(tickSize.width/2),
                                       y: originPoint.y-(tickSize.height/2),
                                       width: tickSize.width,
                                       height: tickSize.height)
                switch tickComponentStyle {

                case .rectangular:
                    path.append(UIBezierPath(rect: rectangle))

                default:
                    assert(false)
                    break
                }
            }

        default:
            // Nothing to draw
            break
        }

        let maskLayer = CAShapeLayer()
        maskLayer.frame = trackLayer.bounds
        maskLayer.path = path.cgPath
        ticksLayer.mask = maskLayer
    }
    
    /**
        This method used for draw track
     */
    
    func drawTrack() {
        switch(trackComponentStyle) {
        case .rectangular:
            trackLayer.frame = trackRectangle
            trackLayer.cornerRadius = 0.0

        case .rounded:
            fallthrough

        default:
            trackLayer.frame = trackRectangle
            trackLayer.cornerRadius = trackRectangle.height/2
            break
        }

        leftTrackLayer.frame = {
            var frame = trackLayer.bounds
            frame.size.width = thumbAbscisse - trackRectangle.minX
            return frame
        }()

        if let backgroundColor = minimumTrackTintColor ?? tintColor {
           leftTrackLayer.backgroundColor = backgroundColor.cgColor
      }

        rightTrackLayer.frame = {
            var frame = trackLayer.bounds
            frame.size.width = trackRectangle.width - leftTrackLayer.frame.width
            frame.origin.x = leftTrackLayer.frame.maxX
            return frame
        }()
        rightTrackLayer.backgroundColor = maximumTrackTintColor.cgColor
    }
    
    /**
        This method used for draw thumb
     */
    func drawThumb() {
        // Feature: hide the thumb when below range
        if( value >= minimumValue) {

            let thumbSizeForStyle = thumbSizeIncludingShadow()
            let thumbWidth = thumbSizeForStyle.width
            let thumbHeight = thumbSizeForStyle.height
            let rectangle = CGRect(x:thumbAbscisse - (thumbWidth / 2),
                                   y: (frame.height - thumbHeight)/2,
                                   width: thumbWidth,
                                   height: thumbHeight)

            let shadowRadius = (thumbComponentStyle == .iOS) ? iOSThumbShadowRadius : thumbShadowRadius
            let shadowOffset = (thumbComponentStyle == .iOS) ? iOSThumbShadowOffset : thumbShadowOffset
            
             // Ignore offset if there is no shadow
            thumbLayer.frame = ((shadowRadius != 0.0)
                ? rectangle.insetBy(dx: shadowRadius + shadowOffset.width,
                                    dy: shadowRadius + shadowOffset.height)
                : rectangle.insetBy(dx: shadowRadius,
                                    dy: shadowRadius))

            switch thumbComponentStyle {
                
            // A rounded thumb is circular
            case .rounded:
                thumbSize.width = max(1, thumbSize.width)
                thumbSize.height = max(1, thumbSize.height)
                thumbLayer.backgroundColor = (thumbTintColor ?? UIColor.lightGray).cgColor
                thumbLayer.foregroundColor = (thumbTextTintColor ?? UIColor.black).cgColor
                thumbLayer.borderColor = UIColor.clear.cgColor
                thumbLayer.borderWidth = 0.0
                thumbLayer.cornerRadius = thumbLayer.frame.width/2
                thumbLayer.allowsEdgeAntialiasing = true

            default:
                thumbLayer.backgroundColor = (thumbTintColor ?? UIColor.white).cgColor
                thumbLayer.foregroundColor = (thumbTextTintColor ?? UIColor.black).cgColor

                // Only default iOS thumb has a border
                if nil == thumbTintColor {
                    let borderColor = UIColor(white:0.5, alpha: 1)
                    thumbLayer.borderColor = borderColor.cgColor
                    thumbLayer.borderWidth = 0.25
                } else {
                    thumbLayer.borderWidth = 0
                }
                thumbLayer.cornerRadius = thumbLayer.frame.width/2
                thumbLayer.allowsEdgeAntialiasing = true
                break
            }

            // Shadow
            if(shadowRadius != 0.0) {
                #if TARGET_INTERFACE_BUILDER
                    thumbLayer.shadowOffset = CGSize(width: shadowOffset.width,
                                                     height: -shadowOffset.height)
                #else // !TARGET_INTERFACE_BUILDER
                    thumbLayer.shadowOffset = shadowOffset
                #endif // TARGET_INTERFACE_BUILDER

                thumbLayer.shadowRadius = shadowRadius
                thumbLayer.shadowColor = UIColor.black.cgColor
                thumbLayer.shadowOpacity = 0.15
            } else {
                thumbLayer.shadowRadius = 0.0
                thumbLayer.shadowOffset = CGSize.zero
                thumbLayer.shadowColor = UIColor.clear.cgColor
                thumbLayer.shadowOpacity = 0.0
            }
        }
    }
    
    /**
        This method create layout of track
     */
    func layoutTrack() {
        assert(tickCount > 1, "2 ticks minimum \(tickCount)")
        let segments = max(1, tickCount - 1)
        let thumbWidth = thumbSizeIncludingShadow().width

        // Calculate the track ticks positions
        let trackHeight = (.iOS == trackComponentStyle) ? 2 : trackThickness
        let trackSize = CGSize(width: frame.width - thumbWidth,
                               height: trackHeight)

        trackRectangle = CGRect(x: (frame.width - trackSize.width)/2,
                                y: (frame.height - trackSize.height)/2,
                                width: trackSize.width,
                                height: trackSize.height)
        let trackY = frame.height / 2
        ticksAbscisses = []
        for iterate in 0 ... segments {
            let ratio = Double(iterate) / Double(segments)
            let originX = trackRectangle.origin.x + (CGFloat)(trackSize.width * CGFloat(ratio))
            ticksAbscisses.append(CGPoint(x: originX, y: trackY))
        }
        layoutThumb()

        ticksListener?.tgpValueChanged(value: UInt(intValue))
        setNeedsDisplay()
    }

    /**
        This method create layout of thumb
     */
    func layoutThumb() {
        assert(tickCount > 1, "2 ticks minimum \(tickCount)")
        let segments = max(1, tickCount - 1)

        // Calculate the thumb position
        let nonZeroIncrement = ((0 == incrementValue) ? 1 : incrementValue)
        var thumbRatio = Double(value - minimumValue) / Double(segments * nonZeroIncrement)
        thumbRatio = max(0.0, min(thumbRatio, 1.0)) // Normalized
        thumbAbscisse = trackRectangle.origin.x + (CGFloat)(trackRectangle.width * CGFloat(thumbRatio))
        setNeedsDisplay()
    }

    func thumbSizeIncludingShadow() -> CGSize {
        switch thumbComponentStyle {

        case .rectangular:
            fallthrough

        case .rounded:
            return ((thumbShadowRadius != 0.0)
                ? CGSize(width:thumbSize.width
                    + (thumbShadowRadius * 2)
                    + (thumbShadowOffset.width * 2),
                         height: thumbSize.height
                            + (thumbShadowRadius * 2)
                            + (thumbShadowOffset.height * 2))
                : thumbSize)

        default:
            return CGSize(width: 33, height: 33)
        }
    }
 
    // MARK: UIResponder Methods
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchedInside = true

        touchDown(touches, animationDuration: 0.1)
        sendActionForControlEvent(controlEvent: .valueChanged, with: event)
        sendActionForControlEvent(controlEvent: .touchDown, with:event)

        if let touch = touches.first {
            if touch.tapCount > 1 {
                sendActionForControlEvent(controlEvent: .touchDownRepeat, with: event)
            }
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchDown(touches, animationDuration:0)

        let inside = touchesAreInside(touches)
        sendActionForControlEvent(controlEvent: .valueChanged, with: event)

        if inside != touchedInside { // Crossing boundary
            sendActionForControlEvent(controlEvent: (inside) ? .touchDragEnter : .touchDragExit,
                                      with: event)
            touchedInside = inside
        }
        // Drag
        sendActionForControlEvent(controlEvent: (inside) ? .touchDragInside : .touchDragOutside,
                                  with: event)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchUp(touches)

        sendActionForControlEvent(controlEvent: .valueChanged, with: event)
        sendActionForControlEvent(controlEvent: (touchesAreInside(touches)) ? .touchUpInside : .touchUpOutside,
                                  with: event)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchUp(touches)

        sendActionForControlEvent(controlEvent: .valueChanged, with:event)
        sendActionForControlEvent(controlEvent: .touchCancel, with:event)
    }

    func touchDown(_ touches: Set<UITouch>, animationDuration duration:TimeInterval) {
        if let touch = touches.first {
            let location = touch.location(in: touch.view)
            moveThumbTo(abscisse: location.x, animationDuration: duration)
        }
    }

    func touchUp(_ touches: Set<UITouch>) {
        if let touch = touches.first {
            let location = touch.location(in: touch.view)
            let tick = pickTickFromSliderPosition(abscisse: location.x)
            moveThumbToTick(tick: tick)
        }
    }

    func touchesAreInside(_ touches: Set<UITouch>) -> Bool {
        var inside = false
        if let touch = touches.first {
            let location = touch.location(in: touch.view)
            if let bounds = touch.view?.bounds {
                inside = bounds.contains(location)
            }
        }
        return inside
    }

    // MARK: Notifications Methods

    func moveThumbToTick(tick: UInt) {
        let nonZeroIncrement = ((0 == incrementValue) ? 1 : incrementValue)
        let intValue = Int(minimumValue) + (Int(tick) * nonZeroIncrement)
        if intValue != self.intValue {
            self.intValue = intValue
            sendActionsForControlEvents()
        }
        print(self.intValue)
        layoutThumb()
        setNeedsDisplay()
    }

    func moveThumbTo(abscisse:CGFloat, animationDuration duration:TimeInterval) {
        let leftMost = trackRectangle.minX
        let rightMost = trackRectangle.maxX

        thumbAbscisse = max(leftMost, min(abscisse, rightMost))
        CATransaction.setAnimationDuration(duration)

        let tick = pickTickFromSliderPosition(abscisse: thumbAbscisse)
        let nonZeroIncrement = ((0 == incrementValue) ? 1 : incrementValue)
        let intValue = Int(minimumValue) + (Int(tick) * nonZeroIncrement)
        if intValue != self.intValue {
            self.intValue = intValue
            sendActionsForControlEvents()
        }
        setNeedsDisplay()
    }
    
    func pickTickFromSliderPosition(abscisse: CGFloat) -> UInt {
        let leftMost = trackRectangle.minX
        let rightMost = trackRectangle.maxX
        let clampedAbscisse = max(leftMost, min(abscisse, rightMost))
        let ratio = Double(clampedAbscisse - leftMost) / Double(rightMost - leftMost)
        let segments = max(1, tickCount - 1)
        return UInt(round( Double(segments) * ratio))
    }

    func sendActionForControlEvent(controlEvent:UIControlEvents, with event:UIEvent?) {
        for target in allTargets {
            if let caActions = actions(forTarget: target, forControlEvent: controlEvent) {
                for actionName in caActions {
                    sendAction(NSSelectorFromString(actionName), to: target, for: event)
                }
            }
        }
    }
    
    //MARK:  Update ThumbValue Method
    
    /**
        This method change the value of thumbLabel
    */
    func sliderthumbLabel(valueChange:Int){
        thumbLayer.fontSize = 20
        thumbLayer.foregroundColor = UIColor.white.cgColor
        thumbLayer.alignmentMode = kCAAlignmentCenter
    
        let xyz:Int = valueChange
        let strinvalue:String? = String.init(format: "%d", xyz)
        thumbValue.text = strinvalue!
        print(thumbValue.text!)
        thumbLayer.string = strinvalue!
    }
    
    #if TARGET_INTERFACE_BUILDER
    // MARK: TARGET_INTERFACE_BUILDER stub
    //       Interface builder hides the IBInspectable for UIControl

    let allTargets: Set<AnyHashable> = Set()
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControlEvents) {}
    func actions(forTarget target: Any?, forControlEvent controlEvent: UIControlEvents) -> [String]? { return nil }
    func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {}
    #endif // TARGET_INTERFACE_BUILDER    
}
