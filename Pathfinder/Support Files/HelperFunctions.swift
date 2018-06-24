//  HelperFunctions.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/23/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

import Foundation

typealias GeoLocation = (Double, Double)

func getEuclideanDistance(firstLocation: GeoLocation, secondLocation: GeoLocation) -> Double {
    let (x1, y1) = firstLocation
    let (x2, y2) = secondLocation
    return pow((pow((x2 - x1), 2.0) + pow((y2-y1), 2.0)), 0.5)  // compute distance
}
