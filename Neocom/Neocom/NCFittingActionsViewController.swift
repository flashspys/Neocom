//
//  NCFittingActionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit


/*class NCFittingTypeRow: TreeRow {
	let type: NCDBInvType
	
	init(type: NCDBInvType, segue: String? = nil, accessoryButtonSegue: String? = nil) {
		self.type = type
		super.init(cellIdentifier: "NCDefaultTableViewCell", segue: segue, accessoryButtonSegue: accessoryButtonSegue)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.object = type
		cell.titleLabel?.text = type.typeName
		cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.accessoryType = .detailButton
	}
	
	override var hashValue: Int {
		return type.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingTypeRow)?.hashValue == hashValue
	}
	
	override func changed(from: TreeNode) -> Bool {
		return false
	}
}*/

class NCFittingDamagePatternRow: TreeRow {
	let damagePattern: NCFittingDamage
	
	init(prototype: Prototype = Prototype.NCDamageTypeTableViewCell.compact, damagePattern: NCFittingDamage, route: Route? = nil) {
		self.damagePattern = damagePattern
		super.init(prototype: prototype, route: route)
		
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDamageTypeTableViewCell else {return}
		
		func fill(label: NCDamageTypeLabel, value: Double) {
			label.progress = Float(value)
			label.text = "\(Int(round(value * 100)))%"
		}
		
		fill(label: cell.emLabel, value: damagePattern.em)
		fill(label: cell.kineticLabel, value: damagePattern.kinetic)
		fill(label: cell.thermalLabel, value: damagePattern.thermal)
		fill(label: cell.explosiveLabel, value: damagePattern.explosive)
	}
	
	override var hashValue: Int {
		return damagePattern.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingDamagePatternRow)?.hashValue == hashValue
	}
	
}

class NCFittingAreaEffectRow: NCTypeInfoRow {
	
}

class NCLoadoutNameRow: NCTextFieldRow {
	
	override var hashValue: Int {
		return 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCLoadoutNameRow)?.hashValue == hashValue
	}
}

class NCFittingActionsViewController: UITableViewController, TreeControllerDelegate, UITextFieldDelegate {
	@IBOutlet var treeController: TreeController!
	var fleet: NCFittingFleet?
	
	private var observer: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//navigationController?.preferredContentSize = CGSize(width: view.bounds.size.width, height: 320)
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDamageTypeTableViewCell.compact,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCFittingCharacterTableViewCell.default
		                    ])
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		reload()
		tableView.layoutIfNeeded()
		var size = tableView.contentSize
		size.height += tableView.contentInset.top
		size.height += tableView.contentInset.bottom
		navigationController?.preferredContentSize = size
		
		if let pilot = fleet?.active, observer == nil {
			observer = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: pilot.engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
		
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let item = node as? TreeNodeRoutable else {return}
		guard let route = item.route else {return}
		route.perform(source: self, view: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let route = node.accessoryButtonRoute else {return}
		route.perform(source: self, view: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard node is NCFittingAreaEffectRow else {return nil}
		return [UITableViewRowAction(style: .default, title: NSLocalizedString("Delete", comment: ""), handler: {[weak self] _ in
			guard let engine = self?.fleet?.active?.engine else {return}
			engine.perform {
				engine.area = nil
			}
		})]
	}
	
	//MARK: - UITextFieldDelegate
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		guard let cell = textField.ancestor(of: UITableViewCell.self) else {return}
		guard let indexPath = tableView.indexPath(for: cell) else {return}
		tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
		
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.endEditing(true)
		return true
	}

	@IBAction func onEndEditing(_ sender: UITextField) {
		guard let pilot = fleet?.active else {return}
		let text = sender.text
		pilot.engine?.perform {
			pilot.ship?.name = text ?? ""
		}
	}
	
	//MARK: - Private
	
	private func reload() {
		guard let pilot = fleet?.active else {return}
		guard let engine = pilot.engine else {return}
		
		var sections = [TreeNode]()

		let invTypes = NCDatabase.sharedDatabase?.invTypes

		engine.performBlockAndWait {
			let title = pilot.ship?.name
			sections.append(NCLoadoutNameRow(text: title?.isEmpty == false ? title : nil, placeholder: NSLocalizedString("Ship Name", comment: "")))
			if let ship = pilot.ship, let type = invTypes?[ship.typeID] {
				let row = NCTypeInfoRow(type: type, accessoryType: .detailButton, route: Router.Database.TypeInfo(type), accessoryButtonRoute: Router.Database.TypeInfo(type))
				sections.append(DefaultTreeSection(nodeIdentifier: "Ship", title: NSLocalizedString("Ship", comment: "").uppercased(), children: [row]))
			}
			
			let characterRow: TreeNode
			let characterRoute = Router.Fitting.Characters(pilot: pilot) { (controller, url) in
				controller.dismiss(animated: true) {
					pilot.setSkills(from: url, completionHandler: nil)
				}
			}
			
			if let account = pilot.account {
				characterRow = NCAccountCharacterRow(account: account, route: characterRoute)
			}
			else if let character = pilot.fitCharacter {
				characterRow = NCCustomCharacterRow(character: character, route: characterRoute)
			}
			else {
				characterRow = NCPredefinedCharacterRow(level: pilot.level ?? 0, route: characterRoute)
			}
			
			sections.append(DefaultTreeSection(nodeIdentifier: "Character", title: NSLocalizedString("Character", comment: "").uppercased(), children: [characterRow]))

			let areaEffectsRoute = Router.Fitting.AreaEffects { [weak self] (controller, type) in
				let typeID = type != nil ? Int(type!.typeID) : nil
				controller.dismiss(animated: true) {
					self?.fleet?.active?.engine?.perform {
						self?.fleet?.active?.engine?.area = typeID != nil ? NCFittingArea(typeID: typeID!) : nil
					}
				}
			}
			
			if let area = engine.area, let type = invTypes?[area.typeID] {
				let row = NCFittingAreaEffectRow(type: type, accessoryType: .detailButton, route: areaEffectsRoute, accessoryButtonRoute: Router.Database.TypeInfo(type))
				sections.append(DefaultTreeSection(nodeIdentifier: "Area", title: NSLocalizedString("Area Effects", comment: "").uppercased(), children: [row]))
			}
			else {
				let row = NCActionRow(title: NSLocalizedString("Select Area Effects", comment: "").uppercased(),  route: areaEffectsRoute)
				sections.append(DefaultTreeSection(nodeIdentifier: "Area", title: NSLocalizedString("Area Effects", comment: "").uppercased(), children: [row]))
			}
			
			let damagePatternsRoute = Router.Fitting.DamagePatterns {[weak self] (controller, damagePattern) in
				controller.dismiss(animated: true) {
					self?.fleet?.active?.engine?.perform {
						for (pilot, _) in self?.fleet?.pilots ?? [] {
							pilot.ship?.damagePattern = damagePattern
						}
					}
				}
			}

			let damagePattern = pilot.ship?.damagePattern ?? .omni
			sections.append(DefaultTreeSection(nodeIdentifier: "DamagePattern", title: NSLocalizedString("Damage Pattern", comment: "").uppercased(), children: [NCFittingDamagePatternRow(damagePattern: damagePattern, route: damagePatternsRoute)]))
		}
		
		if treeController.rootNode == nil {
			let root = TreeNode()
			root.children = sections
			treeController.rootNode = root
		}
		else {
			treeController.rootNode?.children = sections
		}

	}
}