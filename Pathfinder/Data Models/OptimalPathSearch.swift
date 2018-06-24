//  OptimalPathSearch.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/23/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

// Utilize search, constraint propagation to find optimal path (minimize total distance)

// needs way to make Places API call to obtain locations with matching name
// use PlaceAPI Place Search request

import Foundation
import CoreLocation
import GooglePlaces

struct Path {
    
    let location: String  // *** change to Place type
    let distanceFromPrevious: Double
    
    init(loc: String, distance: Double) {
        self.location = loc
        self.distanceFromPrevious = distance
    }
    
}

class OptimalPathSearch {
    
    let currentLocation: CLLocationCoordinate2D
    let locationList: [Place]
    let returnToStart: Bool
    
    // MARK: - Initializers
    
    init(currentLoc: CLLocationCoordinate2D, locations: [Place], returnToStart: Bool) {  // initialize w/ locations names (w/ coordinates for unique places)
        self.currentLocation = currentLoc
        self.locationList = locations
        self.returnToStart = returnToStart
    }
    
    // MARK: - Search Methods
    
    func computeOptimalPath() -> [Path] {
        var paths: [Path] = []
        for loc in locationList {
            paths.append(Path(loc: loc.name, distance: 0.0))
        }
        return paths
    }
    
    // MARK: - Constraint Propagation Methods
    
}
