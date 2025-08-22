import Foundation
import Network

class NetworkDebug {
    static let shared = NetworkDebug()
    private let monitor = NWPathMonitor()
    private var isMonitoring = false
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Network connection established")
                print("Interface type: \(path.availableInterfaces.map { $0.type })")
            } else {
                print("No network connection")
            }
            
            print("Is expensive: \(path.isExpensive)")
            print("Supports IPv4: \(path.supportsIPv4)")
            print("Supports IPv6: \(path.supportsIPv6)")
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        isMonitoring = true
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }
}
