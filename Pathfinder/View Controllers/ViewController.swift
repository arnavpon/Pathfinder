//  ViewController.swift
//  Pathfinder
//  Created by Arnav Pondicherry  on 6/23/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

// Allows user to select the locations for which to find a path

import UIKit
import GooglePlaces
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, CLLocationManagerDelegate {
    
    let searchController = UISearchController(searchResultsController: nil)  // nil -> use same view to display results
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var locationTable: UITableView!
    @IBOutlet weak var determinePathBtn: UIButton!
    
    let locationManager = CLLocationManager()  // handles location services logic
    var placesClient: GMSPlacesClient!  // handles Google Places SDK logic
    var locationList: [String] = [String]()  // list of places selected to visit
    var filteredLocations = [GMSAutocompletePrediction]()  // filtered list for search bar
    
    // View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Table View
        locationTable.delegate = self
        locationTable.dataSource = self
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        
        // Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        //searchController.searchBar.frame = CGRect(x: 0, y: 200, width: self.view.frame.width, height: 50)
        searchController.searchBar.delegate = self  // set search BAR delegate
        searchController.searchBar.placeholder = "Find a Location"  // placeholder
        navigationItem.searchController = searchController  // not compatible w/ IB yet
        definesPresentationContext = true  // ensures bar doesn't stay on screen in different VC
        
        placesClient = GMSPlacesClient.shared()  // initialize client
        locationManager.delegate = self  // set CL delegate
        locationManager.requestWhenInUseAuthorization()  // request permissions
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestLocation()  // get location
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // getCurrentPlace()  // Google Places method for getting current location
    }
    
    func getCurrentPlace() {  // finds current location w/o GPS
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {  // get most likely place
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    print(place.name)
                    print(place.formattedAddress?.components(separatedBy: ",").joined(separator: "\n"))
                }
            }
        })
    }
    
    // Table View Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
            cell.textLabel?.text = locationList[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == searchResultsTable {  // add selection to locationList
            if isFiltering() {  // make sure search bar is active
                locationList.append(filteredLocations[indexPath.row].attributedFullText.string)
                print(locationList)
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
    
    // Search Controller Delegate
    func updateSearchResults(for searchController: UISearchController) {
        print("Updating search results...")
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
    
    func placeAutocomplete(query: String) {  // Google Places SDK
        print("\nAutocomplete on \(query)")
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
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
    
    // Button Actions
    @IBAction func determinePathBtnWasClicked(_ sender: Any) {
        // logic to compute path - grab current location
    }
    
    // Location Services
    
}

