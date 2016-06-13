//
//  Dependency.swift
//  ExampleStaticLibrary
//
//  Created by David Flores on 6/13/16.
//  Copyright © 2016 David Flores. All rights reserved.
//

import Foundation

public class Dependency
{
    private var x : Int
    
    public init(x : Int)
    {
        self.x = x
    }
    
    public func plus(y : Int) -> Int
    {
        return self.x + y
    }
}
