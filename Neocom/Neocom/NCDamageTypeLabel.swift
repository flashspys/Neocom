//
//  NCDamageTypeLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

enum NCDamageType: Int {
	case em
	case thermal
	case kinetic
	case explosive
}

@IBDesignable
class NCDamageTypeLabel: NCLabel {
	@IBInspectable var progress: Float = 0 {
		didSet {
			setNeedsDisplay()
		}
	}
	@IBInspectable var damageType: Int = NCDamageType.em.rawValue
	
	override func awakeFromNib() {
		super.awakeFromNib()
		switch NCDamageType(rawValue: self.damageType) ?? .em {
		case .em:
			self.tintColor = UIColor(number: 0x3482C5FF)
		case .thermal:
			self.tintColor = UIColor(number: 0xC0262AFF)
		case .kinetic:
			self.tintColor = UIColor(number: 0xA3A3A3FF)
		case .explosive:
			self.tintColor = UIColor(number: 0xC2882AFF)
		}
		var rgba: [CGFloat] = [0, 0, 0, 0]
		self.tintColor.getRed(&rgba[0], green: &rgba[1], blue: &rgba[2], alpha: &rgba[3])
		self.backgroundColor = UIColor(red: rgba[0] * 0.4, green: rgba[1] * 0.4, blue: rgba[2] * 0.4, alpha: rgba[3])
	}
	
	
	
#if TARGET_INTERFACE_BUILDER
	override func prepareForInterfaceBuilder() {
		self.awakeFromNib()
	}
#endif
	
	override func draw(_ rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()
		context?.saveGState()
		var left = rect
		left.size.width *= CGFloat(progress)
		tintColor.setFill()
		context?.fill(left)
		context?.restoreGState()
		super.draw(rect)
	}
}