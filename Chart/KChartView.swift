//
//  KChartView.swift
//  Chart
//
//  Created by KK on 2/23/15.
//  Copyright (c) 2015 KK. All rights reserved.
//

import Foundation
import UIKit

// X-axis pre padding to accomodate for Y-axis labels.
let X_AXIS_LABEL_PADDING = 50.0
let X_AXIS_PRE_PADDING = 10.0
let X_AXIS_POST_PADDING = 10.0
let Y_AXIS_TOP_PADDING  = 10.0

@objc protocol KChartViewDataSource  {
    func numberOfItemsInChart() -> Int
    func numberOfStacksPerItem() -> Int
    func itemAtIndex(idx: Int, forStack stack: Int) -> Double
    // Optional labels for the points on X-axis
    optional func labelXForItemAtIndex(idx: Int) -> String
    // Every point is not labeled on Y-axis. Instead, there are a set number of labels.
    optional func numberOfLabelsForYAxis() -> Int
    // Optional coloring for the different stacks
    optional func colorForStack(idx: Int) -> UIColor
}

enum KChartType {
    case Bar, Line
}

class KChartView: UIView {
    
    var datasource: KChartViewDataSource? = nil
    var chartViewItems: [(Double, [Double])] = []
    var chartType: KChartType = .Bar
    
    let barColor = UIColor(white: 0.5, alpha: 1.0) // Grey bar by default
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func drawRect(rect: CGRect) {
        //super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        drawAxes(context)
        
        // Draw a straight line to represent the X-axis
        if let datasource = datasource {
            let numItems  = datasource.numberOfItemsInChart()
            let numStacks = datasource.numberOfStacksPerItem()
            let totItems = numItems * 2 + numItems - 1
            
            let width = Double(self.bounds.size.width) - X_AXIS_LABEL_PADDING - X_AXIS_PRE_PADDING - X_AXIS_POST_PADDING
            
            // Number of gaps = numItems - 1 .. Let gap width = bar width / 2 ..
            // So total number of "items" = numItems * 2 + numItems - 1
            // width of each "item" = width/(numItems * 2 ) + (numItems - 1)
            let indWidth = width / Double(totItems)
            
            for i in 0...numItems - 1 {
                var stackArray : [Double] = []
                var itemTotal = 0.0
                for j in 0...numStacks - 1 {
                    let item = datasource.itemAtIndex(i, forStack: j)
                    itemTotal += item
                    stackArray.append(item)
                }
                let thisItem = (itemTotal, stackArray)
                chartViewItems.append(thisItem)
            }
            
            let maxValue = chartViewItems.reduce(0.0) { max($0.0, $1.0) }
            let maxHeight = Double(self.bounds.size.height * 0.8) - Y_AXIS_TOP_PADDING
            drawYAxisLabels(maxValue, maxHeight: maxHeight)
            
            switch chartType {
            case .Bar:
                // Draw the different stacks ( starting from stack 0 and moving up )
                for i in 0...numItems - 1 {
                    let (total, chartItems) = chartViewItems[i]
                    // For each stack item, draw a rectangle.
                    let x = Double(i) * indWidth * 3.0 + X_AXIS_PRE_PADDING + X_AXIS_LABEL_PADDING
                    
                    var accumulatedHeight = 0.0
                    // The 0th stack represents the lowest stack, so start drawing from the highest stack
                    for j in reverse(0...chartItems.count - 1) {
                        let thisItem = chartItems[j]
                        
                        let totalHeight = (total / maxValue) * maxHeight
                        let thisHeight = (thisItem / maxValue) * maxHeight
                        
                        // Draw bar
                        let color = datasource.colorForStack?(j) ?? barColor
                        CGContextSetFillColorWithColor(context, color.CGColor)
                        let y = CGFloat(maxHeight - totalHeight + Y_AXIS_TOP_PADDING + accumulatedHeight)
                        let rect = CGRectMake(CGFloat(x), y, CGFloat(indWidth * 2.0), CGFloat(thisHeight))
                        CGContextFillRect(context, rect)
                        
                        accumulatedHeight += thisHeight
                    }
                    
                    // Add label for x-axis
                    let label = UILabel()
                    label.setTranslatesAutoresizingMaskIntoConstraints(false)
                    
                    label.text =  datasource.labelXForItemAtIndex?(i) ?? ""
                    self.addSubview(label)
                    self.setViewConstraints(label, offset: x, height: maxHeight + Y_AXIS_TOP_PADDING)
                    
                }
            case .Line:
                var stackLines: [Int: [CGPoint]] = [:] // each element represents a stack and the line that goes through it.
                for i in 0...numItems - 1 {
                    let (total, chartItems) = chartViewItems[i]
                    // For each stack item, draw a rectangle.
                    let x = Double(i) * indWidth * 3.0 + X_AXIS_PRE_PADDING + X_AXIS_LABEL_PADDING
                    
                    var accumulatedHeight = 0.0
                    // The 0th stack represents the lowest stack, so start drawing from the highest stack
                    for j in reverse(0...chartItems.count - 1) {
                        let thisItem = chartItems[j]
                        
                        let totalHeight = (total / maxValue) * maxHeight
                        let thisHeight = (thisItem / maxValue) * maxHeight
                        
                        // Compute x,y
                        let y = CGFloat(maxHeight - totalHeight + Y_AXIS_TOP_PADDING + accumulatedHeight)
                        if var lineArray = stackLines[j] {
                            lineArray.append(CGPoint(x: CGFloat(x), y: y))
                            stackLines[j] = lineArray
                        }
                        else {
                            var lineArray: [CGPoint] = [CGPoint(x: CGFloat(x), y: y)]
                            stackLines[j] = lineArray
                        }
                        
                        accumulatedHeight += thisHeight
                    }
                    
                    // Add label for x-axis
                    let label = UILabel()
                    label.setTranslatesAutoresizingMaskIntoConstraints(false)
                    
                    label.text =  datasource.labelXForItemAtIndex?(i) ?? ""
                    self.addSubview(label)
                    self.setViewConstraints(label, offset: x, height: maxHeight + Y_AXIS_TOP_PADDING)
                    
                }
                // Now render the lines.
                for i in 0...numStacks - 1 {
                    let points = stackLines[i]!
                    let lineColor =  datasource.colorForStack?(i) ?? barColor
                    CGContextSetLineWidth(context, 2.0)
                    CGContextSetStrokeColorWithColor(context, lineColor.CGColor)
                    
                    for j in 0...points.count - 1 {
                        if j == 0 {
                            CGContextMoveToPoint(context, points[j].x, points[j].y)
                        }
                        else {
                            CGContextAddLineToPoint(context, points[j].x, points[j].y)
                        }
                    }
                    CGContextStrokePath(context)
                }
            }
            
        }
    }
    
    private func setViewConstraints(view: UIView, offset: Double, height: Double) {
        var views: NSMutableDictionary = NSMutableDictionary()
        views.setValue(view, forKey: "label")
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-\(offset)-[label]", options: nil, metrics: nil, views: views))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-\(height + 5.0)-[label]", options: nil, metrics: nil, views: views))
    }
    
    private func drawAxes(context: CGContext) {
        
        let lineColor = UIColor.lightGrayColor().CGColor
        
        CGContextSetLineWidth(context, 2.0)
        CGContextSetStrokeColorWithColor(context, lineColor)
        CGContextBeginPath(context)
        
        CGContextMoveToPoint(context, 0, self.bounds.size.height * 0.8);
        CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.size.height * 0.8)
        CGContextStrokePath(context)

        CGContextMoveToPoint(context, CGFloat(X_AXIS_LABEL_PADDING), 0);
        CGContextAddLineToPoint(context, CGFloat(X_AXIS_LABEL_PADDING), self.bounds.size.height * 0.8)
        CGContextStrokePath(context)
    }
    
    private func drawYAxisLabels(maxValue: Double, maxHeight: Double) {
        if let datasource = datasource {
            // Draw y-axis labels -- constant 3 labels.
            let numYLabels = datasource.numberOfLabelsForYAxis?()
            if ( numYLabels != nil ) {
                for i in 0...numYLabels! - 1 {
                    let label = UILabel()
                    label.setTranslatesAutoresizingMaskIntoConstraints(false)
                    
                    let thisVal = Double(maxValue) - ( Double(maxValue) * Double(i)/Double(numYLabels!))
                    let thisHeight =  ( Double(i) / Double(numYLabels!) ) * Double(maxHeight)
                    
                    label.text = "\(thisVal)"
                    self.addSubview(label)
                    self.setViewConstraints(label, offset: 0, height: thisHeight)
                }
            }
        }
    }
    
}
