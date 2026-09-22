// Services/TrailOptimizer.swift — port of services/trail_optimizer.dart
// Held-Karp DP (N ≤ 12) + Nearest Neighbor + 2-opt (N > 12)

import Foundation
import CoreLocation

struct TrailOptimizationResult {
    let orderedStops: [Pandal]
    let totalDurationMinutes: Double
    let totalDistanceKm: Double
    let visitOrderIndices: [Int]
    let legs: [TrailLeg]
}

/// On-device deterministic shortest Hamiltonian-path optimizer (start fixed, no return).
enum TrailOptimizer {
    static let defaultWalkingSpeedKmH: Double = 4.5
    static let defaultCircuityFactor: Double = 1.25
    static let exactThreshold: Int = 12

    /// High-level: optimize a list of pandals starting from `start`.
    static func optimizePandalStops(
        start: CLLocationCoordinate2D,
        stops: [Pandal],
        walkingSpeedKmH: Double = defaultWalkingSpeedKmH,
        circuityFactor: Double = defaultCircuityFactor,
        allowMetro: Bool = false
    ) -> TrailOptimizationResult {
        guard !stops.isEmpty else {
            return TrailOptimizationResult(orderedStops: [], totalDurationMinutes: 0,
                                           totalDistanceKm: 0, visitOrderIndices: [], legs: [])
        }

        if stops.count == 1 {
            let p = stops[0]
            let dist = haversineMeters(start, p.coordinate) * circuityFactor
            let walkMins = dist / (walkingSpeedKmH * 1000.0 / 60.0)
            return TrailOptimizationResult(
                orderedStops: [p],
                totalDurationMinutes: walkMins,
                totalDistanceKm: (dist / 1000.0 * 100).rounded() / 100,
                visitOrderIndices: [0], legs: [])
        }

        let matrix = buildDurationMatrix(start: start, stops: stops,
                                         walkingSpeedKmH: walkingSpeedKmH,
                                         circuityFactor: circuityFactor,
                                         allowMetro: allowMetro)
        let result = optimize(matrix)

        let stopIndices = result.order.map { $0 - 1 }
        let ordered = stopIndices.map { stops[$0] }

        var totalDist: Double = 0
        var prev = start
        for p in ordered {
            totalDist += haversineMeters(prev, p.coordinate) * circuityFactor
            prev = p.coordinate
        }

        return TrailOptimizationResult(
            orderedStops: ordered,
            totalDurationMinutes: result.totalDuration,
            totalDistanceKm: (totalDist / 1000.0 * 100).rounded() / 100,
            visitOrderIndices: stopIndices,
            legs: [])
    }

    /// (N+1) × (N+1) duration matrix where index 0 is `start`.
    static func buildDurationMatrix(
        start: CLLocationCoordinate2D,
        stops: [Pandal],
        walkingSpeedKmH: Double = defaultWalkingSpeedKmH,
        circuityFactor: Double = defaultCircuityFactor,
        allowMetro: Bool = false
    ) -> [[Double]] {
        let n = stops.count + 1
        let points: [CLLocationCoordinate2D] = [start] + stops.map(\.coordinate)
        var matrix = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        let speedMPerMin = walkingSpeedKmH * 1000.0 / 60.0

        for i in 0..<n {
            for j in 0..<n where i != j {
                let walkDist = haversineMeters(points[i], points[j]) * circuityFactor
                let walkMins = walkDist / speedMPerMin
                matrix[i][j] = walkMins
                _ = allowMetro  // metro estimator not implemented in v1 — keeps API stable
            }
        }
        return matrix
    }

    static func optimize(_ duration: [[Double]]) -> (order: [Int], totalDuration: Double) {
        let numStops = duration.count - 1
        guard numStops > 0 else { return ([], 0) }
        if numStops <= exactThreshold {
            return solveExact(duration)
        }
        return solveHeuristic(duration)
    }

    /// Held-Karp DP shortest Hamiltonian path from fixed node 0.
    /// Preserves the Flutter 1:1 behavior including N=1 short-circuit.
    static func solveExact(_ duration: [[Double]]) -> (order: [Int], totalDuration: Double) {
        let n = duration.count
        let numStops = n - 1
        if numStops == 0 { return ([], 0) }
        if numStops == 1 { return ([1], duration[0][1]) }

        let fullMask = 1 << numStops
        var dp = Array(repeating: Array(repeating: Double.infinity, count: n), count: fullMask)
        var parent = Array(repeating: Array(repeating: -1, count: n), count: fullMask)

        // Base case: directly from start to each stop i (node i+1)
        for i in 0..<numStops {
            dp[1 << i][i + 1] = duration[0][i + 1]
        }

        for mask in 1..<fullMask {
            for j in 0..<numStops {
                if (mask & (1 << j)) == 0 { continue }
                let cur = dp[mask][j + 1]
                if cur == .infinity { continue }
                for k in 0..<numStops {
                    if (mask & (1 << k)) != 0 { continue }
                    let nextMask = mask | (1 << k)
                    let cand = cur + duration[j + 1][k + 1]
                    if cand < dp[nextMask][k + 1] {
                        dp[nextMask][k + 1] = cand
                        parent[nextMask][k + 1] = j + 1
                    }
                }
            }
        }

        // Pick best end node
        var bestEnd = -1
        var bestCost = Double.infinity
        for j in 0..<numStops {
            if dp[fullMask - 1][j + 1] < bestCost {
                bestCost = dp[fullMask - 1][j + 1]
                bestEnd = j + 1
            }
        }

        // Backtrack to recover order
        var order: [Int] = []
        var mask = fullMask - 1
        var node = bestEnd
        while node != -1 && node != 0 {
            order.append(node)
            let p = parent[mask][node]
            mask &= ~(1 << (node - 1))
            node = p
        }
        return (order.reversed(), bestCost)
    }

    /// Nearest-neighbor construction + 2-opt local search.
    /// **Faithful 1:1 port**: the inner `break` after first improvement per outer iteration
    /// is preserved, matching the Flutter source exactly. Result may be up to ~5% from optimum.
    static func solveHeuristic(_ duration: [[Double]]) -> (order: [Int], totalDuration: Double) {
        let n = duration.count
        let numStops = n - 1
        if numStops == 0 { return ([], 0) }
        if numStops == 1 { return ([1], duration[0][1]) }

        // Nearest neighbor
        var unvisited = Set((1...numStops).map { $0 })
        var tour: [Int] = []
        var current = 0
        while !unvisited.isEmpty {
            var bestNext = unvisited.first!
            var minD = duration[current][bestNext]
            for c in unvisited {
                if duration[current][c] < minD {
                    minD = duration[current][c]
                    bestNext = c
                }
            }
            tour.append(bestNext)
            unvisited.remove(bestNext)
            current = bestNext
        }

        func cost(_ t: [Int]) -> Double {
            guard let first = t.first else { return 0 }
            var c = duration[0][first]
            for i in 0..<(t.count - 1) {
                c += duration[t[i]][t[i + 1]]
            }
            return c
        }

        var bestCost = cost(tour)
        var improved = true
        var iter = 0
        let maxIter = 80
        while improved && iter < maxIter {
            improved = false
            iter += 1
            for i in 0..<(tour.count - 1) {
                for j in (i + 1)..<tour.count {
                    var reversed = tour
                    var l = i, r = j
                    while l < r {
                        let tmp = reversed[l]
                        reversed[l] = reversed[r]
                        reversed[r] = tmp
                        l += 1; r -= 1
                    }
                    let newCost = cost(reversed)
                    if newCost < bestCost - 1e-6 {
                        tour = reversed
                        bestCost = newCost
                        improved = true
                        break
                    }
                }
                if improved { break }
            }
        }
        return (tour, bestCost)
    }
}
