//  OptimalPathSearch.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/23/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

// Utilize search, constraint propagation to find optimal path (minimize total distance)
// when we add a node to the search tree, it needs to have coordinates for us to calculate the distances between locations. Search will take exceedingly long if we need to stop to make an API request each time we add a node to the tree, so we will need some way to obtain & cache locations prior to starting the search. FOR ALL NON-UNIQUE LOCATIONS ON LIST, before search starts, send API request to find locations (up to 20) & cache them.
// we don't have a "goal" per se, so DFS won't work (no absolute goal)
// we need to expand ALL possibilities (that satisfy existing constraints),
// then see which path is the shortest & return that one
// (1) start at current location
// (2) expand search tree breadth first until ALL possibilities are exhausted
//  - to add node, check if location is unique or not
//  - if UNIQUE, add location (coordinates) to branch (as is): +1 node
//  - if NON-UNIQUE, get cached list of related locations & add EACH loc in list as node: +X nodes
//      - compute distance between previous node & current node to grow path length
//  - once a location is added to tree, remove it from "remaining" list
// (3) if returnToStart is True, end @ currentLocation as final node in each branch
//  - if not, end @ last node that is already present
// ** how to handle edge cases where data (locations) are missing **

import Foundation
import CoreLocation

class OptimalPathSearch {
    
    private let currentLocation: CLLocationCoordinate2D
    private let locationList: [Place]
    private let returnToStart: Bool
    private var shortestPathLength: Double = 0.0
    private var distancesAlongPath = [Double]()
    
    // MARK: - Initializers
    
    init(currentLoc: CLLocationCoordinate2D, locations: [Place], returnToStart: Bool) {
        // initialize w/ Place objects
        self.currentLocation = currentLoc
        self.locationList = locations
        self.returnToStart = returnToStart
    }
    
    func getOptimalPathLength() -> Double {  // return minimum path
        return self.shortestPathLength
    }
    
    func getDistancesAlongPath() -> [Double] {
        return distancesAlongPath
    }
    
    func getPlaces(completion: ([[CLLocationCoordinate2D]]) -> Void) {
        var locationPossibilities = [[CLLocationCoordinate2D]]()  // list of lists of coordinates
        for location in locationList {  // iterate through each location in list
            if (location.isUnique) {  // unique location - add to list AS-IS
                locationPossibilities.append([location.coordinates!])
            } else {  // NON-unique location - expand list into nearby possibilities
                
            }
        }
        completion(locationPossibilities)  // return list of nearby locations async
    }
    
    // MARK: - Search Methods
    
    func computeOptimalPath() -> [String] {  // searches for optimal path using DFS
        // store the shortest path & its length, replace if shorter path is found
        let initial = currentLocation  // starting state
        var frontier = [[Place]]()  // frontier is LIST of PATHS (sequences of Place objects)
        for successor in self.getSuccessorStates(state: nil) {  // add initial paths to search
            frontier.append([successor])
        }
        var explored = Set<Place>()  // explored set starts out empty
        
        // explored needs to be customized
        // references overall list of places
        // within each path, needs to keep track of which places in list remain to be explored
        
        while !(frontier.isEmpty) {
            let path = frontier.remove(at: 0)  // pop 0th item in array (FIFO)
            if let endState = path.last {  // get the last Place along the path
                explored.insert(endState)  // add end state to explored set
                // goal test again - check if remaining locations are gone
                for s in self.getSuccessorStates(state: endState) {
                    if !(explored.contains(s)) {  // make sure state is NOT in explored
                        var expandedPath = path  // initialize
                        expandedPath.append(s)  // add next successor
                        frontier.insert(expandedPath, at: 0)  // add FULL path back -> 0th index
                    }
                }
            }
        }
        return []
    }
    
    private func getSuccessorStates(state: Place?) -> [Place] {  // return child Place objects
        if let s = state {  // state was input
            
        } else {  // no state was input - INITIAL STATE
            
        }
        return []
    }
    
    private func goalTest() {  // check if NEW path has shorter cost than OLD shortest path
        // store new shortest path + cost
    }
    
    // MARK: - Constraint Propagation Methods
    
}
