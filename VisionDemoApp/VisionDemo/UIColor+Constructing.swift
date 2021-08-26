//
//  UIColor+Constructing.swift
//  VisionDemo
//
//  Created by Semerkchet on 25/08/2021.
//

import UIKit

extension UIColor {
    static var primary: UIColor {
        guard let primary = UIColor(named: "Primary") else { fatalError("No color named primary!") }
        return primary
    }
}