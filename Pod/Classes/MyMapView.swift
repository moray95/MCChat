//
//  MyMapView.swift
//  MultipeerConnectivityChat
//
//  Created by Moray on 03/07/15.
//  Copyright © 2015 Moray. All rights reserved.
//

import UIKit
import MapKit

class MyMapView: MKMapView
{
    override func addAnnotation(annotation: MKAnnotation)
    {
        super.addAnnotation(annotation)
        if annotation.title!! == "Currrent Location"
        {
            return
        }
        let location = locations[annotation.title!!]!
        let overlay = MKCircle(centerCoordinate: location.coordinate, radius: location.horizontalAccuracy)
        
        addOverlay(overlay)
    }

}
