//  PathDisplayViewController.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/24/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

//  Displays the computed path - show each location in numbered list, w/ distance from point A -> point B & total (cumulative) distance underneath.

import UIKit
import GooglePlaces
import SystemConfiguration

class PathDisplayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var pathTable: UITableView!
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    
    var intelligentAgent: OptimalPathSearch?  // performs search
    var shortestPath: [Node] = []
    var shortestPathDistance: Double = 0.0
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Activity Indicator
        let width: CGFloat = 40.0
        self.view.addSubview(activityIndicator)  // add to main view
        activityIndicator.frame = CGRect(x: (self.view.frame.midX - width), y: (self.view.frame.midY - width), width: width, height: width)  // center indicator in view
        activityIndicator.hidesWhenStopped = true  // hide if not spinning
        activityIndicator.startAnimating()  // spin before computing
        
        // Perform search & update UI:
        if let agent = self.intelligentAgent {  // do this async, then update UI
            var coordsAvailable = false
            while !(coordsAvailable) { // do nothing until ALL Place objects have assigned coordinates
                sleep(UInt32(0.10))  // sleep for 1/10 of a second
                coordsAvailable = agent.checkAllLocationsHaveCoordinates()  // repeat check
            }
            (shortestPath, shortestPathDistance) = agent.computeOptimalPath()  // get shortest path
            
            // Update with true distances
            var temp: [Node] = []  // for Nodes w/ true distances
            for (i, node) in shortestPath.enumerated() {
                if i == 0 {  // first element, compute distance -> start
                    DistanceAPIHelper(origin: agent.getStartLocation(), destination: node.place.coordinates!).getDistanceBetweenLocations { (distance) in
                        if let dist = distance {
                            let new = Node(place: node.place, distance: dist)
                            temp.append(new)  // update with true distance
                        }
                    }
                } else {  // compute distance between current node & previous node
                    DistanceAPIHelper(origin: shortestPath[i-1].place.coordinates!, destination: node.place.coordinates!).getDistanceBetweenLocations { (distance) in
                        if let dist = distance {
                            let new = Node(place: node.place, distance: dist)
                            temp.append(new)  // update with true distance
                        }
                    }
                }
            }
            // *** won't work b/c will return before true Nodes are added to source!
            self.shortestPath = temp  // update data source w/ accurate distances
            
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
        if (section == 0) {  // display paths + between distances
            return shortestPath.count
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
            cell.textLabel?.text = "\(indexPath.row + 1)) " + shortestPath[indexPath.row].place.fullName
            cell.textLabel?.numberOfLines = 3
            cell.detailTextLabel?.text = "\(shortestPath[indexPath.row].distanceToPreviousNode) miles"
            cell.detailTextLabel?.textColor = UIColor.blue
        } else {  // cumulative distance
            cell.textLabel?.text = "\(shortestPathDistance) miles"
            cell.detailTextLabel?.text = nil  // no detail
        }
        return cell
    }
}
