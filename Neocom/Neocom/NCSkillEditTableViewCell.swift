//
//  NCSkillEditTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCSkillEditTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var levelSegmentedControl: UISegmentedControl!
	
}


extension Prototype {
	struct NCSkillEditTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCSkillEditTableViewCell")
	}
}

class NCSkillEditRow: FetchedResultsObjectNode<NSDictionary> {
	var level: Int = 0
	let typeID: Int
	required init(object: NSDictionary) {
		typeID = (object["typeID"] as! NSNumber).intValue
		super.init(object: object)
		cellIdentifier = Prototype.NCSkillEditTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCSkillEditTableViewCell else {return}
		cell.titleLabel.text = object["typeName"] as? String
		cell.levelSegmentedControl.selectedSegmentIndex = level
	}
}