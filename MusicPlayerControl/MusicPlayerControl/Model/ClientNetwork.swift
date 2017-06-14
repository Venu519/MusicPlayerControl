//
//  File.swift
//  MusicPlayerControl
//
//  Created by Venugopal Reddy Devarapally on 14/06/17.
//  Copyright © 2017 venu. All rights reserved.
//

import Foundation
import UIKit

func taskForGetAlbumList(completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
    var urlStr = "https://gist.githubusercontent.com/Venu519/381244828ab8a1b7e63a37433c1da103/raw/59317ca02a7a372c74e025c388b00692ac48b427/albums.json"
    
    let url = URL(string: urlStr)
    let request = URLRequest(url: url!)
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        func sendError(_ error: String) {
            print(error)
            let userInfo = [NSLocalizedDescriptionKey : error]
            completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
        }
        
        /* GUARD: Was there an error? */
        guard (error == nil) else {
            sendError("There was an error with your request: \(error)")
            return
        }
        
        /* GUARD: Did we get a successful 2XX response? */
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
            sendError("Your request returned a status code other than 2xx!")
            return
        }
        
        /* GUARD: Was there any data returned? */
        guard let data = data else {
            sendError("No data was returned by the request!")
            return
        }
        
        convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
    }
    
    task.resume()
    
    return task
}

func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
    
    var parsedResult: AnyObject! = nil
    do {
        parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
    } catch {
        let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
        completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
    }
    
    completionHandlerForConvertData(parsedResult, nil)
}

func imageFromServerURL(urlString: String, completion:@escaping (_ result: UIImage?, _ error: NSError?) -> Void) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        return
    }
    if let image = appDelegate.appCache?.object(forKey: urlString as AnyObject){
        completion(image as? UIImage, nil)
    } else {
        URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                completion(UIImage(named: "placeHolder")!, error as NSError?)
                return
            }
            if data != nil, let image = UIImage(data: data!){
                appDelegate.appCache?.setObject(image, forKey: urlString as AnyObject)
                completion(image, nil)
            }else{
                completion(UIImage(named: "placeHolder")!, error as NSError?)
            }
        }).resume()
    }
}
