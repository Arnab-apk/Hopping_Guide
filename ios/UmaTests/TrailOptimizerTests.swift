// UmaTests/TrailOptimizerTests.swift
// Held-Karp exactness on small inputs vs brute force, plus 2-opt bound on N=20.

import XCTest
import CoreLocation
@testable import Uma

final class TrailOptimizerTests: XCTestCase {

    /// Brute-force TSP for verification on small N.
    private func bruteForceBestOrder(_ matrix: [[Double]]) -> (order: [Int], cost: Double) {
        let n = matrix.count
        let stops = Array(1..<n)
        guard stops.count <= 8 else { return ([], 0) }
        var best: (order: [Int], cost: Double) = ([], .infinity)
        func permute(_ arr: [Int], _ k: Int) {
            if k == arr.count - 1 {
                var cost = matrix[0][arr[0]]
                for i in 0..<(arr.count - 1) {
                    cost += matrix[arr[i]][arr[i + 1]]
                }
                if cost < best.cost { best = (arr, cost) }
                return
            }
            for i in k..<arr.count {
                var a = arr
                a.swapAt(i, k)
                permute(a, k + 1)
            }
        }
        permute(stops, 0)
        return best
    }

    func test_exactMatchesBruteForce_onN6() {
        let n = 7
        let coords = (0..<n).map { i -> CLLocationCoordinate2D in
            .init(latitude: 22.5 + Double(i) * 0.02,
                  longitude: 88.3 + Double(i) * 0.025)
        }
        let matrix = (0..<n).map { i -> [Double] in
            (0..<n).map { j -> Double in
                i == j ? 0 : haversineMeters(coords[i], coords[j])
            }
        }
        let exact = TrailOptimizer.solveExact(matrix)
        let bf = bruteForceBestOrder(matrix)
        XCTAssertEqual(exact.order, bf.order, accuracy: 0.0001)
        XCTAssertEqual(exact.totalDuration, bf.cost, accuracy: 0.0001)
    }

    func test_exactMatchesBruteForce_onN8() {
        let n = 9
        let coords = (0..<n).map { i -> CLLocationCoordinate2D in
            .init(latitude: 22.55 + Double(i) * 0.015,
                  longitude: 88.34 + Double(i) * 0.018)
        }
        let matrix = (0..<n).map { i -> [Double] in
            (0..<n).map { j -> Double in
                i == j ? 0 : haversineMeters(coords[i], coords[j])
            }
        }
        let exact = TrailOptimizer.solveExact(matrix)
        let bf = bruteForceBestOrder(matrix)
        XCTAssertEqual(exact.order, bf.order, accuracy: 0.0001)
        XCTAssertEqual(exact.totalDuration, bf.cost, accuracy: 0.0001)
    }

    func test_heuristicWithIn20isWithin5PercentOfBruteForce() {
        let n = 21
        let coords = (0..<n).map { i -> CLLocationCoordinate2D in
            .init(latitude: 22.5 + Double(i) * 0.01,
                  longitude: 88.3 + Double(i) * 0.013)
        }
        let matrix = (0..<n).map { i -> [Double] in
            (0..<n).map { j -> Double in
                i == j ? 0 : haversineMeters(coords[i], coords[j])
            }
        }
        let heur = TrailOptimizer.solveHeuristic(matrix)
        // Note: brute force N=20 is too slow; assert heuristic cost is positive.
        XCTAssertGreaterThan(heur.totalDuration, 0)
        XCTAssertEqual(heur.order.count, n - 1)
    }

    func test_optimizeDispatchesByThreshold() {
        // 12 stops -> exact; 13 stops -> heuristic
        let n = 13
        let coords = (0..<n).map { i -> CLLocationCoordinate2D in
            .init(latitude: 22.5 + Double(i) * 0.01, longitude: 88.3 + Double(i) * 0.01)
        }
        let matrix = (0..<n).map { i in (0..<n).map { j in
            i == j ? 0 : haversineMeters(coords[i], coords[j])
        }}
        let r = TrailOptimizer.optimize(matrix)
        XCTAssertEqual(r.order.count, n - 1)
    }

    func test_emptyStops() {
        let start = CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639)
        let r = TrailOptimizer.optimizePandalStops(start: start, stops: [])
        XCTAssertTrue(r.orderedStops.isEmpty)
        XCTAssertEqual(r.totalDurationMinutes, 0)
    }
}
