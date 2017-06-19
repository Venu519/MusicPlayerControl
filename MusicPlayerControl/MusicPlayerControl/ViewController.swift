//
//  ViewController.swift
//  MusicPlayerControl
//
//  Created by Venugopal Reddy Devarapally on 14/06/17.
//  Copyright © 2017 venu. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var refreshControl: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!
    var tableViewDataSource = [Album]()
    var collectionViewDataSource = [Album]()
    let searchController = UISearchController(searchResultsController: nil)
    var filteredTableViewDataSource = [Album]()
    fileprivate var currentPage: Int = 0
    
    fileprivate var pageSize: CGSize {
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        var pageSize = layout.itemSize
        if layout.scrollDirection == .horizontal {
            pageSize.width += layout.minimumLineSpacing
        } else {
            pageSize.height += layout.minimumLineSpacing
        }
        return pageSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = []

        // Delgates
        tableView.dataSource = self
        tableView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        
        //Network Call
        getAlbumList()
        
        //CoreDataCall
        fetchDataForFavorites(isFavorites:true)
        fetchDataForFavorites(isFavorites:false)
        
        // CollectionView Layout
        setupCollectionViewLayout()
        
        //Search
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }
    
    fileprivate func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
//        layout.sideItemScale = 0.6
        layout.itemSize = CGSize(width: 300, height: 200)
        collectionView.collectionViewLayout = layout
//        layout.spacingMode = UPCarouselFlowLayoutSpacingMode.overlap(visibleOffset: 30)
        layout.scrollDirection = .horizontal
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Fetch Data Methods
    func getAlbumList(){
        self.refreshControl?.startAnimating()
        let _ = taskForGetAlbumList { (response, error) in
            func sendError(_ error: String) {
                performUIUpdatesOnMain {
                    let alert = UIAlertController(title: "Oops!!", message: error, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion:nil)
                    self.refreshControl?.stopAnimating()
                }
            }
            guard error == nil else {
                sendError("No Network. Please try after sometime.")
                return
            }
            let albumArray = response as! Array<AnyObject>
            for album in albumArray {
                self.save(album: album as! Dictionary<String, Any>)
            }
            performUIUpdatesOnMain {
                self.refreshControl?.stopAnimating()
                self.fetchDataForFavorites(isFavorites:true)
                self.fetchDataForFavorites(isFavorites:false)
            }
        }
    }
    
    func fetchDataForFavorites(isFavorites: Bool){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<Album> = Album.fetchRequest()
        if isFavorites {
            let predicate = NSPredicate(format: "isFavorite == %@", NSNumber.init(value: isFavorites))
            fetchRequest.predicate = predicate
        }
        do {
            let fetchResults = try managedContext.fetch(fetchRequest)
            if fetchResults.count > 0 {
                if isFavorites {
                    self.collectionViewDataSource.removeAll()
                    for item in fetchResults {
                        collectionViewDataSource.append(item)
                    }
                    reloadCollectionView()
                }else{
                    self.tableViewDataSource.removeAll()
                    for item in fetchResults {
                        tableViewDataSource.append(item)
                    }
                    tableView.reloadData()
                }
            }
        }
        catch{
            fatalError("Failed to fetch employees: \(error)")
        }
    }
    
    func save(album: Dictionary<String, Any>) {
        let entityName = "Album"
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let albumId = album["id"] as! String
        
        let fetchRequest:NSFetchRequest<Album> = Album.fetchRequest()
        let predicate = NSPredicate(format: "albumId == %@", albumId)
        fetchRequest.predicate = predicate
        
        do {
            let fetchResults = try managedContext.fetch(fetchRequest)
            if fetchResults.count > 0 {
//                tableViewDataSource.append(fetchResults.first!)
            }else{
                print("None")
                let entity = NSEntityDescription.entity(forEntityName: entityName,
                                                        in: managedContext)!
                
                let albumObj = NSManagedObject(entity: entity,
                                              insertInto: managedContext) as! Album
                
                albumObj.artist = (album["artist"] as? Dictionary<String,Any>!)?["name"] as? String
//                albumObj.authorAvatar = (album["author"] as? Dictionary<String,Any>!)?["avatar"] as? String
                albumObj.albumTitle =  album["songTitle"] as? String
//                albumObj.bookdesc = album["description"] as? String
                albumObj.cover = album["cover"] as? String
                albumObj.albumId = album["id"] as? String
//                albumObj.genre = (album["genre"] as? Dictionary<String,Any>!)?["name"] as? String
//                albumObj.likes = album["likes"] as! Int64
//                albumObj.isFavorite = false
//                albumObj.excerpt = ((album["introduction"] as! Array<Dictionary<String,Any>>).first)?["content"] as? String
                
//                let formatter = DateFormatter()
//                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
//                bookObj.publishDate = formatter.date(from: album["published"] as! String) as NSDate?
                do {
                    try managedContext.save()
//                    tableViewDataSource.append(albumObj)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }
    
    func save(isFavorite: Bool, album:Album, indexPath: IndexPath) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<Album> = Album.fetchRequest()
        let predicate = NSPredicate(format: "albumId == %@", album.albumId!)
        fetchRequest.predicate = predicate
        do {
            let fetchResults = try managedContext.fetch(fetchRequest)
            if fetchResults.count > 0 {
                let albumObj = fetchResults.first
                albumObj?.isFavorite = isFavorite
                do {
                    try managedContext.save()
                    updateCellAtIndexPathForTableView(indexPath: indexPath)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
        catch{
            fatalError("Failed to fetch employees: \(error)")
        }
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredTableViewDataSource = tableViewDataSource.filter { album in
            return (album.albumTitle?.lowercased().contains(searchText.lowercased()))! || (album.artist?.lowercased().contains(searchText.lowercased()))!
        }
        tableView.reloadData()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredTableViewDataSource.count
        }
        return tableViewDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        //        let album = tableViewDataSource[(indexPath as NSIndexPath).row]
        let album: Album
        if searchController.isActive && searchController.searchBar.text != "" {
            album = filteredTableViewDataSource[indexPath.row]
        } else {
            album = tableViewDataSource[indexPath.row]
        }
        cell.title.text = album.albumTitle
        cell.subTitle.text = album.artist
        cell.cellImageView.image = UIImage(named: "placeHolder")
        if album.isFavorite {
            cell.favBtn.setImage(UIImage.init(named: "favoritesSelected"), for: .normal)
        }else{
            cell.favBtn.setImage(UIImage.init(named: "favorites"), for: .normal)
        }
        //Download Album Cover
        let albumCoverUrl = album.cover!
        imageFromServerURL(urlString: albumCoverUrl, completion: { (image, error) in
            if error != nil {
                print(error)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                cell.cellImageView.image = image
            })
        })
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let album = tableViewDataSource[(indexPath as NSIndexPath).row]
        save(isFavorite: !album.isFavorite, album: album, indexPath: indexPath)
    }
    
    func updateCellAtIndexPathForTableView(indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath) as! TableViewCell
        let album = tableViewDataSource[(indexPath as NSIndexPath).row]
        
        if album.isFavorite {
            cell.favBtn.setImage(UIImage.init(named: "favoritesSelected"), for: .normal)
            collectionViewDataSource.append(album)
        }else{
            cell.favBtn.setImage(UIImage.init(named: "favorites"), for: .normal)
            if(collectionViewDataSource.contains(album)){
                collectionViewDataSource.remove(at: collectionViewDataSource.index(of: album)!)
            }
        }
        reloadCollectionView()
        if collectionViewDataSource.count > 0{
            let index = IndexPath(item: (collectionViewDataSource.count - 1), section: 0)
            self.collectionView?.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
        }
    }
    
    func ScrollToTableViewCellAtObject(album: Album){
        var index: Int = 0
        if searchController.isActive && searchController.searchBar.text != "" {
            if filteredTableViewDataSource.contains(album){
                index = filteredTableViewDataSource.index(of: album)!
                let indexPath = IndexPath(item: index, section: 0)
                tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
        else {
            if tableViewDataSource.contains(album){
                index = tableViewDataSource.index(of: album)!
                let indexPath = IndexPath(item: index, section: 0)
                tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionViewDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.identifier, for: indexPath) as! CollectionViewCell
        let album = collectionViewDataSource[(indexPath as NSIndexPath).row]
        cell.imageView.image = UIImage(named: "placeHolder")
        cell.songTitle.text = album.albumTitle
        //Download Image
        let albumUrl = album.cover!
        imageFromServerURL(urlString: albumUrl, completion: { (image, error) in
            if error != nil {
                print(error)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                cell.imageView.image = image
            })
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = collectionViewDataSource[(indexPath as NSIndexPath).row]
        ScrollToTableViewCellAtObject(album: album)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.isKind(of: UICollectionView.self){
            let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            let pageSide = (layout.scrollDirection == .horizontal) ? self.pageSize.width : self.pageSize.height
            let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
            currentPage = Int(floor((offset - pageSide / 2) / pageSide) + 1)
            ScrollToTableViewCellAtObject(album: collectionViewDataSource[currentPage])
        }
    }
    
    func reloadCollectionView(){
        collectionView.reloadData()
        if collectionViewDataSource.count > 0 {
            collectionHeightConstraint.constant = 221.0
        }else{
            collectionHeightConstraint.constant = 0.0
        }
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

