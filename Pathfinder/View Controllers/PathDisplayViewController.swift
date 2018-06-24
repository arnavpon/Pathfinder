//  PathDisplayViewController.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/24/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

//  Displays the computed path - show each location in numbered list, w/ distance from point A -> point B & total (cumulative) distance underneath.

import UIKit
import GooglePlaces

class PathDisplayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    @IBOutlet weak var pathTable: UITableView!
    
    var pathList = [Path]()  // tableView data source
    var intelligentAgent: OptimalPathSearch?  // performs search
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Activity Indicator
        let width: CGFloat = 40.0
        self.view.addSubview(activityIndicator)  // add to main view
        activityIndicator.frame = CGRect(x: (self.view.frame.midX - width), y: (self.view.frame.midY - width), width: width, height: width)  // center indicator in view
        activityIndicator.hidesWhenStopped = true  // hide if not spinning
        activityIndicator.startAnimating()  // spin before computing
        
        // Perform search & update UI
        if let agent = self.intelligentAgent {
            self.pathList = agent.computeOptimalPath()  // update data source
            pathTable.delegate = self
            pathTable.dataSource = self  // setting source will refresh UI
        }
        activityIndicator.stopAnimating()  // hide indicator
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View Logic
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(40)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0:
            return "Optimal Path"
        case 1:
            return "Shortest Cumulative Distance"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {  // display paths
            return pathList.count
        } else {  // display cumulative distance
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 0) {  // expand to enable full address display
            return 105
        } else {  // default
            return CGFloat(44)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if (indexPath.section == 0) {  // path display
            cell.textLabel?.text = "\(indexPath.row + 1)) " + pathList[indexPath.row].location
            cell.textLabel?.numberOfLines = 3
            cell.detailTextLabel?.text = "\(pathList[indexPath.row].distanceFromPrevious) miles"
            cell.detailTextLabel?.textColor = UIColor.blue
        } else {  // cumulative distance
            var total = 0.0
            for path in pathList {
                total += path.distanceFromPrevious
            }
            cell.textLabel?.text = "\(total) miles"
            cell.detailTextLabel?.text = nil
        }
        return cell
    }
}
