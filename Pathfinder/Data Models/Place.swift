//  Place.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/24/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

import Foundation
import CoreLocation

class Place {  // class representing a location
    
    let name: String  // text representation of location
    let isUnique: Bool  // indicates if address is unique or not
    var coordinates: CLLocationCoordinate2D?  // latitude & longitude for address
    
    private let baseGeocodeURL = URL(string: "https://maps.googleapis.com/maps/api/geocode/")!
    private var geocodeURL: URL {
        let encodedName = name.replacingOccurrences(of: " ", with: "+")  // remove spaces
        return URL(string: "json?address=\(encodedName)&key=\(CONSTANT_API_KEY)", relativeTo: baseGeocodeURL)!
    }
    
    private let baseSearchURL = URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/")!
    
    
    // MARK: - Initializers
    
    init(name: String, isUnique: Bool) {
        self.name = name
        self.isUnique = isUnique
    }
    
    // MARK: - Instance Methods
    
    func findPlaceNearLocation(location: CLLocationCoordinate2D, completion: @escaping ([CLLocationCoordinate2D]) -> Void) {
        // Search for nearby locations of NON-unique places:
        let encodedName = self.name.replacingOccurrences(of: " ", with: "%20")  // remove spaces
        let searchURL = URL(string: "json?location=\(location.latitude),\(location.longitude)&rankby=distance&keyword=\(encodedName)&key=\(CONSTANT_API_KEY)", relativeTo: baseSearchURL)!
        print("Searching \(searchURL.absoluteString)...")
        let connection = NetworkConnection(url: searchURL)  // initialize network object
        connection.downloadJSONFromURL { (data) in
            var matchingLocations = [CLLocationCoordinate2D]()  // return object
            if let json = data, let results = json["results"] as? NSArray {
                print("\n\nFound \(results.count) results")
                for result in results {
                    if let result = result as? [String: AnyObject], let geometry = result["geometry"] as? [String: AnyObject], let location = geometry["location"] as? [String: Double], let latitude = location["lat"], let longitude = location["lng"] {
                        let name = result["name"] as! String  // make sure name matches query
                        print("\(name): \(latitude), \(longitude)\n")
                        if name == self.name {  // EXACT name match
                            matchingLocations.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))  // add item to return object
                        }
                    }
                }
            }
            completion(matchingLocations)  // return found matches
        }
    }
    
    func getCoordinatesForPlace() {  // extract coordinates given place name
        let connection = NetworkConnection(url: geocodeURL)  // initialize network object
        connection.downloadJSONFromURL { (data) in
            if let json = data, let results = json["results"] as? NSArray, let result = results.firstObject as? [String: AnyObject], let geometry = result["geometry"] as? [String: AnyObject], let location = geometry["location"] as? [String: Double], let latitude = location["lat"], let longitude = location["lng"] {
                self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
    }
}
