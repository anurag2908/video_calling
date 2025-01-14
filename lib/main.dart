import 'package:agora_token_service/agora_token_service.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoCallPage(),
    );
  }
}

class VideoCallPage extends StatefulWidget {
  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  static const String appId = 'ae8adc7f61d64048b3d8d40bb6517bf9';
  static const String channelName = 'tester23';
  static const String appCertificate = 'a983d57ae67642ae8f9bd07e4bb95c3c';

  late RtcEngine _engine;
  int? _remoteUid;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    // Initialize the Agora engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: appId));

    // Set up event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _isJoined = true;
          });
          debugPrint('Local user joined channel: ${connection.channelId}');
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
          debugPrint('Remote user joined: $remoteUid');
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUid = null;
          });
          debugPrint('Remote user left: $remoteUid');
        },
      ),
    );

    // Enable video
    await _engine.enableVideo();

    const expirationInSeconds = 36000;
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expireTimestamp = currentTimestamp + expirationInSeconds;

    // Fetch and use the token
    String token = RtcTokenBuilder.build(
      appId: appId,
      appCertificate: "a983d57ae67642ae8f9bd07e4bb95c3c",
      channelName: channelName,
      uid: '0',
      role: RtcRole.publisher,
      expireTimestamp: expireTimestamp,
    );

    // Join the channel
    await _engine.startPreview();
    await _engine.joinChannel(
      token: token, // Use a token if required, otherwise pass null
      channelId: channelName,
      uid: 0, // Set 0 to let Agora assign a unique ID
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _engine.leaveChannel();
    _engine.release();
  }

  Widget _renderLocalPreview() {
    if (_isJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Text('Joining channel, please wait...');
    }
  }

  Widget _renderRemoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channelName),
        ),
      );
    } else {
      return const Text(
        'Waiting for remote user to join...',
        textAlign: TextAlign.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Video Call'),
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: _renderLocalPreview())),
          const Divider(),
          Expanded(child: Center(child: _renderRemoteVideo())),
        ],
      ),
    );
  }
}
