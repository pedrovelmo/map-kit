//
//  ViewController.swift
//  MapKitAula
//
//  Created by Alline Pedreira on 02/03/17.
//  Copyright © 2017 Alline Pedreira. All rights reserved.
//

import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController {
    
    let locationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    var selectedPin:MKPlacemark? = nil
    
    var resultSearchController:UISearchController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configurar Localização
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        // Instanciar a TableView e configurar os resultados da busca dos lugares
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        // Inicilizar e customizar a SearchBar e inserí-la dentro da Navigation Bar
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar

        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getDirections(){
        if let selectedPin = selectedPin {
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
    func findFastestRoute(routes: [MKRoute]) -> MKRoute {
        let rotasOrdenadas = routes.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})
        return rotasOrdenadas[0]
    }
}


extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if locations.first != nil {
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegion(center: (locations.first?.coordinate)!, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error)")
    }
}


extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        
        // create annotation based on placemark
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city), \(state)"
        }
        
        // add annotation on the map
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}

extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), for: .normal)
        button.addTarget(self, action: #selector(ViewController.getDirections), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        var origem: CLLocationCoordinate2D? = self.locationManager.location?.coordinate
        var destino: CLLocationCoordinate2D? = view.annotation?.coordinate
        var obtainedRoutes: [MKRoute]?
        var fastestRoute: MKRoute?
        
        let directionsRequest = MKDirectionsRequest()
        let destination = MKPlacemark(coordinate: destino!, addressDictionary: nil)
        let origin = MKPlacemark(coordinate: origem!, addressDictionary: nil)
        directionsRequest.source = MKMapItem(placemark: origin)
        directionsRequest.destination = MKMapItem(placemark: destination)
        directionsRequest.transportType = MKDirectionsTransportType.automobile
        directionsRequest.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate(completionHandler: { (response, error) in
            
            if (error != nil) {
                
                print("Error getting directions ",error?.localizedDescription)
                
            }
                
            else if (response == nil) {
                
                obtainedRoutes = []
            }
                
            else {
                
                obtainedRoutes = response!.routes as [MKRoute]
                fastestRoute = self.findFastestRoute(routes: obtainedRoutes!)
                print("Fastest route time: ", fastestRoute?.expectedTravelTime)
                self.mapView.add((fastestRoute?.polyline)!)
                
            }
        })
        
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        var myLineRenderer = MKPolylineRenderer(overlay: overlay)
        
        myLineRenderer.strokeColor = UIColor.blue
        
        myLineRenderer.lineWidth = 3
        
        return myLineRenderer
    }
    
}


