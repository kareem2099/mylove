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
                  : Image.network(
                MediaUrl,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('Failed to load image'),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Card( // Added Card for details
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: $MediaDate',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Description: $MediaDescription',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
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
  State <VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false; // Track video playback state


  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
      ..initialize().then((_) {
        setState(() {});
      })
      ..addListener(() {
        // Update playback state when video finishes
        if (_controller.value.position == _controller.value.duration) {
          setState(() {
            _isPlaying = false;
          });
        }
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
        ? Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        // Video Controls
        IconButton(
          onPressed: () {
            setState(() {
              _isPlaying = !_isPlaying;
              if (_isPlaying) {
                _controller.play();
              } else {
                _controller.pause();
              }
            });
          },
          icon: Icon(
            _isPlaying ? Icons.pause_circle : Icons.play_circle,
            size: 48,
            color: Colors.white,
          ),
        ),
        // Video Progress Indicator
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.pink,
              bufferedColor: Colors.pinkAccent,
              backgroundColor: Colors.grey,
            ),
          ),
        ),
      ],
    )
        : const Center(
      child: Text('Failed to load video'), // Error message
    );
  }
}
