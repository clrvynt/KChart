//
//  ViewController.swift
//  Chart
//
//  Created by KK on 2/23/15.
//  Copyright (c) 2015 KK. All rights reserved.
//

import UIKit

class ViewController: UIViewController, KChartViewDataSource {
    
    @IBOutlet var chartView: KChartView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        chartView.datasource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segmentChanged(sender: UISegmentedControl!) {
        if sender.selectedSegmentIndex == 0 {
            chartView.chartType = .Bar
        }
        else {
            chartView.chartType = .Line
        }
        chartView.setNeedsDisplay()
    }

    //MARK:- KChartViewDataSource
    func numberOfItemsInChart() -> Int {
        return 5
    }
    
    func numberOfStacksPerItem() -> Int {
        return 2
    }
    
    func numberOfLabelsForYAxis() -> Int {
        return 4
    }
    
    func colorForStack(idx: Int) -> UIColor {
        if idx == 0 {
            return UIColor.blueColor()
        }
        else {
            return UIColor.redColor()
        }
    }

    func itemAtIndex(idx: Int, forStack stack: Int) -> Double {
        return Double(arc4random_uniform(100))
    }
    
    func labelXForItemAtIndex(idx: Int) -> String {
        switch(idx) {
        case 0:
            return "lab 1"
        case 1:
            return "lab 2"
        case 2:
            return "bla"
        case 3:
            return "three"
        case 4:
            return "dog"
        default:
            return "umm"
            
        }
    }
    
}

