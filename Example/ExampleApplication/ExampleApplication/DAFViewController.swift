//
//  DAFViewController.swift
//  ExampleApplication
//
//  Created by David Flores on 6/13/16.
//  Copyright © 2016 David Flores. All rights reserved.
//

import UIKit
import ExampleStaticLibrary

class DAFViewController: UIViewController
{
    private var dependency = Dependency(x:40)
    
    @IBOutlet private var label: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        label.text = "\(dependency.plus(2))"
    }
}
