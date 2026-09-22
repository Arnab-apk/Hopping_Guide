// DouglasPeucker.swift — port of polyline simplification from routing_service.dart

import Foundation
import CoreLocation

/// Iterative Ramer-Douglas-Peucker simplifier (no recursion).
/// Returns a subset of `points` preserving shape within `tolerance` degrees (~5m).
func simplifyRoute(_ points: [CLLocationCoordinate2D], tolerance: Double = 0.00005) -> [CLLocationCoordinate2D] {
    guard points.count > 2 else { return points }

    var keep = Array(repeating: false, count: points.count)
    keep[0] = true
    keep[points.count - 1] = true

    var stack: [(Int, Int)] = [(0, points.count - 1)]
    while let (lo, hi) = stack.popLast() {
        guard hi - lo > 1 else { continue }
        var maxDist = 0.0
        var maxIdx = lo
        let a = points[lo], b = points[hi]
        for i in (lo + 1)..<hi {
            let d = perpendicularDistance(points[i], a, b)
            if d > maxDist { maxDist = d; maxIdx = i }
        }
        if maxDist > tolerance {
            keep[maxIdx] = true
            stack.append((lo, maxIdx))
            stack.append((maxIdx, hi))
        }
    }
    return points.enumerated().compactMap { keep[$0.offset] ? $0.element : nil }
}

private func perpendicularDistance(_ p: CLLocationCoordinate2D, _ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    let dx = b.longitude - a.longitude
    let dy = b.latitude - a.latitude
    if dx == 0 && dy == 0 {
        let ex = p.longitude - a.longitude
        let ey = p.latitude - a.latitude
        return (ex * ex + ey * ey).squareRoot()
    }
    let t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) / (dx * dx + dy * dy)
    let tc = max(0.0, min(1.0, t))
    let projX = a.longitude + tc * dx
    let projY = a.latitude + tc * dy
    let ex = p.longitude - projX
    let ey = p.latitude - projY
    return (ex * ex + ey * ey).squareRoot()
}
