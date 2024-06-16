import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaDetailPage extends StatelessWidget {
  final String MediaUrl;
  final String MediaTitle;
  final String MediaDate;
  final String MediaDescription;
  final bool isVideo;

  const MediaDetailPage({
    super.key,
    required this.MediaUrl,
    required this.MediaTitle,
    required this.MediaDate,
    required this.MediaDescription,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(MediaTitle),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: MediaUrl,
              child: isVideo
                  ? VideoPlayerWidget(mediaUrl: MediaUrl)
                  : Image.network(MediaUrl),
            ),
            const SizedBox(height: 16),
            Text('Date: $MediaDate'),
            const SizedBox(height: 8),
            Text('Description: $MediaDescription'),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String mediaUrl;

  const VideoPlayerWidget({super.key, required this.mediaUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : const Center(child: CircularProgressIndicator());
  }
}
