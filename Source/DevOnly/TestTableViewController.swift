//
//  TestTableViewController.swift
//  MoleMapper
//
//  Created by Alejandro Cárdenas on 3/14/18.
//  Copyright © 2018 OHSU. All rights reserved.
//

import Foundation
import UIKit

class TestTableViewController: UITableViewController {
    
    // MARK: - Properties
    var viewModel: TestViewModel?
    
    // MARK: - Life View Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: viewModel?.cellIdentifier ?? "")
    }
    
    // MARK: - Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.itemsCount ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = viewModel?.cellIdentifier ?? ""
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.textLabel?.text = viewModel?.item(at: indexPath.row).rowTitle ?? "No title"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = viewModel?.item(at: indexPath.row) as? TestViewModel.TestItem
            else { return }
        
        item.completion?()
    }
}

