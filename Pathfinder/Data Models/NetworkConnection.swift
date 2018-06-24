//  NetworkConnection.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// GENERIC class responsible for creating a network connection & downloading JSON data from a specified URL.

import Foundation
import SystemConfiguration

class NetworkConnection { //conforms to error reporting protocol
    
    lazy var config: URLSessionConfiguration = URLSessionConfiguration.default
    lazy var session: URLSession = URLSession(configuration: self.config)
    fileprivate let queryURL: URL
    fileprivate let postBody: Data? //optional POST request body
    fileprivate let blockContentTypeHeader: Bool //for POST request - REQUIRED for Nutrition API
    
    // MARK: - Network Connectivity [CLASS METHOD]
    
    class func deviceIsConnectedToNetwork() -> Bool { //checks if Wifi is available; **does not work for Cellular Data apparently!
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        return (isReachable) && !(needsConnection)
    }
    
    // MARK: - Initializers
    
    init(url: URL) { //initialize w/ the URL to which the network request is being sent
        self.queryURL = url
        self.postBody = nil
        self.blockContentTypeHeader = false
    }
    
    init(url: URL, postBody: Data, blockContentTypeHeader: Bool) { //POST request initializer
        self.queryURL = url
        self.postBody = postBody
        self.blockContentTypeHeader = blockContentTypeHeader //set blocker as needed
    }
    
    // MARK: - Networking Logic
    
    typealias JSONDictionaryCompletion = ([String: AnyObject]?) -> Void //closure typeAlias
    
    func downloadJSONFromURL(_ completion: @escaping JSONDictionaryCompletion) {
        print("Downloading JSON From URL...")
        let request = NSMutableURLRequest(url: queryURL)
        if let body = postBody { //check if request contains JSON data to POST
            request.httpMethod = "POST"
            if !(blockContentTypeHeader) { //check for blocker before setting header
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }
            request.httpBody = body
        }
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: //successful response
                    print("HTTP Response 200")
                    do {
                        if let receivedData = data { //serialize JSON object into a dictionary
                            let jsonDictionary = try JSONSerialization.jsonObject(with: receivedData, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: AnyObject]
                            completion(jsonDictionary)
                            return //terminate fx execution
                        }
                    } catch {
                        print("Error - could not serialize JSON")
                    }
                default:
                    print("Get request not successful. HTTP status code: \(httpResponse.statusCode)")
                    // tell user to connect to internet
                }
            } else {
                if let err = error as? NSError {
                    switch err.code {
                    case -1009:
                        print("[downloadJSON] No internet access was detected.")
                    case -1004:
                        print("[downloadJSON] Error - could not connect to SERVER!")
                    default:
                        print("[downloadJSON] Process failed w/ error: \(String(describing: error)).")
                    }
                }
            }
            completion(nil) //if operation fails, pass NIL back out
        }) 
        dataTask.resume() //begin task
    }
    
}
