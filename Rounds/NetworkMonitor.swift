//
//  NetworkMonitor.swift
//  Rounds
//
//  Ward wifi drops. The account gate must not appear while the device is
//  offline — play continues and the gate waits until a path exists again.
//

import Foundation
import Network

@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isOnline = true

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { path in
            let online = path.status == .satisfied
            Task { @MainActor in
                NetworkMonitor.shared.isOnline = online
            }
        }
        monitor.start(queue: DispatchQueue(label: "rounds.network"))
    }
}
