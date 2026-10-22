// Features/Map/PandalAnnotation.swift — MKAnnotation subclass for pandals + custom MKAnnotationView

import Foundation
import MapKit
import SwiftUI

final class PandalAnnotation: NSObject, MKAnnotation {
    let pandal: Pandal
    let stopNumber: Int?
    var coordinate: CLLocationCoordinate2D { pandal.coordinate }
    var title: String? {
        if let num = stopNumber {
            return "#\(num) \(pandal.name)"
        }
        return pandal.name
    }
    var subtitle: String? { pandal.zone.label }

    init(pandal: Pandal, stopNumber: Int? = nil) {
        self.pandal = pandal
        self.stopNumber = stopNumber
    }
}

final class MetroAnnotation: NSObject, MKAnnotation {
    let station: MetroStation
    var coordinate: CLLocationCoordinate2D { station.coordinate }
    var title: String? { station.name }
    var subtitle: String? { station.line.label }
    init(station: MetroStation) { self.station = station }
}

final class TransitStationAnnotation: NSObject, MKAnnotation {
    let station: TransitStation
    var coordinate: CLLocationCoordinate2D { station.coordinate }
    var title: String? { station.displayName }
    var subtitle: String? { "\(station.typeLabel) · \(station.lines.first ?? station.network ?? "Kolkata")" }
    init(station: TransitStation) { self.station = station }
}

final class FoodSpotAnnotation: NSObject, MKAnnotation {
    let spot: FoodSpot
    var coordinate: CLLocationCoordinate2D { spot.coordinate }
    var title: String? { spot.name }
    var subtitle: String? { spot.type }
    init(spot: FoodSpot) { self.spot = spot }
}

@MainActor
final class SquadMemberAnnotation: NSObject, @preconcurrency MKAnnotation {
    var member: SquadMember {
        didSet {
            title = member.name
            subtitle = member.status
        }
    }
    @objc dynamic var coordinate: CLLocationCoordinate2D
    @objc dynamic var title: String?
    @objc dynamic var subtitle: String?
    private var coordinateUpdateToken = UUID()

    init(member: SquadMember) {
        self.member = member
        coordinate = member.coordinate
        title = member.name
        subtitle = member.status
        super.init()
    }

    func update(_ updatedMember: SquadMember, reduceMotion: Bool) {
        guard updatedMember.lastSeen >= member.lastSeen else { return }
        let start = coordinate
        let destination = updatedMember.coordinate
        let oldMarkerState = member.markerState
        member = updatedMember
        let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))

        guard !reduceMotion,
              oldMarkerState == .fresh,
              updatedMember.markerState == .fresh,
              distance >= 3,
              distance <= 250 else {
            coordinateUpdateToken = UUID()
            coordinate = destination
            return
        }

        let token = UUID()
        coordinateUpdateToken = token
        Task { @MainActor [weak self] in
            let frameCount = 6
            for frame in 1...frameCount {
                try? await Task.sleep(nanoseconds: 70_000_000)
                guard let self, self.coordinateUpdateToken == token else { return }
                let progress = Double(frame) / Double(frameCount)
                self.coordinate = CLLocationCoordinate2D(
                    latitude: start.latitude + (destination.latitude - start.latitude) * progress,
                    longitude: start.longitude + (destination.longitude - start.longitude) * progress
                )
            }
        }
    }
}

/// Custom annotation view — teardrop pin with gold outline, stop numbering, and priority layering atop stations.
final class PandalAnnotationView: MKAnnotationView {
    static let reuseId = "PandalAnnotationView"
    private var renderToken = UUID()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false
        self.collisionMode = .circle
        self.clusteringIdentifier = "uma.pandal"
        self.centerOffset = CGPoint(x: 0, y: -14)
        self.frame = CGRect(x: 0, y: 0, width: 32, height: 40)
        // High zPriority ensures numbered festival pins layer atop station pins
        self.zPriority = MKAnnotationViewZPriority(rawValue: 1000)
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        renderToken = UUID()
        image = nil
        super.prepareForReuse()
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        guard let pAnno = annotation as? PandalAnnotation else { return }

        let stopNum = pAnno.stopNumber
        let pandalID = pAnno.pandal.id
        let token = UUID()
        renderToken = token
        image = nil
        clusteringIdentifier = stopNum == nil ? "uma.pandal" : nil
        self.zPriority = stopNum != nil
            ? MKAnnotationViewZPriority(rawValue: 1000)
            : MKAnnotationViewZPriority(rawValue: 800)
        self.displayPriority = stopNum != nil ? .required : .defaultHigh

        let pinView = ZStack {
            PandalPinShape()
                .fill(PujaColors.durgaRed)
                .overlay(
                    PandalPinShape()
                        .stroke(PujaColors.festivalGold, lineWidth: 1.8)
                )

            if let num = stopNum {
                Text("\(num)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(PujaColors.goldBright)
                    .offset(y: -4)
            }
        }
        .frame(width: 32, height: 40)

        Task { @MainActor [weak self] in
            guard let self,
                  self.renderToken == token,
                  let current = self.annotation as? PandalAnnotation,
                  current.pandal.id == pandalID,
                  current.stopNumber == stopNum else { return }
            let renderer = ImageRenderer(content: pinView)
            renderer.scale = UIScreen.main.scale
            renderer.proposedSize = .init(width: 32, height: 40)
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
