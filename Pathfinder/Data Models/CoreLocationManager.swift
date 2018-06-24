//  CoreLocationManager.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/18/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Central manager for all CoreLocation-related tasks. This object is called @ path creation time to pull in current location information (a SINGLE time), before terminating the task.

import Foundation
import CoreLocation

class CoreLocationManager: NSObject, CLLocationManagerDelegate {
    
    fileprivate let locationManager = CLLocationManager()
    
    // MARK: - Initializers
    
    override init() {
        super.init()
        locationManager.delegate = self //set delegate
    }
    
    // MARK: - External Access
    
    func startStandardUpdates() -> Bool { // DELAY function call until needed by variable obj
        let enabled = CLLocationManager.locationServicesEnabled()
        print("[startStandardUpdates()] CoreLocation Access Available?: \(enabled).")
        if (enabled) { //location services IS enabled
            if (NetworkConnection.deviceIsConnectedToNetwork()) { //internet connection is available
                print("device is connected to wifi")
                locationManager.desiredAccuracy = kCLLocationAccuracyKilometer //set accuracy -> w/in 1 km
                locationManager.distanceFilter = 500 //set movement threshold for new events [meters]
                locationManager.requestWhenInUseAuthorization() //asks user for permission to use location
                locationManager.startUpdatingLocation() //begin listening for location update
                return true
            } else {
                print("Device is NOT connected to wifi")
                //throw error (no internet)
                return false
            }
        }
        //throw error (no location services &/or internet)
        return false
    }
    
    // MARK: - Delegate Methods
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("CoreLocation authorization did change...")
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if (NetworkConnection.deviceIsConnectedToNetwork()) { //make sure device is connected
                print("App is AUTHORIZED for location services & wifi is available! Starting updates...")
                locationManager.startUpdatingLocation()
            }
        default: //access is Undetermined, Denied, or Restricted
            print("Access was DENIED for location services! Stopping updates...")
            locationManager.stopUpdatingLocation() //stop updating location (no access)
            // indicate to user to connect to Location Services
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location: CLLocation = locations.last { //get most recent location
            //Make sure the timeStamp of the location is recent (< 30 seconds old):
            let eventDate: Date = location.timestamp
            let timeDifference = eventDate.timeIntervalSinceNow
            if (abs(timeDifference)) < 30 { // set limit to < 30 seconds
                let latitude = location.coordinate.latitude
                let longitude = location.coordinate.longitude
                print("Latitude: [\(latitude)]. Longitude: [\(longitude)].")
                locationManager.stopUpdatingLocation() //end updating after receiving 1 location!
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { //sometimes thrown when there is no internet connection
        print("[locationManager] Did fail w/ error! Error: \(error).")
    }
    
}
