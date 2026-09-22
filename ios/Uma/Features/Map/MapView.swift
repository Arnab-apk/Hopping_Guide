// Features/Map/MapView.swift — UIViewRepresentable hosting MKMapView
// Vector tiles — eliminates the Android white-pixel bug class entirely.

import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @Binding var selectedPandal: Pandal?
    @Binding var highlightedRoute: WalkingRoute?
    var pandals: [Pandal]
    var metroStations: [MetroStation]
    var foodSpots: [FoodSpot]
    var squadMembers: [SquadMember]
    var showFoodSpots: Bool
    var showMetroStations: Bool
    var followUser: Bool
    var userLocation: CLLocationCoordinate2D?
    var onTapPandal: (Pandal) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator

        // Vector tile configuration — fixes the white-pixel bug.
        map.preferredConfiguration = MKStandardMapConfiguration(
            elevationStyle: .realistic,
            emphasisStyle: .muted
        )
        map.overrideUserInterfaceStyle = .dark
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = false
        map.showsUserLocation = true
        map.showsScale = false

        // Native clustering
        map.register(MKMarkerAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        map.register(PandalAnnotationView.self,
                     forAnnotationViewWithReuseIdentifier: PandalAnnotationView.reuseId)

        // Initial region: central Kolkata at low zoom
        let center = CLLocationCoordinate2D(latitude: AppConfig.defaultLat, longitude: AppConfig.defaultLng)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6))
        map.setRegion(region, animated: false)

        context.coordinator.syncAnnotations(map)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.syncAnnotations(map)
        context.coordinator.syncOverlays(map, route: highlightedRoute)
        if followUser, let user = userLocation {
            map.setCenter(user, animated: true)
        }
        if let sel = selectedPandal {
            map.setCenter(sel.coordinate, animated: true)
        }
    }

    // MARK: - Coordinator (delegate)

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        private var lastPandalIds: Set<String> = []
        private var lastMetroIds: Set<String> = []
        private var lastFoodIds: Set<String> = []
        private var lastSquadIds: Set<String> = []

        init(_ parent: MapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier,
                    for: cluster) as! MKMarkerAnnotationView
                view.markerTintColor = UIColor(PujaColors.durgaRed)
                view.glyphText = "\(cluster.memberAnnotations.count)"
                return view
            }

            if annotation is PandalAnnotation {
                return mapView.dequeueReusableAnnotationView(
                    withIdentifier: PandalAnnotationView.reuseId,
                    for: annotation)
            }

            if let m = annotation as? MetroAnnotation {
                let id = "metro_\(m.station.id)"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id)
                            as? MKMarkerAnnotationView)
                           ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                view.annotation = annotation
                view.markerTintColor = UIColor(m.station.line.color)
                view.glyphImage = UIImage(systemName: "tram.fill")
                view.canShowCallout = false
                return view
            }

            if let f = annotation as? FoodSpotAnnotation {
                let id = "food_\(f.spot.id)"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id)
                            as? MKMarkerAnnotationView)
                           ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                view.annotation = annotation
                view.markerTintColor = UIColor(red: 1.0, green: 0.57, blue: 0.0, alpha: 1)
                view.glyphImage = UIImage(systemName: "fork.knife")
                view.canShowCallout = false
                return view
            }

            if let s = annotation as? SquadMemberAnnotation {
                let id = "squad_\(s.member.id)"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                view.annotation = annotation
                view.image = SquadMemberIcon.image(for: s.member)
                view.canShowCallout = false
                view.centerOffset = .zero
                return view
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let p = view.annotation as? PandalAnnotation {
                parent.onTapPandal(p.pandal)
            }
            if let p = view.annotation as? MetroAnnotation {
                Haptics.selection()
            }
            if let p = view.annotation as? FoodSpotAnnotation {
                Haptics.selection()
            }
        }

        func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
            let cluster = MKClusterAnnotation(memberAnnotations: memberAnnotations)
            cluster.title = "\(memberAnnotations.count) pandals"
            return cluster
        }

        func syncAnnotations(_ map: MKMapView) {
            let pandalIds = Set(parent.pandals.map(\.id))
            let metroIds = Set(parent.metroStations.map(\.id))
            let foodIds = Set(parent.foodSpots.map(\.id))
            let squadIds = Set(parent.squadMembers.map(\.id))

            if pandalIds != lastPandalIds {
                let existing = map.annotations.compactMap { $0 as? PandalAnnotation }
                map.removeAnnotations(existing)
                let annos = parent.pandals.map { PandalAnnotation(pandal: $0) }
                map.addAnnotations(annos)
                lastPandalIds = pandalIds
            }
            if metroIds != lastMetroIds {
                let existing = map.annotations.compactMap { $0 as? MetroAnnotation }
                map.removeAnnotations(existing)
                if parent.showMetroStations {
                    let annos = parent.metroStations.map { MetroAnnotation(station: $0) }
                    map.addAnnotations(annos)
                }
                lastMetroIds = metroIds
            }
            if foodIds != lastFoodIds {
                let existing = map.annotations.compactMap { $0 as? FoodSpotAnnotation }
                map.removeAnnotations(existing)
                if parent.showFoodSpots {
                    let annos = parent.foodSpots.map { FoodSpotAnnotation(spot: $0) }
                    map.addAnnotations(annos)
                }
                lastFoodIds = foodIds
            }
            if squadIds != lastSquadIds {
                let existing = map.annotations.compactMap { $0 as? SquadMemberAnnotation }
                map.removeAnnotations(existing)
                let annos = parent.squadMembers.map { SquadMemberAnnotation(member: $0) }
                map.addAnnotations(annos)
                lastSquadIds = squadIds
            }
        }

        func syncOverlays(_ map: MKMapView, route: WalkingRoute?) {
            map.removeOverlays(map.overlays)
            guard let route, route.points.count >= 2 else { return }
            // Glow halo
            let halo = MKPolyline(coordinates: route.points, count: route.points.count)
            map.addOverlay(halo, level: .aboveRoads)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let line = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: line)
                r.strokeColor = UIColor(PujaColors.durgaRed)
                r.lineWidth = 6
                r.lineCap = .round
                r.lineJoin = .round
                r.alpha = 0.9
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Helpers

extension Color {
    var uiColor: UIColor { UIColor(self) }
}

enum SquadMemberIcon {
    @MainActor
    static func image(for member: SquadMember) -> UIImage {
        let size: CGFloat = 36
        let renderer = ImageRenderer(content:
            ZStack {
                Circle()
                    .fill(Color(hex: UInt32(member.avatarColorHex & 0xFFFFFF)))
                    .frame(width: size, height: size)
                Text(member.initials)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: size, height: size)
                Circle()
                    .fill(member.markerState == .fresh ? Color.green :
                          member.markerState == .stale ? Color.yellow : Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(x: 11, y: 11)
            }
            .frame(width: size, height: size)
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? UIImage()
    }
}
