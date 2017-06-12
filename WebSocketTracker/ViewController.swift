//
//  ViewController.swift
//  WebSocketTracker
//
//  Created by Douglas Barbosa on 27/05/17.
//  Copyright © 2017 Douglas Barbosa. All rights reserved.
//

import UIKit
import CoreLocation
import SocketIO

class ViewController: UIViewController {
    
    // MARK: - IBOutlets

    @IBOutlet weak var shareLocationLabel: UILabel!
    @IBOutlet weak var shareLocationSwitch: UISwitch!
    @IBOutlet weak var nicknameTextField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    var locationManager = CLLocationManager()
    
    var nickname = "" {
        didSet {
            shareLocationSwitch.isEnabled = !nickname.isEmpty
        }
    }
    
    var trackedUsers: [[String:AnyObject]] = []
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInitialValues()
        setupLocationManager()
        listenToEvents()
    }
    
    // MARK: - Helpers
    
    func setupInitialValues() {
        shareLocationSwitch.isOn = false
        shareLocationSwitch.isEnabled = false
        
        nicknameTextField.addTarget(self, action: #selector(textFieldDidChangeText(sender:)), for: .editingChanged)
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func setupAppToInitialState() {
        navigationController?.popToRootViewController(animated: true)
        shareLocationSwitch.isOn = false
        shareLocationLabel.text = "Share location"
        locationManager.stopUpdatingLocation()
    }
    
    func textFieldDidChangeText(sender: UITextField) {
        if let nicknameString = sender.text {
            nickname = nicknameString
        }
    }

    @IBAction func shareLcoationSwitchAction(_ sender: UISwitch) {
        shareLocationLabel.text = sender.isOn ? "Stop sharing location" : "Share location"
        
        if sender.isOn {
            userStartedLocationSharing()
        }
        else {
            userStoppedLocationSharing()
        }
        
        nicknameTextField.resignFirstResponder()
    }
    
    //Listen to all necessary events
    func listenToEvents() {
        listenToConnectionChanges()
        listenToTrackedUsersListUpdate()
    }
    
    // MARK: - Socket functions
    
    //Send message to server that user is sharing location
    func userStartedLocationSharing() {
        SocketManager.sharedInstance.userStartedLocationSharing(withNickname: nickname)
        self.locationManager.startUpdatingLocation()
    }
    
    //Send message to server that user stopped sharing location
    func userStoppedLocationSharing() {
        SocketManager.sharedInstance.userStoppedLocationSharing()
        self.locationManager.stopUpdatingLocation()
    }
    
    func listenToConnectionChanges() {
        SocketManager.sharedInstance.listenToConnectionChanges(onConnectHandler: {
            
            //if user was successfully connected to server we ask for a updated tracked user list
            SocketManager.sharedInstance.checkForUpdatedTrackedUsersList()
            
        }, onDisconnectHandler: {
            
            //if user was disconnected from server we update the app interface
            self.setupAppToInitialState()
            
        })
    }
    
    //Listen to updates in tracked user list, whenever it is updated or when we request
    func listenToTrackedUsersListUpdate() {
        SocketManager.sharedInstance.listenToTrackedUsersListUpdate() { trakedUsersListUpdate in
            if let listUpdate = trakedUsersListUpdate {
                self.trackedUsers = listUpdate
                
                self.tableView.reloadData()
            }            
        }
    }
    
    //Send to server the current coordinates when sharing location
    func sendCoordinates(withLocation location: CLLocation) {
        SocketManager.sharedInstance.sendCoordinates(withLatitude: String(location.coordinate.latitude), andLongitude: String(location.coordinate.longitude))
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let trackedUser = sender as? [String:AnyObject], let mapVC = segue.destination as? MapVC {
            mapVC.trackedUser = trackedUser
        }
    }
}

// MARK: - CLLocationManagerDelegate -

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        
        //Whenever the location is updated we send it to server
        sendCoordinates(withLocation: location)
    }
    
}

// MARK: - UITableViewDelegate and UITableViewDataSource -

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            if let trackerUserNickname = trackedUsers[indexPath.row]["nickname"] as? String {
                cell.textLabel?.text = trackerUserNickname
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trackedUser = trackedUsers[indexPath.row]
        
        performSegue(withIdentifier: "SegueToMapVC", sender: trackedUser)
    }
    
}


