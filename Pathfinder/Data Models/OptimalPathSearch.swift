//  OptimalPathSearch.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/23/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

// Utilize search, constraint propagation to find optimal path (minimize total distance)

import Foundation
import CoreLocation

class OptimalPathSearch {
    
    private let currentLocation: CLLocationCoordinate2D
    private let returnToStart: Bool  // should path return to starting point?
    private var locationList: [[Place]]  // @ each index: 1 entry for unique, > 1 entry for non-unique
    private var shortestPath: [Node] = []  // optimal path
    private var shortestPathLength: Double = Double.infinity  // init w/ max possible distance
    
    // MARK: - Initializers
    
    init(currentLoc: CLLocationCoordinate2D, locations: [[Place]], returnToStart: Bool) {
        // initialize w/ Place objects
        self.currentLocation = currentLoc
        self.locationList = locations
        self.returnToStart = returnToStart
    }
    
    func updateLocationListAtIndex(index: Int, places: [Place]) {  // called by Closure in VC
        self.locationList[index] = places  // update value @ specified index
        print("Updated LL w/ \(places.count) places @ index \(index).")
    }
    
    func getStartLocation() -> CLLocationCoordinate2D {  // getter
        return self.currentLocation
    }
    
    func checkAllLocationsHaveCoordinates() -> Bool {  // returns True if EACH Place has coords
        print("\nCoordinates check...")
        for locations in locationList {
            for location in locations {
                if (location.coordinates == nil) {
                    print("Missing coordinates!\n")
                    return false  // terminate
                }
            }
        }
        print("All coordinates present!")
        return true
    }
    
    func checkAllPlacesAvailable() -> Bool {  // safety check before running search
        print("\nPlaces check...")
        for (i, locations) in locationList.enumerated() {
            if (locations.isEmpty) {  // return false if any inner list of locations is empty
                print("Missing place @ index \(i)")
                return false
            }
        }
        return true  // default
    }
    
    // MARK: - Search Methods
    
    func computeOptimalPath() -> ([Node], Double) {  // searches for optimal path using DFS
        var frontier = [[Node]]()  // frontier is LIST of PATHS (sequences of Place objects)
        for successor in self.getSuccessorStates(path: nil) {  // add initial paths to search
            frontier.append([successor])
        }
        
        while !(frontier.isEmpty) {  // iterate until frontier is empty
            let path = frontier.remove(at: 0)  // pop 0th item in array (FIFO)
            let successors = self.getSuccessorStates(path: path)
            if (successors.isEmpty) {  // no successors remain - full path constructed
                let (fullPath, distance) = self.getTotalDistanceForPath(path: path)
                if (distance < self.shortestPathLength) {  // new shortest path
                    print("New shortest path = \(distance) mi. Old = \(shortestPathLength).")
                    self.shortestPath = fullPath  // update path
                    self.shortestPathLength = distance  // update distance
                }
            }
            for s in self.getSuccessorStates(path: path) {  // successors exist
                var expandedPath = path  // initialize
                expandedPath.append(s)  // add successor Node
                frontier.insert(expandedPath, at: 0)  // add FULL path back -> 0th index
            }
        }
        return (self.shortestPath, self.shortestPathLength)
    }
    
    private func getSuccessorStates(path: [Node]?) -> [Node] {  // return child Place objects
        // compute distance between each successor & last node in path before adding
        var successors: [Node] = []
        if let p = path, let lastNode = p.last {  // state was input
            // Check primary name for each Place in path, knock it off list of possibilities:
            var possibleLocations = self.getPossibleLocations()
            for node in p {  // remove each existing Place from list of possibilities
                possibleLocations.remove(node.place.primaryName)
            }
            for locations in self.locationList {
                for loc in locations {
                    if (possibleLocations.contains(loc.primaryName)) {  // filter used locations
                        let distance = DistanceAPIHelper(origin: lastNode.place.coordinates!, destination: loc.coordinates!).getEuclideanDistance()  // get distance
                        successors.append(Node(place: loc, distance: distance))  // add Node
                    }
                }
            }
        } else {  // no state was input - INITIAL STATE, all successors possible
            for locations in self.locationList {
                for loc in locations {
                    let distance = DistanceAPIHelper(origin: self.currentLocation, destination: loc.coordinates!).getEuclideanDistance()
                    successors.append(Node(place: loc, distance: distance))  // add Node
                }
            }
        }
        return successors
    }
    
    private func getPossibleLocations() -> Set<String> {  // gets FULL list of possible Place objects
        var possibilities = Set<String>()
        for locations in self.locationList {  // iterate through, extract names
            if let first = locations.first {  // get ANY item in list
                possibilities.insert(first.primaryName)
            }
        }
        return possibilities
    }
    
    private func getTotalDistanceForPath(path: [Node]) -> ([Node], Double) {
        var fullPath: [Node] = path
        var totalDistance: Double = 0.0
        for node in path {  // add up individual distances along path
            totalDistance += node.distanceToPreviousNode
        }
        if (self.returnToStart) {  // add distance from last Node -> start location
            if let lastNode = path.last, let coords = lastNode.place.coordinates {
                let helper = DistanceAPIHelper(origin: coords, destination: self.currentLocation)
                let d = helper.getEuclideanDistance()
                totalDistance += d
                fullPath.append(Node(place: Place(primary: "Current Address", full: "Current Address", coords: currentLocation), distance: d))  // add start location to Path
            }
        }
        return (fullPath, totalDistance)
    }
    
    // MARK: - Constraint Propagation Methods
    
}
