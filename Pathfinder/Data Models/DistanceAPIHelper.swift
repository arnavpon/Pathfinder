//  DistanceAPIHelper.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/24/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

// Provides logic to compute distances between locations using Google Distance Matrix API
// modify to handle batch requests...

import Foundation
import CoreLocation

extension Double {
    var degreesToRadians: Double {
        return self * .pi / 180
    }
    var radiansToDegrees: Double {
        return self * 180 / .pi
    }
    
    func rounded(toPlaces places: Int) -> Double {  // rounds Double to X number of places
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

struct DistanceAPIHelper {
    
    private let origin: CLLocationCoordinate2D
    private let destination: CLLocationCoordinate2D
    private let baseURL = URL(string: "https://maps.googleapis.com/maps/api/distancematrix/")
    
    private var finalURL: URL {  // construct dynamically using origin/destination
        return URL(string: "json?units=imperial&origins=\(origin.latitude)%2C\(origin.longitude)&destinations=\(destination.latitude)%2C\(destination.longitude)&key=\(CONSTANT_API_KEY)", relativeTo: baseURL)!
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
                            if let distance = first["distance"] as? Dictionary<String, AnyObject>, let value = distance["value"] as? Double, let _ = distance["text"] as? String {  // distance returned in meters
                                completion((value / 1600.0).rounded(toPlaces: 2))
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
    
    func getEuclideanDistance() -> Double {  // Haversine formula - finds distance between lat/long
        let radius: Double = 6371  // Earth's radius in km
        let (x1, y1) = (origin.latitude.degreesToRadians, origin.longitude.degreesToRadians)
        let (x2, y2) = (destination.latitude.degreesToRadians, destination.longitude.degreesToRadians)
        let differenceLatitude = x2 - x1  // latitude difference in radians
        let differenceLongitude = y2 - y1  // longitude difference in radians
        let a = pow(sin(differenceLatitude/2), 2) + cos(x1) * cos(x2) * pow(sin(differenceLongitude/2), 2)
        let c = 2 * atan2(pow(a, 0.5), pow(1-a, 0.5))
        return (radius * c / 1.6).rounded(toPlaces: 2)  // distance in miles
    }
    
}
