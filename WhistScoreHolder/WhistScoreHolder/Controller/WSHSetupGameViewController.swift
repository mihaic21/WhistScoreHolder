//
//  WSHSetupGameViewController.swift
//  WhistScoreHolder
//
//  Created by OctavF on 29/02/16.
//  Copyright © 2016 WSHGmbH. All rights reserved.
//

import UIKit

class WSHSetupGameViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WSHPlayerViewControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var playBarButtonItem: UIBarButtonItem!
    
    var players: [WSHPlayer] = []
    var currentPlayer: WSHPlayer?
    
    var rowHeight : CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playBarButtonItem.enabled = false
        tableView.editing = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        currentPlayer = nil
        rowHeight = min(tableView.frame.height / 6.0, 80.0)
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        rowHeight = min(size.height / 6.0, 80.0)
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    // MARK: - Private functions
    
    
    private func refreshButtons() {
        if players.count < kMIN_NUMBER_OF_PLAYERS {
            playBarButtonItem.enabled = false
        } else {
            playBarButtonItem.enabled = true
        }
        if players.count >= kMAX_NUMBER_OF_PLAYERS {
            addBarButtonItem.enabled = false
        } else {
            addBarButtonItem.enabled = true
        }
    }
    
    private func reloadTableView() {
        refreshButtons()
        
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    
    // MARK: - UITableView DataSource & Delegate
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.players.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PlayerCell", forIndexPath: indexPath)
        
        let player = players[indexPath.row]
        cell.textLabel?.text = player.name
        cell.imageView?.image = player.image?.scale(toSize: CGSizeMake(rowHeight - 8.0, rowHeight - 8.0))
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            players.removeAtIndex(indexPath.row)
            refreshButtons()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            break
        default:
            break
        }
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let itemToMove = self.players[sourceIndexPath.row]
        players.removeAtIndex(sourceIndexPath.row)
        players.insert(itemToMove , atIndex: destinationIndexPath.row)
    }
    
    
    // MARK: - WSHPlayerViewControllerDelegate functions
    
    
    func didAddPlayer(sender: WSHPlayerViewController, player: WSHPlayer) -> Int {
        players.append(player)
        reloadTableView()
        
        return players.count ?? 0
    }
    
    func didEditPlayer(sender: WSHPlayerViewController, player: WSHPlayer) {
        currentPlayer?.name = player.name
        currentPlayer?.image = player.image
        
        reloadTableView()
    }
    
    
    // MARK: - Actions
    
    
    @IBAction func playButtonTapped(sender: AnyObject) {
        let alertController: UIAlertController
        
        alertController = UIAlertController(title: "Get ready", message:
            "Game will start", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { action in
            // TODO: (foc) Start the game already
            // TODO: (foc) Dismiss alert after time has passed
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil))
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "cellTapped" {
            currentPlayer = players[(tableView.indexPathForCell(sender as! UITableViewCell)?.row)!]
        }
        let navigationController: UINavigationController = segue.destinationViewController as! UINavigationController
        let playerViewController: WSHPlayerViewController = navigationController.viewControllers.first as! WSHPlayerViewController
        
        playerViewController.delegate = self
        playerViewController.editPlayer = currentPlayer
    }
}
