//
//  UIColor+Constructing.swift
//  VisionDemo
//
//  Created by Kamil Tustanowski on 25/08/2021.
//

import UIKit

extension UIColor {
    static var primary: UIColor {
        guard let primary = UIColor(named: "Primary") else { fatalError("No color named primary!") }
        return primary
    }
    
    static var background: UIColor {
        guard let primary = UIColor(named: "Background") else { fatalError("No color named primary!") }
        return primary
    }
}
