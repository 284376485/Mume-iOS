//
//  TodayViewController.swift
//  TodayWidget
//
//  Created by LEI on 4/12/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import UIKit
import NotificationCenter
import PotatsoBase
import Cartography
import SwiftColor
import PotatsoLibrary
import MMWormhole
import CocoaAsyncSocket

private let kCurrentGroupCellIndentifier = "kCurrentGroupIndentifier"

class TodayViewController: UIViewController, NCWidgetProviding, GCDAsyncSocketDelegate {
    
    let constrainGroup = ConstraintGroup()
    
    let wormhole = Manager.sharedManager.wormhole
    
    var timer: NSTimer?
    
    var rowCount: Int {
        return 1
    }
    
    var status: Bool = false

    var socket: GCDAsyncSocket!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let port = Potatso.sharedUserDefaults().integerForKey("tunnelStatusPort")
        status = port > 0
        
        view.addSubview(tableView)
        updateLayout()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        startTimer()
        self.reload()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }

    func tryConnectStatusSocket() {
        let port = Potatso.sharedUserDefaults().integerForKey("tunnelStatusPort")
        guard port > 0 else {
            updateStatus(false)
            return
        }
        do {
            socket.delegate = self
            try socket.connectToHost("127.0.0.1", onPort: UInt16(port))
        }catch {
            updateStatus(false)
        }
    }

    func startTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(TodayViewController.tryConnectStatusSocket), userInfo: nil, repeats: true)
        timer?.fire()
    }

    func stopTimer() {
        socket.disconnect()
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Socket

    func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        updateStatus(true)
        sock.delegate = nil
        sock.disconnect()
    }

    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        updateStatus(false)
    }

    func updateStatus(current: Bool) {
        if status != current {
            status = current
            dispatch_async(dispatch_get_main_queue(), { 
                self.reload()
            })
        }
    }
    
    func switchVPN() {
        if status {
            wormhole.passMessageObject("", identifier: "stopTunnel")
        } else {
            let url = NSURL(string: "mume://on")
            self.extensionContext?.openURL(url!, completionHandler:nil)
//TODO: try on-demand first
//            let url = NSURL(string: "https://on-demand.connect.mume.vpn/start/")
//            let task = NSURLSession.sharedSession().dataTaskWithURL(url) {data, reponse, error in
//                if (error) {
//                    
//                }
//            }
//            task.resume()
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        var inset = defaultMarginInsets
        inset.bottom = inset.top
        return inset
    }

    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.NewData)
    }
    
    func updateLayout() {
        constrain(tableView, view, replace: constrainGroup) { tableView, superView in
            tableView.leading == superView.leading
            tableView.top == superView.top
            tableView.trailing == superView.trailing
            tableView.bottom == superView.bottom
            tableView.height == CGFloat(60 * rowCount)
        }
    }
    
    lazy var tableView: CurrentGroupCell = {
        let v = CurrentGroupCell(frame: CGRectZero)
        return v
    }()
    
    func reload() {
        let name = Potatso.sharedUserDefaults().objectForKey(kDefaultGroupName) as? String
        tableView.config(name ?? "Default".localized(), status: status, switchVPN: switchVPN)
    }
    
}
