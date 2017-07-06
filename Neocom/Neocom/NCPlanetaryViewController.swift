//
//  NCPlanetaryViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCColonySection: TreeSection {
	let colony: ESI.PlanetaryInteraction.Colony
	let layout: NCCachedResult<ESI.PlanetaryInteraction.ColonyLayout>
	let engine: NCFittingEngine
	
	lazy var planet: NCDBMapDenormalize? = {
		return NCDatabase.sharedDatabase?.mapDenormalize[self.colony.planetID]
	}()
	
	init(colony: ESI.PlanetaryInteraction.Colony, layout: NCCachedResult<ESI.PlanetaryInteraction.ColonyLayout>, engine: NCFittingEngine) {
		self.colony = colony
		self.layout = layout
		self.engine = engine
		super.init(prototype: Prototype.NCHeaderTableViewCell.default)
	}
	
	override var hashValue: Int {
		return colony.hashValue ^ (layout.value?.hashValue ?? 0)
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCColonySection)?.hashValue == hashValue
	}
	
	override func loadChildren() {
		if let layout = layout.value {
			self.children = []
			let colony = self.colony
			let engine = self.engine
			let planetTypeID = Int(self.planet?.type?.typeID ?? 0)
			
			engine.perform {
				let planet = NCFittingPlanet(typeID: planetTypeID)
				engine.planet = planet
				
				var lastUpdate: Date? = nil
				
				for pin in layout.pins {
					let facility: NCFittingFacility? = planet.facility(identifier: pin.pinID) ?? {
						let facility = planet.addFacility(typeID: pin.typeID, identifier: pin.pinID)
						switch facility {
						case let ecu as NCFittingExtractorControlUnit:
							ecu.launchTime = pin.lastCycleStart?.timeIntervalSinceReferenceDate ?? 0
							ecu.installTime = pin.installTime?.timeIntervalSinceReferenceDate ?? 0
							ecu.expiryTime = pin.expiryTime?.timeIntervalSinceReferenceDate ?? 0
							ecu.cycleTime = TimeInterval((pin.extractorDetails?.cycleTime ?? 0) * 60)
							ecu.quantityPerCycle = pin.extractorDetails?.qtyPerCycle ?? 0
						case let factory as NCFittingIndustryFacility:
							factory.launchTime = pin.lastCycleStart?.timeIntervalSinceReferenceDate ?? 0
							factory.schematic = NCFittingSchematic(schematicID: pin.factoryDetails?.schematicID ?? 0)
						default:
							break
						}
						return facility
					}()
					
				}
			}
		}
		else if let error = layout.error {
			self.children = [DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, title: error.localizedDescription)]
		}
		else {
			self.children = [DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.placeholder, title: NSLocalizedString("Colony Layout not Available", comment: ""))]
		}
		super.loadChildren()
		
	}
}

class NCPlanetaryViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		registerRefreshable()
		
		treeController.delegate = self
		
		reload()
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var colonies: NCCachedResult<[ESI.PlanetaryInteraction.Colony]>?
	private var colonyLayouts: [Int: NCCachedResult<ESI.PlanetaryInteraction.ColonyLayout>]?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 2)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		progress.perform {
			dataManager.colonies { result in
				self.colonies = result
				
				progress.perform {
					switch result {
					case let .success(_, record):
						if let record = record {
							self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
								guard let strongSelf = self else {return}
								strongSelf.reloadLayouts(dataManager: dataManager) {
									strongSelf.reloadSections()
								}
							}
						}
						
						self.reloadLayouts(dataManager: dataManager) {
							self.reloadSections()
							completionHandler?()
						}
					case .failure:
						self.reloadSections()
						completionHandler?()
					}
				}
			}
		}
	}
	
	private func reloadLayouts(dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		guard let value = colonies?.value else {
			completionHandler?()
			return
		}
		let progress = Progress(totalUnitCount: Int64(value.count))
		
		let dispatchGroup = DispatchGroup()
		
		var colonyLayouts: [Int: NCCachedResult<ESI.PlanetaryInteraction.ColonyLayout>] = [:]
		
		for colony in value {
			progress.perform {
				dispatchGroup.enter()
				dataManager.colonyLayout(planetID: colony.planetID) { result in
					colonyLayouts[colony.planetID] = result
					dispatchGroup.leave()
				}
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			self.colonyLayouts = colonyLayouts
			completionHandler?()
		}
	}
	
	private func reloadSections() {
		if let value = colonies?.value {
			var sections = [TreeNode]()
			
			if self.treeController.content == nil {
				let root = TreeNode()
				root.children = sections
				self.treeController.content = root
			}
			else {
				self.treeController.content?.children = sections
			}
			self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil

			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: colonies?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}