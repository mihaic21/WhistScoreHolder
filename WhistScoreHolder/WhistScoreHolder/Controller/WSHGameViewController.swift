//
//  WSHGameViewController.swift
//  WhistScoreHolder
//
//  Created by OctavF on 15/03/16.
//  Copyright © 2016 WSHGmbH. All rights reserved.
//

import UIKit

let kScoreCellWidth: CGFloat = 56.0
let kHeaderHeight: CGFloat = 26.0
let kTableViewMinWidth: CGFloat = 164.0

class WSHGameViewController: UIViewController,
                            UITableViewDataSource, UITableViewDelegate,
                            UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,
                            WSHGameManagerDelegate,
                            WSHBeginRoundActionDelegate, WSHHandsActionViewControllerDelegate {
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var tableViewObject: UITableView!
    @IBOutlet weak var collectionViewObject: UICollectionView!
    
    @IBOutlet private weak var tableViewWidth: NSLayoutConstraint!
    
    private var rowHeight: CGFloat = 0.0
    private var collectionViewOffsetXBeforeScroll: CGFloat = 0.0
    private var actionViewController: WSHActionViewController? {
        didSet {
            if actionViewController == nil {
                actionButton.enabled = false
            } else {
                actionButton.enabled = true
            }
        }
    }
    
    private var _currentGame: WSHGame?
    private var currentGame: WSHGame! {
        get {
            if let game = _currentGame {
                return game
            } else {
                _currentGame = WSHGameManager.sharedInstance.currentGame
                
                if let game = _currentGame {
                    return game
                } else {
                    return WSHGame(players: [])
                }
            }
        }
        set {
            _currentGame = newValue
        }
    }
    
    
    //MARK: - View lifecycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewObject.tableFooterView = UIView()
        
        var userDetailsNIB = UINib(nibName: "WSHScoreCell", bundle: nil)
        collectionViewObject.registerNib(userDetailsNIB, forCellWithReuseIdentifier: "ScoreCell")
        userDetailsNIB = UINib(nibName: "WSHHeaderCell", bundle: nil)
        collectionViewObject.registerNib(userDetailsNIB, forCellWithReuseIdentifier: "HeaderCell")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        setupScoreViewsWidths(forSize: view.bounds.size);
        rowHeight = floor((view.frame.height - kHeaderHeight) / (CGFloat(self.currentGame.players.count) ?? 6.0))
        tableViewObject.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        
        let offsetPoint = collectionViewObject.contentOffset
        
        collectionViewObject.contentSize = CGSizeMake(kScoreCellWidth * CGFloat(currentGame.rounds.count), view.frame.height)
        collectionViewObject.contentOffset = offsetPoint
        
        collectionViewObject.reloadData()
        collectionViewObject.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tableViewObject.reloadData()
        collectionViewObject.reloadData()
    }
    
    
    //MARK: - Private
    
    
    private func setupScoreViewsWidths(forSize size: CGSize) {
        let numberOfVisibleCells = Int((size.width - kTableViewMinWidth) / kScoreCellWidth) + 1
        
        let scoreCellsWidth = kScoreCellWidth * CGFloat(numberOfVisibleCells)
        tableViewWidth.constant = size.width - scoreCellsWidth
        
        view.setNeedsLayout()
    }
    
    private func realignCollectionView() {
        if collectionViewObject.contentOffset.x > 0 && collectionViewObject.contentOffset.x <= collectionViewObject.contentSize.width {
            let partOfCell = collectionViewObject.contentOffset.x % kScoreCellWidth
            
            if partOfCell != 0 {
                var newScrollOffsetX: CGFloat;
                
                if partOfCell < kScoreCellWidth * 0.2 {
                    newScrollOffsetX = collectionViewObject.contentOffset.x - partOfCell
                    
                } else if partOfCell > kScoreCellWidth * 0.8 {
                    newScrollOffsetX = collectionViewObject.contentOffset.x + (kScoreCellWidth - partOfCell)
                    
                } else {
                    if collectionViewOffsetXBeforeScroll > collectionViewObject.contentOffset.x {
                        newScrollOffsetX = collectionViewObject.contentOffset.x - partOfCell
                        
                    } else {
                        newScrollOffsetX = collectionViewObject.contentOffset.x + (kScoreCellWidth - partOfCell)
                    }
                }
                collectionViewObject.setContentOffset(CGPointMake(newScrollOffsetX, collectionViewObject.contentOffset.y), animated: true)
            }
        }
    }
    
    private func presentActionViewController() {
        let nav = UINavigationController(rootViewController: actionViewController!)
        
        presentViewController(nav, animated: true, completion: nil)
    }
    
    private func resignActionViewController() {
        actionViewController?.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        actionViewController = nil
    }
    
    private func setupBeginRoundActionViewController(round roundType: WSHRoundType, fromPlayer player: WSHPlayer, score: Int) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let beginRoundVC = mainStoryboard.instantiateViewControllerWithIdentifier("WSHBeginRoundActionViewController") as! WSHBeginRoundActionViewController
        beginRoundVC.player = player
        beginRoundVC.round = roundType
        beginRoundVC.playerScore = score
        beginRoundVC.delegate = self
        
        actionViewController = beginRoundVC
    }
    
    private func scrollToCurrentRound() {
        var collectionViewOffsetX: CGFloat = 0.0;
        
        if let round = currentGame.currentRound {
            let noScoreCellsAtOnce = Int(collectionViewObject.frame.width / kScoreCellWidth);
            let indexOfCurrentRound = currentGame.rounds.indexOf(round)!
            
            let x = CGFloat(indexOfCurrentRound - (noScoreCellsAtOnce - 1/*the current round*/)) * kScoreCellWidth
            
            collectionViewOffsetX = min(max(x, 0), collectionViewObject.contentSize.width - collectionViewObject.frame.width);
        }
        collectionViewObject.setContentOffset(CGPointMake(collectionViewOffsetX, collectionViewObject.contentOffset.y), animated: true)
    }
    
    
    //MARK: - WSHGameManagerDelegate functions
    
    
    func gameManager(gameManager: WSHGameManager, didStartGame game: WSHGame) {
        
    }
  
    func willBeginRoundOfType(type: WSHRoundType, startingPlayer player: WSHPlayer) {
        setupBeginRoundActionViewController(round: type, fromPlayer: player, score: currentGame.totalPlayerScores[player] ?? 0)
        presentActionViewController()
        
        if let _ = self.collectionViewObject {
            self.scrollToCurrentRound()
        }
    }
    
    func playerTurnToBet(player: WSHPlayer, forRoundType roundType: WSHRoundType, excluding choice: WSHGameBetChoice?) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let bettingActionViewController = mainStoryboard.instantiateViewControllerWithIdentifier("WSHBettingActionViewController") as! WSHBettingActionViewController
        bettingActionViewController.playerImage = player.image
        bettingActionViewController.playerName = player.name
        bettingActionViewController.playerOptions = self.bettingChoiceButtonsForRoundType(roundType, excludingChoice: choice)
        
        self.actionViewController = bettingActionViewController
        self.presentActionViewController()
    }
    
    func didFinishBettingInRound(round: WSHRound) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let handsActionViewController = mainStoryboard.instantiateViewControllerWithIdentifier("WSHHandsActionViewController") as! WSHHandsActionViewController
        handsActionViewController.players = self.currentGame.players
        
        var bets: [WSHPlayer : Int] = [:]
        for (key, val) in self.currentGame.currentRound?.roundInformation ?? [:] {
            bets[key] = val.bet.intValue
        }
        handsActionViewController.bets = bets
        handsActionViewController.delegate = self
        
        self.actionViewController = handsActionViewController
        self.presentActionViewController()
    }
    
    func roundDidFinish(round: WSHRound, withBonuses bonuses: [WSHPlayer : Int]) {
        self.resignActionViewController()
        
        if bonuses.count > 0 {
            // show alert for bonuses
        }
        
        //after bonuses are shown
        WSHGameManager.sharedInstance.startNextRound()
    }

    func gameManager(gameManager: WSHGameManager, didEndGame game: WSHGame) {
        currentGame = game
    }
    
    
    //MARK: - WSHBeginRoundActionDelegate functions
    
    
    func beginRoundFromActionController(actionViewController: WSHBeginRoundActionViewController) {
        resignActionViewController()
        WSHGameManager.sharedInstance.startBetting()
    }
    
    
    //MARK: - ScrollViewDelegate functions
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y != 0 {
            
            if collectionViewObject == scrollView {
                tableViewObject.delegate = nil;
                tableViewObject.contentOffset = CGPointMake(tableViewObject.contentOffset.x, scrollView.contentOffset.y)
                tableViewObject.delegate = self;
                
            } else {
                collectionViewObject.delegate = nil;
                collectionViewObject.contentOffset = CGPointMake(collectionViewObject.contentOffset.x, scrollView.contentOffset.y)
                collectionViewObject.delegate = self;
            }
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if scrollView == collectionViewObject {
            collectionViewOffsetXBeforeScroll = scrollView.contentOffset.x
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if scrollView == collectionViewObject {
            realignCollectionView()
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == collectionViewObject {
            if !decelerate {
                realignCollectionView()
            }
        }
    }
    
    
    //MARK: - TableViewDelegate functions
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentGame.players.count ?? 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return kHeaderHeight
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textAlignment = .Center
        label.text = "Player \\ Round"
        label.backgroundColor = UIColor.lightTextColor()
        
        return label
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PlayerCell")
        
        let currentPlayer: WSHPlayer = currentGame.players[indexPath.row]
        
        cell?.textLabel?.adjustsFontSizeToFitWidth = true
        cell?.textLabel?.text = currentPlayer.name.substringToIndex(currentPlayer.name.startIndex.advancedBy(min(currentPlayer.name.characters.count, 4)))
        cell?.detailTextLabel?.text = "\(currentGame.totalPlayerScores[currentPlayer]!)"
        let cellSize = min(rowHeight * 3.0/4.0, kScoreCellWidth)
        
        cell?.imageView?.image = currentPlayer.image?.scale(toSize: CGSizeMake(cellSize, cellSize))
        cell?.backgroundColor = UIColor.clearColor()
        
        return cell!
    }
    
    
    //MARK: - Collection view delegates
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return currentGame.totalNumberOfRounds ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (currentGame.players.count ?? 0) + 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        let round: WSHRound? = currentGame.rounds[indexPath.section]
        
        if indexPath.row == 0 {
            let headerCell: WSHHeaderCell = (collectionView.dequeueReusableCellWithReuseIdentifier("HeaderCell", forIndexPath: indexPath) as! WSHHeaderCell)
            
            headerCell.mainLabel.text = "\((round?.roundType.intValue)!)"
            headerCell.backgroundColor = UIColor.lightGrayColor()
            
            cell = headerCell
            
        } else {
            let scoreCell: WSHScoreCell = (collectionView.dequeueReusableCellWithReuseIdentifier("ScoreCell", forIndexPath: indexPath) as! WSHScoreCell)
            scoreCell.backgroundColor = UIColor.whiteColor()
            
            var scoreString = "?"
            var betString = "?"
            var handString = "?"
            
            let indexRound: WSHRound = currentGame.rounds[indexPath.section]
            let currentPlayer: WSHPlayer = currentGame.players[indexPath.row - 1]
            
            if let currentRound = currentGame.currentRound {
                let indexOfCurrentRound = currentGame.rounds.indexOf(currentRound)
                let indexOfIndexRound = currentGame.rounds.indexOf(indexRound)
                
                if indexOfCurrentRound > indexOfIndexRound || (indexRound == currentGame.currentRound && indexRound.isRoundComplete) {
                    scoreString = "\(indexRound.playerScores[currentPlayer]!)"
                }
                
                if indexOfCurrentRound >= indexOfIndexRound {
                    if let (bet, hand) = indexRound.roundInformation[currentPlayer] {
                        betString = "\(bet.intValue)"
                        handString = "\(hand.intValue)"
                        
                        if currentRound == round {
                            scoreCell.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.05)
                            
                        } else if bet.intValue == hand.intValue {
                            scoreCell.backgroundColor = UIColor.greenColor().colorWithAlphaComponent(0.05)
                            
                        } else {
                            scoreCell.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.05)
                        }
                    }
                }
            } else {
                if let (bet, hand) = indexRound.roundInformation[currentPlayer] {
                    betString = "\(bet.intValue)"
                    handString = "\(hand.intValue)"
                    
                    if bet.intValue == hand.intValue {
                        scoreCell.backgroundColor = UIColor.greenColor().colorWithAlphaComponent(0.05)
                    } else {
                        scoreCell.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.05)
                    }
                }
                scoreString = "\(indexRound.playerScores[currentPlayer]!)"
            }
            if let bonus = self.currentGame.playerBonusesPerRound[round!]?[currentPlayer] {
                if bonus < 0 {
                    scoreCell.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.2)
                } else {
                    scoreCell.backgroundColor = UIColor.greenColor().colorWithAlphaComponent(0.2)
                }
            }
            
            scoreCell.mainLabel.text = scoreString
            scoreCell.guessLabel.text = betString
            scoreCell.realityLabel.text = handString
            
            cell = scoreCell
        }
        
        return cell!
    }
    
    
    //MARK: - Collection view layout
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.row == 0 {
            return CGSizeMake(kScoreCellWidth, kHeaderHeight)
        }
        return CGSizeMake(kScoreCellWidth, rowHeight)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0.0;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0.0
    }
    
    
    //MARK: - WSHHandsActionViewControllerDelegate functions
    
    
    func handsActionControllerPlayerDidTakeHand(controller: WSHHandsActionViewController, player: WSHPlayer) -> Int {
        do {
            try WSHGameManager.sharedInstance.playerDidTakeHand(player)
        } catch let error {
            presentError(error, fromController: self.navigationController!)
        }
        return currentGame.currentRound?.roundInformation[player]?.hands.intValue ?? 0
    }
    
    
    // MARK: - Actions
    
    
    @IBAction func closeButtonTapped(sender: AnyObject) {
        let alertController = UIAlertController(title: "Game will end", message:
            "Game will be aborted", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { action in
            WSHGameManager.sharedInstance.resetAllData()
            self.navigationController?.popViewControllerAnimated(true)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil))
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func actionButtonTapped(sender: AnyObject) {
        self.presentActionViewController()
    }
    
    func betChoiceButtonPressed(button: UIButton) {
        self.resignActionViewController()
        
        if let player = WSHGameManager.sharedInstance.currentGame?.currentRound?.currentBettingPlayer {
            do {
                try WSHGameManager.sharedInstance.player(player, didBet: WSHGameBetChoice(rawValue: button.tag)!)
            } catch let error {
                print("Error found \(error)")
            }
        }
    }
    
    @IBAction func focusButtonPressed(sender: UIButton) {
        self.scrollToCurrentRound()
    }
    
    
    // MARK: - Buttons factory
    
    
    private func bettingChoiceButtonsForRoundType(roundType: WSHRoundType, excludingChoice choice: WSHGameBetChoice?) -> [UIButton] {
        var buttons: [UIButton] = []
        
        for betChoice in 0...roundType.intValue {
            let button = self.configuredStandardChoiceButton()
            button.setTitle("\(betChoice)", forState: .Normal)
            button.tag = betChoice
            button.addTarget(self, action: #selector(WSHGameViewController.betChoiceButtonPressed(_:)), forControlEvents: .TouchUpInside)
            
            if let excluded = choice {
                if betChoice == excluded.intValue {
                    button.enabled = false
                    button.alpha = 0.5
                }
            }
            
            buttons.append(button)
        }
        
        return buttons
    }
    
    private func configuredStandardChoiceButton() -> UIButton {
        let button = UIButton(type: .System)
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor(red: 127.5 / 255, green: 127.5 / 255, blue: 127.5 / 255, alpha: 0.5)
        button.titleLabel?.font = UIFont.systemFontOfSize(100)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        button.setTitleColor(UIColor.blackColor().colorWithAlphaComponent(0.85), forState: .Normal)
        
        return button
    }
}
