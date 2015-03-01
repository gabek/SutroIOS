//
//  SecondViewController.swift
//  RdioParty
//
//  Created by Gabe Kangas on 2/19/15.
//  Copyright (c) 2015 Rdio. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, RdioDelegate {

    var room :Room = Session.sharedInstance.room
    var queue = Queue()
    var backgroundImage = UIImageView()
    
    var rdio = Rdio(consumerKey: "mqbnqec7reb8x6zv5sbs5bq4", andSecret: "NTu8GRBzr5", delegate: nil)

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.rdio.delegate = self
        
        self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0)
        self.tableView.backgroundColor = UIColor.clearColor()
        
        self.backgroundImage.frame = self.view.frame
        self.view.insertSubview(self.backgroundImage, belowSubview: self.tableView)
        updateBackground()
        
        load()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func load() {
        
        var ref = Firebase(url:"https://rdioparty.firebaseio.com/\(self.room.name)/queue")

        // Track added
        ref.observeEventType(.ChildAdded, withBlock: { snapshot in
            if (snapshot.key != nil) {
                var song = Song(fromSnapshot: snapshot)
                self.updateSongWithDetails(song)
                self.tableView.reloadData()
            }
        })
        
        // Track removed
        ref.observeEventType(.ChildRemoved, withBlock: { snapshot in
            let trackKey = snapshot.value.valueForKey("trackKey") as! String
            self.queue.removeSongById(trackKey)
        })
        
        // Queue changed
        ref.observeEventType(.ChildRemoved, withBlock: { snapshot in
            self.queue.sort()
            self.tableView.reloadData()
        })
    }
    
    func updateBackground() {
        var backgroundUrl = "http://rdiodynimages0-a.akamaihd.net/?l=a185706-0%3Bprimary%280.5%29%3B%240%3Azoom%2830%25%29%3Bboxblur%285%25%2C%205%25%29%3Bcolorize%28rgba%280%2C%200%2C%200%2C%200.2%29%29%3Boverlay%28%241%29"
        UIView.transitionWithView(self.backgroundImage, duration: 2.0, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.backgroundImage.sd_setImageWithURL(NSURL(string: backgroundUrl))
        }, completion: nil)
    }
    
    // MARK: - Track Details
    func updateSongWithDetails(song: Song) {
        var parameters:Dictionary<NSObject, AnyObject!> = ["keys": song.trackKey, "extras": "-*,name,artist,dominantColor,duration,bigIcon,icon,playerBackgroundUrl"]

        self.rdio.callAPIMethod("get",
            withParameters: parameters,
            success: { (result) -> Void in
                // Result
                let track: AnyObject? = result[song.trackKey]

                song.icon = track!["icon"] as! String!
                song.bigIcon = track!["bigIcon"] as! String!
                song.artistName = track!["artist"] as! String!
                song.trackName = track!["name"] as! String!
                song.backgroundImage = track!["playerBackgroundUrl"] as! String

                self.queue.add(song)
                self.tableView.reloadData()
                
            }) { (error) -> Void in
                // Error
                
        }
    }
    
    // MARK: - Table View
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.queue.count()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let song = self.queue.songAtIndex(indexPath.row)
        var cell = tableView.dequeueReusableCellWithIdentifier("QueueItemCell") as! QueueItemCellTableViewCell
        cell.upVoteLabel.text = String(song.upVoteKeys.count)
        cell.downVoteLabel.text = String(song.downVoteKeys.count)
        cell.trackArtist.text = song.artistName
        cell.trackName.text = song.trackName
        cell.trackImage.sd_setImageWithURL(NSURL(string: song.icon))
        cell.backgroundColor = UIColor.clearColor()
        cell.contentView.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
        return cell
    }


}
