//
//  ViewController.swift
//  CustomeSliderController
//
//  Created by Umangi on 08/12/17.
//  Copyright © 2017 mobileFirst. All rights reserved.
//

import UIKit

class ViewController: UIViewController,CustomeSliderTicksProtocol {
   
    func tgpValueChanged(value: UInt) {
        controlEventsLabel.text = ("\(Double(value))")
    }
    
    @IBOutlet var controlEventsLabel: UILabel!
    @IBOutlet var slider: CustomeDiscreteSlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.ticksListener = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func valueChanged(_ sender: CustomeDiscreteSlider, event:UIEvent) {
        controlEventsLabel.text = ("\(Double(sender.value))")
    }
    
    
}

