import 'package:flutter/material.dart';

class PhotoDetailPage extends StatelessWidget {
  final String ImageUrl;
  final String ImageTitle;
  final String ImageDate;
  final String ImageDescription;

  const PhotoDetailPage({super.key,
    required this.ImageUrl,
    required this.ImageTitle,
    required this.ImageDate,
    required this.ImageDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ImageTitle),
      ),
      body: SingleChildScrollView( // Added SingleChildScrollView for better handling of overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: ImageUrl, // Use the same tag as in the grid
              child: Image.network(ImageUrl,loadingBuilder: (context, child, loadingProgress) {
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
             Card(
               margin: const EdgeInsets.symmetric(horizontal: 16),
               child: Padding(
                padding: const EdgeInsets.all(16.0), // Added padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: $ImageDate',
                      style: Theme.of(context).textTheme.headlineMedium, // Added text style
                      maxLines: 2, // Limit lines if text is too long
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                           ),
             ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Added padding
              child: Text(
                'Description: $ImageDescription',
                style: Theme.of(context).textTheme.displayMedium, // Added text style
              ),
            ),
          ],
        ),
      ),
    );
  }
}
