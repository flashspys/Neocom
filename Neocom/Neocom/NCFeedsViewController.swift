//
//  NCFeedsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFeedsViewController: UITableViewController, TreeControllerDelegate {
	
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])
		treeController.delegate = self
		
		let folders = try! JSONSerialization.jsonObject(with: try! Data(contentsOf: Bundle.main.url(forResource: "rssFeeds", withExtension: "json")!), options: []) as! [String: Any]

		let sections = (folders["folders"] as? [[String: Any]])?.map { i -> DefaultTreeSection in
			let rows = (i["feeds"] as? [[String: Any]])?.flatMap { j -> DefaultTreeRow? in
				guard let s = j["url"] as? String, let url = URL(string: s) else {return nil}
				guard let title = j["title"] as? String else {return nil}
				return DefaultTreeRow(image: #imageLiteral(resourceName: "rss"),
				                      title: title,
				                      subtitle: j["link"] as? String,
				                      accessoryType: .disclosureIndicator,
				                      route: Router.RSS.Channel(url: url, title: title))
			}
			return DefaultTreeSection(title: (i["title"] as? String)?.uppercased(), children: rows)
		}
		
		treeController.content = RootNode(sections ?? [])
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
}