import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../const/agora.dart';

class CamScreen extends StatefulWidget {
  const CamScreen({super.key});

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  RtcEngine? engine;
  int? uid = 0;

  int? otherUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LIVE'),
      ),
      body: FutureBuilder<bool>(
          future: init(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return Column(children: [
              Expanded(child: renderMainView()),
            ]);
          }),
    );
  }

  renderMainView() {
    if (uid == null) {
      return Center(
        child: Text('채널에 참여해주세여요.'),
      );
    } else {
      return AgoraVideoView(
          controller: VideoViewController(
              rtcEngine: engine!,
              canvas: VideoCanvas(
                uid: 0,
              )));
    }
  }

  renderSubView() {}

  Future<bool> init() async {
    final resp = await [Permission.camera, Permission.microphone].request();

    final cameraPermission = resp[Permission.camera];

    final microphonePermission = resp[Permission.microphone];

    if (cameraPermission != PermissionStatus.granted ||
        microphonePermission != PermissionStatus.granted) {
      throw '카메라 또는 마이크 권한이 없습니다.';
    }

    if (engine == null) {
      engine = createAgoraRtcEngine();

      await engine!.initialize(
        RtcEngineContext(
          appId: APP_ID,
        ),
      );
      await engine!.enableAudio();

      await engine!.startPreview();

      ChannelMediaOptions options = ChannelMediaOptions();

      await engine!.joinChannel(
        token: TOKEN,
        channelId: 'test',
        uid: 0,
        options: options,
      );
      engine!.registerEventHandler(
        RtcEngineEventHandler(
            onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('채널에 입장했습니다. uid: ${connection.localUid}');
          setState(() {
            uid = connection.localUid;
          });
        }, onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('체널 퇴장');
          setState(() {
            uid == null;
          });
        }, onUserJoined:
                (RtcConnection connection, int remoteUid, int elapsed) {
          print('상대가 채널에 입장했습니다. otherUid: $remoteUid}');

          setState(() {
            otherUid = remoteUid;
          });
        }, onUserOffline: (RtcConnection connection, int remoteUid,
                UserOfflineReasonType reason) {
          print('상대가 채널에 나갔습니다. otherUid: $remoteUid}');

          setState(() {
            otherUid = null;
          });
        }),
      );
    }

    return true;
  }
}
