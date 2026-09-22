// Features/Map/PandalAnnotation.swift — MKAnnotation subclass for pandals + custom MKAnnotationView

import Foundation
import MapKit
import SwiftUI

final class PandalAnnotation: NSObject, MKAnnotation {
    let pandal: Pandal
    var coordinate: CLLocationCoordinate2D { pandal.coordinate }
    var title: String? { pandal.name }
    var subtitle: String? { pandal.zone.label }

    init(pandal: Pandal) { self.pandal = pandal }
}

final class MetroAnnotation: NSObject, MKAnnotation {
    let station: MetroStation
    var coordinate: CLLocationCoordinate2D { station.coordinate }
    var title: String? { station.name }
    var subtitle: String? { station.line.label }
    init(station: MetroStation) { self.station = station }
}

final class FoodSpotAnnotation: NSObject, MKAnnotation {
    let spot: FoodSpot
    var coordinate: CLLocationCoordinate2D { spot.coordinate }
    var title: String? { spot.name }
    var subtitle: String? { spot.type }
    init(spot: FoodSpot) { self.spot = spot }
}

final class SquadMemberAnnotation: NSObject, MKAnnotation {
    let member: SquadMember
    var coordinate: CLLocationCoordinate2D { member.coordinate }
    var title: String? { member.name }
    var subtitle: String? { member.status }
    init(member: SquadMember) { self.member = member }
}

/// Custom annotation view — teardrop pin with gold outline, "selected" pulse.
final class PandalAnnotationView: MKAnnotationView {
    static let reuseId = "PandalAnnotationView"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false
        self.collisionMode = .circle
        self.centerOffset = CGPoint(x: 0, y: -14)
        self.frame = CGRect(x: 0, y: 0, width: 30, height: 38)
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        guard annotation is PandalAnnotation else { return }
        let pin = PandalPinShape()
            .fill(PujaColors.durgaRed)
            .overlay(
                PandalPinShape()
                    .stroke(PujaColors.festivalGold, lineWidth: 1.6)
            )
        Task { @MainActor in
            let renderer = ImageRenderer(content: pin.frame(width: 30, height: 38))
            renderer.scale = UIScreen.main.scale
            renderer.proposedSize = .init(width: 30, height: 38)
            if let img = renderer.uiImage {
                self.image = img
            }
        }
    }
}

private struct PandalPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let topY = rect.minY
        let botY = rect.maxY
        let r: CGFloat = rect.width / 2

        // Teardrop body
        p.addEllipse(in: CGRect(x: rect.minX, y: topY, width: rect.width, height: rect.height * 0.7))
        // Bottom point
        p.move(to: CGPoint(x: cx - r * 0.6, y: rect.minY + rect.height * 0.55))
        p.addLine(to: CGPoint(x: cx, y: botY))
        p.addLine(to: CGPoint(x: cx + r * 0.6, y: rect.minY + rect.height * 0.55))
        p.closeSubpath()
        return p
    }
}
