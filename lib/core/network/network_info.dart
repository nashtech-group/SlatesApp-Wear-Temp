// lib/core/network/network_info.dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  // You can use connectivity_plus package for actual implementation
  @override
  Future<bool> get isConnected async {
    // Implementation using connectivity_plus package
    // For now, returning true - implement based on your needs
    return true;
  }
}
