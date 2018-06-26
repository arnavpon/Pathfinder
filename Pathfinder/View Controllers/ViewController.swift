//  ViewController.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/23/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

// Allows user to select the locations for which to compute an optimal path (at least 3)

// why isn't search bar showing as soon as page loads???

import UIKit
import GooglePlaces
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, CLLocationManagerDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)  // handles searches
    @IBOutlet weak var searchResultsTable: UITableView!  // displays search results
    @IBOutlet weak var locationTable: UITableView!  // determines selected locations
    @IBOutlet weak var determinePathBtn: UIButton!  // computes optimal path
    
    var intelligentAgent: OptimalPathSearch?  // handles search logic
    var returnToStart: Bool = true  // indicates whether user will return to start @ end of trip
    let locationManager = CLLocationManager()  // handles location services logic
    var placesClient: GMSPlacesClient!  // handles Google Places SDK logic
    var locationList = [Place]() { // list of places selected to visit
        didSet {
            if (locationList.count > 2) {  // enable btn after 2+ locations are added
                determinePathBtn.isEnabled = true
            } else {  // disable
                determinePathBtn.isEnabled = false
            }
        }
    }
    var filteredLocations = [GMSAutocompletePrediction]()  // filtered list for search bar
    var currentLocation: CLLocationCoordinate2D? {  // current location
        didSet {
            if let loc = currentLocation {
                print("Currently @ \(loc)")
            }
        }
    }
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        determinePathBtn.isEnabled = false  // disable to start
        NotificationCenter.default.addObserver(self, selector: #selector(applicationIsReappearing(_:)), name: NSNotification.Name("applicationWillEnterForeground"), object: nil)  // register for foreground appearance notification
        
        // Table View
        locationTable.delegate = self
        locationTable.dataSource = self
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        
        // Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false  // don't dim background
        searchController.searchBar.delegate = self  // set search BAR delegate
        searchController.searchBar.placeholder = "Find a Location"  // placeholder
        navigationItem.searchController = searchController  // not compatible w/ IB yet
        definesPresentationContext = true  // ensures bar doesn't stay on screen in different VC
        
        // Location & Places logic:
        placesClient = GMSPlacesClient.shared()  // initialize client
        locationManager.delegate = self  // set CL delegate
        locationManager.requestWhenInUseAuthorization()  // request usage permission
        getCurrentLocation()  // method to find location
    }
    
    private func isLocationUnique(selectionIndex: Int, places: [GMSAutocompletePrediction]) -> Bool {  // determines if selection is unique address or chain (e.g. grocery store)
        print("\nIs location unique?")
        var copy = places  // make mutable copy
        let selection = copy.remove(at: selectionIndex)  // remove place from array
        for place in copy {  // iterate through REMAINING places
            print(place.attributedPrimaryText.string)
            if (place.attributedPrimaryText.string.range(of: selection.attributedPrimaryText.string) != nil) {  // check if selection name is WHOLLY contained in other place name
                print("NOT unique")
                return false
            }
        }
        print("UNIQUE location!")
        return true
    }
    
    @objc
    private func applicationIsReappearing(_ notification: Notification) {
        getCurrentLocation()  // re-check for location
    }
    
    // MARK: - Table View Logic
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(40)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == searchResultsTable {
            return "Search Results"
        } else {
            return "Selected Locations"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == searchResultsTable {  // show filtered list
            if isFiltering() {  // user is searching
                return filteredLocations.count
            }
            return 0  // show nothing until user activates search bar
        }
        return locationList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == searchResultsTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
            if isFiltering() {  // search is occurring
                cell.textLabel?.text = filteredLocations[indexPath.row].attributedFullText.string
            } else {  // not searching
                cell.textLabel?.text = nil
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
            cell.textLabel?.text = locationList[indexPath.row].primaryName
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == searchResultsTable {  // add selection to locationList
            if isFiltering() {  // make sure search bar is active
                locationList.append(Place(name: filteredLocations[indexPath.row], isUnique: isLocationUnique(selectionIndex: indexPath.row, places: filteredLocations)))
                locationList.last!.findPlacesNearLocation(location: self.currentLocation!) { (coords) in
                    // ***
                }
                locationTable.reloadData()  // update UI
                searchController.searchBar.text = nil  // clear text in search bar
                searchController.searchBar.resignFirstResponder()  // exit search bar
                filteredLocations = []  // clear data source
                searchResultsTable.isHidden = true  // hide table
            }
        } else {
            locationList.remove(at: indexPath.row)  // remove location from table
        }
        tableView.reloadData() // update UI
    }
    
    // MARK: - Search Controller Logic
    
    func updateSearchResults(for searchController: UISearchController) {
        if !(searchBarIsEmpty()) {  // make sure there is text in the search bar
            searchResultsTable.isHidden = false  // reveal table
            placeAutocomplete(query: searchController.searchBar.text!)  // pass query -> Places handler
        } else {
            filteredLocations = []  // clear array
            searchResultsTable.reloadData()  // reload UI
            searchResultsTable.isHidden = true
        }
    }
    
    func searchBarIsEmpty() -> Bool {  // returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {  // checks if search bar is currently being used
        return searchController.isActive && !(searchBarIsEmpty())
    }
    
    func placeAutocomplete(query: String) {  // Google Places SDK - returns up to 5 results
        let filter = GMSAutocompleteFilter()
        filter.type = .noFilter  // filters the type of result received
        placesClient.autocompleteQuery(query, bounds: nil, filter: filter, callback: {(results, error) -> Void in
            if let error = error {
                print("Autocomplete error: \(error)")
                return
            }
            if let results = results {
                self.filteredLocations = results  // update filteredLocations list
                DispatchQueue.main.async {  // update UI on main
                    self.searchResultsTable.reloadData()
                }
            }
        })
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filteredLocations = []  // clear data source
        searchResultsTable.reloadData()  // update UI
        searchResultsTable.isHidden = true  // hide table
    }
    
    // MARK: - Button/Switch Actions
    
    @IBAction func returnSwitchWasToggled(_ sender: Any) {
        self.returnToStart = (sender as! UISwitch).isOn
    }
    
    @IBAction func determinePathBtnWasClicked(_ sender: Any) {
        if !(self.locationList.isEmpty) {
            if let current = currentLocation {
                self.intelligentAgent = OptimalPathSearch(currentLoc: current, locations: locationList, returnToStart: returnToStart) // initialize intelligent agent
                if self.shouldPerformSegue(withIdentifier: "showPathDisplayVC", sender: nil) {
                    performSegue(withIdentifier: "showPathDisplayVC", sender: nil)  // move to next page
                }
            }
        }
    }
    
    // MARK: - Location Services
    
    func getCurrentLocation() {
        getCurrentPlace()  // Google Places method for getting current location
        if CLLocationManager.locationServicesEnabled() {  // CL - set properties & start updating
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestLocation()  // get location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("[CLManager] Updated current location: ")
        print(locations.first!.coordinate)
        currentLocation = locations.first?.coordinate  // store current location
        manager.stopUpdatingLocation()  // stop obtaining location after receiving current
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location mgr failed w/ error: \(error.localizedDescription)")
    }
    
    func getCurrentPlace() {  // Google Places method to obtain current location
        print("[GooglePlaces API] Getting current place...")
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {  // get most likely place
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.currentLocation = place.coordinate  // set current location
                }
            }
        })
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        do {
            let connected = try Reachability()?.isConnectedToNetwork  // check for network
            if (connected == true) {  // connected to network
                var shouldSegue: Bool = true
                for place in self.locationList {
                    if (place.isUnique) {  // get coords for place
                        
                    } else {  // find up to the 5 nearest matches & store somehow
                        
                    }
                    place.getCoordinatesForPlace { (coords) in
                        if (coords == nil) {  // stop segue if any Place coordinates are not found
                            shouldSegue = false  // set blocker
                        }
                    }
                }
                return shouldSegue  // *** probably won't work - blocking even when conn exists
            } else {  // NOT connected to network
                let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                let controller = UIAlertController(title: "No Internet Connection", message: "Please connect to the internet to find the optimal path.", preferredStyle: UIAlertControllerStyle.alert)
                controller.addAction(ok)
                self.present(controller, animated: true, completion: nil)
                return false  // block segue
            }
        } catch let error {
            print("Error - \(error.localizedDescription)")
        }
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! PathDisplayViewController
        destination.intelligentAgent = self.intelligentAgent  // pass agent
    }
}

