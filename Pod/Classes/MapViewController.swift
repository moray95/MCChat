//
//  MapViewController.swift
//  MultipeerConnectivityChat
//
//  Created by Moray on 01/07/15.
//  Copyright © 2015 Moray. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class UnlocatedPeerCell : UICollectionViewCell
{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!

}


class Annotation : NSObject, MKAnnotation
{
    @objc var coordinate : CLLocationCoordinate2D
    @objc var title : String? = ""
    @objc let subtitle : String? = ""

    init(location : CLLocation, title : String)
    {
        self.coordinate = location.coordinate
        self.title = title
    }
}

class RotationToggleBarButtonItem : UIBarButtonItem
{
    var state = true
}

class MapViewController: UIViewController, MKMapViewDelegate
{

    @IBOutlet weak var mapView: MyMapView!
    @IBOutlet weak var collectionView: UICollectionView!

    var unlocatedPeers = [String]()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = RotationToggleBarButtonItem(title: "Rotation: On", style: UIBarButtonItemStyle.Plain, target: self, action: "toggleRotation:")

        var location = locations[NSUserDefaults.displayName]
        mapView.delegate = self
        mapView.userTrackingMode = .FollowWithHeading

        for (displayName, peerLocation) in locations
        {
            if displayName != NSUserDefaults.displayName
            {
                let annotation = Annotation(location: peerLocation, title: displayName)
                mapView.addAnnotation(annotation)
                location = location ?? peerLocation
            }
        }
        /*if location != nil
        {

            var maxLong = location!.coordinate.longitude + location!.horizontalAccuracy/(111_111.0 * cos(location!.coordinate.latitude))
            var minLong = location!.coordinate.longitude - location!.horizontalAccuracy/(111_111.0 * cos(location!.coordinate.latitude))
            var maxLat = location!.coordinate.latitude + location!.horizontalAccuracy/111_111.0
            var minLat = location!.coordinate.latitude - location!.horizontalAccuracy/111_111.0

            for (_, location) in locations
            {
                let error = location.horizontalAccuracy
                if location.coordinate.latitude - error/111_111.0 < minLat
                {
                    minLat = location.coordinate.latitude - error/111_111.0
                }
                if location.coordinate.latitude + error/111_111.0 > maxLat
                {
                    maxLat = location.coordinate.latitude + error/111_111.0
                }
                if location.coordinate.longitude - error/(111_111.0 * cos(minLat)) < minLong
                {
                    minLong = location.coordinate.longitude - error/(111_111.0 * cos(minLat))
                }
                if location.coordinate.longitude - error/(111_111.0 * cos(maxLat)) < maxLong
                {
                    maxLong = location.coordinate.longitude - error/(111_111.0 * cos(maxLat))
                }
            }

            mapView.region = MKCoordinateRegion(center: location!.coordinate,
                                                  span: MKCoordinateSpan(
                                                            latitudeDelta: abs(maxLat - minLat),
                                                            longitudeDelta: abs(maxLong - minLong)))

            mapView.showsUserLocation = true
        }*/


        for (peer, _) in connectedUserInfo
        {
            if locations[peer] == nil
            {
                unlocatedPeers.append(peer)
            }
        }
        collectionView.reloadData()
    }

    // MARK: Actions
    func toggleRotation(sender : RotationToggleBarButtonItem)
    {
		sender.state = !sender.state
        if !sender.state
        {
            mapView.userTrackingMode = .None
            sender.title = "Rotation: Off"
        }
        else
        {
            mapView.userTrackingMode = .FollowWithHeading
            sender.title = "Rotation: On"
        }
    }


    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation.title!! == "Current Location"
        {
            return nil
        }

        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
        annotationView.image = avatarForDisplayName(annotation.title!!).avatarImage()
        annotationView.canShowCallout = true
        return annotationView
    }

    func mapView(mapView: MKMapView,
                didChangeUserTrackingMode mode: MKUserTrackingMode,
                animated: Bool)
    {
        let button = navigationItem.rightBarButtonItem as! RotationToggleBarButtonItem
        switch mode
        {
        case .None, .Follow:
            button.title = "Rotation: Off"
            button.state = false
        case .FollowWithHeading:
            button.title = "Rotation On"
            button.state = true
        }
    }

    func mapView(mapView: MKMapView,
        rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer
    {
        let renderer = MKCircleRenderer(overlay: overlay)

        let comps = UnsafeMutablePointer<CGFloat>(malloc(sizeof(CGFloat) * 3))
        UIColor.greenColor().getRed(comps, green: comps.successor(), blue: comps.successor().successor(), alpha: nil)
        let color = UIColor(red: comps.memory, green: comps.successor().memory, blue: comps.successor().successor().memory, alpha: 0.2)
        renderer.fillColor = color
        return renderer
    }

    // MARK: UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView,
            numberOfItemsInSection section: Int) -> Int
    {
        return unlocatedPeers.count
    }

    func collectionView(collectionView: UICollectionView,
            cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("unlocatedPeerCell", forIndexPath: indexPath) as? UnlocatedPeerCell
        if cell == nil
        {
            cell = UnlocatedPeerCell()
        }

        cell?.imageView.image = avatarForDisplayName(unlocatedPeers[indexPath.item]).avatarImage()
        cell?.label.text = unlocatedPeers[indexPath.item]
        return cell!
    }

}
