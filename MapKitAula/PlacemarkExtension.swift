//
//  PlacemarkExtension.swift
//  MapKitAula
//
//  Created by Pedro Velmovitsky on 06/03/17.
//  Copyright © 2017 Alline Pedreira. All rights reserved.
//

import Foundation
import MapKit


extension MKPlacemark {
    
    var parseAddress: String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (self.subThoroughfare != nil && self.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (self.subThoroughfare != nil || self.thoroughfare != nil) && (self.subAdministrativeArea != nil || self.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (self.subAdministrativeArea != nil && self.administrativeArea != nil) ? " " : ", "
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            self.subThoroughfare ?? "",
            firstSpace,
            // street name
            self.thoroughfare ?? "",
            comma,
            // city
            self.locality ?? "",
            secondSpace,
            // state
            
            self.administrativeArea ?? ""
        )
        return addressLine
    }
    
}
