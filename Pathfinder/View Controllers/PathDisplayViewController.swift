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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var intelligentAgent: OptimalPathSearch?  // performs search
    var shortestPath: [Node] = [] {
        didSet {
            shortestPathDistance = 0.0
            for node in shortestPath {  // update total path distance
                shortestPathDistance += node.distanceToPreviousNode
            }
            DispatchQueue.main.async {
                self.pathTable.reloadData()  // update UI on main
            }
        }
    }
    var shortestPathDistance: Double = 0.0
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pathTable.delegate = self
        pathTable.dataSource = self  // setting source will refresh UI
    }
    
    override func viewWillAppear(_ animated: Bool) {
        activityIndicator.startAnimating()  // spin before computing
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let agent = self.intelligentAgent {  // perform search & update UI
            var placesAvailable = false
            while !(placesAvailable) { // do nothing until ALL Place objects are set
                sleep(UInt32(1))  // sleep for 1 second
                placesAvailable = agent.checkAllPlacesAvailable()  // repeat check
            }
            
            var coordsAvailable = false
            while !(coordsAvailable) { // do nothing until ALL Place objects have assigned coordinates
                sleep(UInt32(1))  // sleep for 1 second
                coordsAvailable = agent.checkAllLocationsHaveCoordinates()  // repeat check
            }
            
            // Update the shortestPath nodes with true distances:
            (shortestPath, shortestPathDistance) = agent.computeOptimalPath()  // get shortest path
            for (i, node) in shortestPath.enumerated() {
                if i == 0 {  // first element, compute distance -> start
                    DistanceAPIHelper(origin: agent.getStartLocation(), destination: node.place.coordinates!).getDistanceBetweenLocations { (distance) in
                        if let dist = distance {  // update with true distance
                            self.shortestPath[i] = Node(place: node.place, distance: dist)
                        }
                    }
                } else {  // compute distance between current node & previous node
                    DistanceAPIHelper(origin: shortestPath[i-1].place.coordinates!, destination: node.place.coordinates!).getDistanceBetweenLocations { (distance) in
                        if let dist = distance {  // update with true distance
                            self.shortestPath[i] = Node(place: node.place, distance: dist)
                        }
                    }
                }
            }
            self.pathTable.reloadData()  // update UI
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
            return (shortestPath.count + 1)
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
            if (indexPath.row == 0) {
                cell.textLabel?.text = "Current Location"
                cell.detailTextLabel?.text = "-----"
            } else {
                cell.textLabel?.text = "\(indexPath.row)) " + shortestPath[indexPath.row-1].place.fullName
                cell.textLabel?.numberOfLines = 3
                cell.detailTextLabel?.text = "\(shortestPath[indexPath.row-1].distanceToPreviousNode) miles from last stop"
                cell.detailTextLabel?.textColor = UIColor.blue
            }
        } else {  // cumulative distance
            cell.textLabel?.text = "\(shortestPathDistance) miles"
            cell.detailTextLabel?.text = nil  // no detail
        }
        return cell
    }
}
