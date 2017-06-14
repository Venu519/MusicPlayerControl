//
//  CacheManager.swift
//  MusicPlayerControl
//
//  Created by Venugopal Reddy Devarapally on 14/06/17.
//  Copyright © 2017 venu. All rights reserved.
//

import Foundation
let CACHE_MANAGER_NAME = "cachemanager"
class CacheManager: NSObject {
    let sharedInstance: CacheManager = CacheManager()
//    {
//        struct Static {
//            static var instance: CacheManager?
//            static var token: dispatch_once_t = 0
//        }
//        dispatch_once(&Static.token) {
//            //we try to load an existing CacheManager, otherwise we create a new one
//            if let filepath = CacheManager.pathInDocDirectory(CACHE_MANAGER_NAME) {
//                if let mgr = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath) as? CacheManager{
//                    Static.instance = mgr
//                }
//            }
//            if (Static.instance == nil) {
//                Static.instance = CacheManager()
//            }
//        }
//        return Static.instance!
//    }
    
    //the current highest object id
    private var objectMaxId: Int = 0
    //this dictionnary stores the unique filename that is attached to the object identifier
    private var filenameFromIdDico: [String : String] = [:]
    
    //this init method is used when no CacheManager is found on the phone
    override init(){
        super.init()
    }
    
    //decode method for our CacheManager
    required init?(coder aDecoder: NSCoder) {
        self.objectMaxId = aDecoder.decodeInteger(forKey: "objectMaxId")
        if let dico:[String:String] = aDecoder.decodeObject(forKey: "filenameFromUrlDic") as? [String:String] {
            self.filenameFromIdDico = dico
        }
        super.init()
    }
    
    //saving method for our CacheManager
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encode(self.objectMaxId, forKey: "objectMaxId")
        aCoder.encode(self.filenameFromIdDico, forKey: "filenameFromUrlDic")
    }
    
    class func pathInDocDirectory(filename: String)->String? {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if paths.count > 0 {
            if let path: String = paths[0] as String {
                return path + "/" + filename
            }
        }
        return nil
    }
    
    private func saveToDevice() {
        if let path = CacheManager.pathInDocDirectory(filename: CACHE_MANAGER_NAME) {
            NSKeyedArchiver.archiveRootObject(self, toFile: path)
        }
    }
    
    func saveObject(object:AnyObject, identifier:String) -> Bool {
        if (identifier.isEmpty) {
            return false
        }
        
        //we sync on the object to be sure that only thread at a time generates a new objectId
        objc_sync_enter(self)
        var filename: String
        //we check to see if the CacheManager has a caches object for this identifier
        if let filenameFromDico: String = self.filenameFromIdDico[identifier] {
            filename = filenameFromDico
        }
        else {
            self.objectMaxId += 1
            filename = "object." + String(self.objectMaxId)
            self.filenameFromIdDico[identifier] = filename
        }
        objc_sync_exit(self)
        
        var status: Bool = false
        //we generate the full path for the object every time instead of caching it because the path contains a unique identifier that changes with each build, so we mustn't cache it
        if let filepath: String = CacheManager.pathInDocDirectory(filename: filename) {
            NSKeyedArchiver.archiveRootObject(object, toFile: filepath)
            status = true
        }
        self.saveToDevice()
        return status;
    }
    
    func loadObject(identifier:String) -> AnyObject? {
        if let filename: String = self.filenameFromIdDico[identifier] {
            if let filepath = CacheManager.pathInDocDirectory(filename: filename) {
                return NSKeyedUnarchiver.unarchiveObject(withFile: filepath)
            }
        }
        return nil
    }
}
