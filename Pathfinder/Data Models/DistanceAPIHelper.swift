//  DistanceAPIHelper.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/24/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

// Provides logic to compute distances between locations using Google Distance Matrix API

import Foundation
import CoreLocation

struct DistanceAPIHelper {
    
    private let origin: CLLocationCoordinate2D
    private let destination: CLLocationCoordinate2D
    private let baseURL = URL(string: "https://maps.googleapis.com/maps/api/distancematrix/")
    
    private var finalURL: URL {  // construct dynamically using origin/destination
        return URL(string: "json?units=imperial&origins=\(origin.latitude),\(origin.longitude)&destinations=\(destination.latitude),\(destination.longitude)&key=\(CONSTANT_API_KEY)", relativeTo: baseURL)!
    }
    
    // MARK: - Initializers
    
    init(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        self.origin = origin
        self.destination = destination
    }
    
    // MARK: - Networking
    
    func getDistanceBetweenLocations(completion: @escaping (Double?) -> Void) {  // -> distance?
        print("\nMaking network request...")
        let connection = NetworkConnection(url: finalURL)  // construct Network object
        connection.downloadJSONFromURL { (data) in
            if let json = data, let status = json["status"] as? String {
                print("Status: \(status)")
                if (status == "OK") {  // make sure request was processed
                    if let rows = json["rows"] as? NSArray, let result = rows.firstObject as? [String: AnyObject], let elements = result["elements"] as? NSArray, let first = elements.firstObject as? [String: AnyObject], let state = first["status"] as? String {
                        if (state == "OK") {  // successful request
                            if let distance = first["distance"] as? Dictionary<String, AnyObject>, let value = distance["value"] as? Double, let _ = distance["text"] as? String {
                                completion(value)
                                return  // terminate closure to prevent nil return
                            }
                        } else if (state == "ZERO_RESULTS") {  // handle failure appropriately
                            print("No results found")
                        }
                    }
                }
            }
            completion(nil)  // default return value
        }
    }
    
    // MARK: - Alternative Distance Metrics
    
    func getEuclideanDistance() -> Double {
        let (x1, y1) = (origin.latitude, origin.longitude)
        let (x2, y2) = (destination.latitude, destination.longitude)
        return pow((pow((x2 - x1), 2.0) + pow((y2-y1), 2.0)), 0.5)  // compute distance
    }
    
}
