// api_provider.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class ApiProvider {
  // Update this to your server's IP & port.
  // If you run on a LAN, "192.168.1.2" might need to be changed.
  final String _wsUrl = "ws://192.168.1.7:8000/ws";

  IOWebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onServerMessage;

  /// Connect to the WebSocket and start listening for server responses.
  void connect({Function(Map<String, dynamic>)? onMessage}) {
    // Create a new WebSocket channel:
    _channel = IOWebSocketChannel.connect(Uri.parse(_wsUrl));

    // Keep reference to the callback (so we can call setState in the UI).
    onServerMessage = onMessage;

    // Listen to incoming messages from the server:
    _channel?.stream.listen((message) {
      try {
        // The server sends JSON, so decode it:
        final decoded = jsonDecode(message);
        if (onServerMessage != null) {
          onServerMessage!(decoded);
        }
      } catch (e) {
        print("Error decoding message: $e");
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    }, onDone: () {
      print("WebSocket connection closed.");
    });
  }

  /// Send a single camera frame (already converted to JPEG bytes) over the WebSocket.
  void sendFrame(Uint8List frameBytes) {
    if (_channel == null) return;
    try {
      // Convert the image to Base64 and send it as text:
      final base64Image = base64Encode(frameBytes);
      _channel?.sink.add(base64Image);
    } catch (e) {
      print("Error sending frame over WebSocket: $e");
    }
  }

  /// Send a clear command to the server to reset its internal state.
  void sendClearCommand() {
    if (_channel == null) return;
    try {
      _channel!.sink.add("CLEAR");
    } catch (e) {
      print("Error sending clear command: $e");
    }
  }

  /// Close the WebSocket connection.
  void closeConnection() {
    _channel?.sink.close(status.normalClosure);
    _channel = null;
  }
}
