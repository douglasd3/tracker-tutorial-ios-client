//
//  MapVC.swift
//  WebSocketTracker
//
//  Created by Douglas Barbosa on 27/05/17.
//  Copyright © 2017 Douglas Barbosa. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Properties
    
    var trackedUser: [String:AnyObject]!
    
    var locationPin = MKPointAnnotation()
    
    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTrackingUser()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopTrackingUser()
    }
    
    // MARK: - Helpers
    
    func updateTrackedUserLocation(withLatitude latitude: Double, andLongitude longitude: Double) {
        locationPin.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        mapView.addAnnotation(locationPin)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(locationPin.coordinate, 300, 300)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // MARK: - Socket functions
    
    func startTrackingUser() {
        if let trackedUserId = trackedUser["id"] as? String {
            
            //Send to server a message that user is now tracking a tracked user location
            SocketManager.sharedInstance.userStartedTracking(trackedUserSocketId: trackedUserId, coordinatesUpdateHandler: { trakedUsersCorrdinatesUpdate in
                
                //When we receive tracked user current location the map is updated
                if let latitudeString = trakedUsersCorrdinatesUpdate?["latitude"] as? String, let longitudeString = trakedUsersCorrdinatesUpdate?["longitude"] as? String, let latitude = Double(latitudeString), let longitude = Double(longitudeString) {
                    self.updateTrackedUserLocation(withLatitude: latitude, andLongitude: longitude)
                }
                
            }, trackedUserStoppedTrackingHandler: { trackedUserNickname in
                
                //When the tracked user stops sharing location we return to the tracked users list
                if let nickname = trackedUserNickname {
                    let alert = UIAlertController(title: "Ops!", message: "\(nickname) has stopped sharing location", preferredStyle: .alert)
                    let okButton = UIAlertAction(title: "Ok", style: .default) { action in
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    
                    alert.addAction(okButton)
                    
                    self.present(alert, animated: true, completion: nil)
                }
                
            })
        }
    }
    
    func stopTrackingUser() {
        if let trackedUserId = trackedUser["id"] as? String {
            //Let the server know that the user is no longer tracking
            SocketManager.sharedInstance.userStoppedTracking(trackedUserSocketId: trackedUserId)
        }
    }

}
