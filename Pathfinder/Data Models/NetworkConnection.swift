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
    
    // MARK: - Initializers
    
    init(url: URL) { //GET request - initialize w/ the URL to which the network request is being sent
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
                if let e = error {
                    switch (e as NSError).code {
                    case -1009:
                        print("[downloadJSON] No internet access was detected.")
                    case -1004:
                        print("[downloadJSON] Error - could not connect to SERVER!")
                    default:
                        print("[downloadJSON] Process failed w/ error: \(e.localizedDescription)).")
                    }
                }
            }
            completion(nil) //if operation fails, pass NIL back out
        }) 
        dataTask.resume() //begin task
    }
    
}
