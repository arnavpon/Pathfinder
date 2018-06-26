//  Place.swift
//  Pathfinder
//  Created by Arnav Pondicherry on 6/24/18.
//  Copyright © 2018 Arnav Pondicherry. All rights reserved.

import Foundation
import CoreLocation
import GooglePlaces

class Place: Hashable {
    
    let primaryName: String  // PRIMARY name representation of location
    let fullName: String  // FULL name representation of location
    let isUnique: Bool  // indicates if address is unique or not
    var coordinates: CLLocationCoordinate2D?  // latitude & longitude for address
    
    private let baseSearchURL = URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/")!
    private let baseGeocodeURL = URL(string: "https://maps.googleapis.com/maps/api/geocode/")!
    private var geocodeURL: URL {  // use FULL name, replace spaces w/ '+'
        let encodedName = fullName.replacingOccurrences(of: " ", with: "+")
        return URL(string: "json?address=\(encodedName)&key=\(CONSTANT_API_KEY)", relativeTo: baseGeocodeURL)!
    }
    
    // MARK: - Initializers
    
    init(name: GMSAutocompletePrediction, isUnique: Bool) {
        self.primaryName = name.attributedPrimaryText.string
        self.fullName = name.attributedFullText.string
        self.isUnique = isUnique
    }
    
    init(primary: String, full: String, coords: CLLocationCoordinate2D) {
        self.primaryName = primary
        self.fullName = full
        self.coordinates = coords
        self.isUnique = false  // this init ONLY used for non-unique locations
    }
    
    // MARK: - Hashable Protocol
    
    var hashValue: Int {  // hash of FULL name of place
        return self.fullName.hashValue
    }
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        if (lhs.fullName == rhs.fullName) {  // same FULL name => same place
            return true
        }
        return false
    }
    
    // MARK: - Instance Methods
    
    func findPlacesNearLocation(location: CLLocationCoordinate2D, completion: @escaping ([Place]) -> Void) {  // search for nearby locations of NON-unique places
        let encodedName = primaryName.replacingOccurrences(of: " ", with: "%20")  // encode spaces
        let searchURL = URL(string: "json?location=\(location.latitude),\(location.longitude)&rankby=distance&keyword=\(encodedName)&key=\(CONSTANT_API_KEY)", relativeTo: baseSearchURL)!
        print("Searching \(searchURL.absoluteString)...")
        let connection = NetworkConnection(url: searchURL)  // initialize network object
        connection.downloadJSONFromURL { (data) in
            var matchingLocations = [Place]()  // return object
            if let json = data, let results = json["results"] as? NSArray {
                print("\n\nFound \(results.count) nearby places")
                for result in results {
                    if let result = result as? [String: AnyObject], let vicinity = result["vicinity"] as? String, let geometry = result["geometry"] as? [String: AnyObject], let location = geometry["location"] as? [String: Double], let latitude = location["lat"], let longitude = location["lng"], let resultName = result["name"] as? String {
                        print("[\(latitude), \(longitude)] \(resultName): \(vicinity)\n")
                        if resultName == self.primaryName {  // EXACT match - add to return object
                            matchingLocations.append(Place(primary: resultName, full: vicinity, coords: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
                        }
                    }
                    if let result = result as? [String: AnyObject], let placeID = result["place_id"] as? String {
                        print("[ID]: \(placeID)\n")  // do nothing
                    }
                }
            }
            if (matchingLocations.isEmpty) { // NO matches found - look up coordinates for self
                self.getCoordinatesForPlace(completion: { (coordinates) in })
            } else {  // matches found
                completion(matchingLocations)  // return found Place objects
            }
        }
    }
    
    func getCoordinatesForPlace(completion: @escaping (CLLocationCoordinate2D?) -> Void) {  // extract coordinates given a location's name
        let connection = NetworkConnection(url: geocodeURL)  // initialize network object
        connection.downloadJSONFromURL { (data) in
            if let json = data, let results = json["results"] as? NSArray, let result = results.firstObject as? [String: AnyObject], let geometry = result["geometry"] as? [String: AnyObject], let location = geometry["location"] as? [String: Double], let latitude = location["lat"], let longitude = location["lng"] {
                self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                completion(self.coordinates!)  // return coordinates
                return  // terminate function
            }
        }
        completion(nil)  // return nil if JSON request fails
    }
    
    private func getReverseGeocodingURL(id: String) -> URL {
        let base = URL(string: "https://maps.googleapis.com/maps/api/geocode/")!
        return URL(string: "json?place_id=\(id)&key=\(CONSTANT_API_KEY)", relativeTo: base)!
    }
    
    func getFullNameForPlaceID(id: String, completion: @escaping (String) -> Void) {
        let connection = NetworkConnection(url: self.getReverseGeocodingURL(id: id))
        connection.downloadJSONFromURL { (data) in
            if let json = data, let results = json["results"] as? NSArray, let result = results.firstObject as? [String: AnyObject], let address = result["formatted_address"] as? String {
                print("Address: \(address)")
            }
        }
    }
}
