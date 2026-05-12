import Combine
import Foundation
import Network

enum ConnectionType: Equatable {
    case wifi
    case cellular
    case unknown
}

protocol NetworkMonitorProtocol: ObservableObject {
    var isConnected: Bool { get }
}

final class NetworkMonitor: NetworkMonitorProtocol, ObservableObject {
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.filmila.networkmonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.apply(path: path)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func apply(path: NWPath) {
        isConnected = path.status == .satisfied
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else {
            connectionType = .unknown
        }
    }
}
