import 'dart:async';
import 'dart:developer';
import 'dart:io';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Timer? _connectivityTimer;
  bool _isConnected = false;

  /// Stream of connectivity status
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Start monitoring connectivity
  void startMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
    
    // Check immediately
    _checkConnectivity();
  }

  /// Stop monitoring connectivity
  void stopMonitoring() {
    _connectivityTimer?.cancel();
  }

  /// Check connectivity once
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateConnectivity(isConnected);
      return isConnected;
    } on SocketException catch (_) {
      _updateConnectivity(false);
      return false;
    } catch (e) {
      log('Connectivity check failed: $e');
      _updateConnectivity(false);
      return false;
    }
  }

  /// Force connectivity check with API endpoint
  Future<bool> checkApiConnectivity(String apiUrl) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(apiUrl));
      request.headers.add('Connection', 'close');
      final response = await request.close().timeout(const Duration(seconds: 5));
      await response.drain();
      httpClient.close();
      
      final isConnected = response.statusCode == 200;
      _updateConnectivity(isConnected);
      return isConnected;
    } catch (e) {
      log('API connectivity check failed: $e');
      _updateConnectivity(false);
      return false;
    }
  }

  void _checkConnectivity() async {
    await checkConnectivity();
  }

  void _updateConnectivity(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectivityController.add(isConnected);
      log('Connectivity changed: $isConnected');
    }
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }
}