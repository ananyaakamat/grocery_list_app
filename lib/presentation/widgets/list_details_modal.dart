import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ListDetailsModal extends StatefulWidget {
  final String initialDescription;
  final String initialUrl;
  final Function(String description, String url) onSave;

  const ListDetailsModal({
    super.key,
    required this.initialDescription,
    required this.initialUrl,
    required this.onSave,
  });

  @override
  State<ListDetailsModal> createState() => _ListDetailsModalState();
}

class _ListDetailsModalState extends State<ListDetailsModal> {
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _urlController = TextEditingController(text: widget.initialUrl);
    _isEditMode =
        widget.initialDescription.isEmpty && widget.initialUrl.isEmpty;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  /// Cleans URL by removing whitespace, newlines, and other unwanted characters
  String _cleanUrl(String url) {
    return url
        .trim() // Remove leading/trailing spaces
        .replaceAll('\n', '') // Remove newlines
        .replaceAll('\r', '') // Remove carriage returns
        .replaceAll(' ', ''); // Remove any remaining spaces
  }

  Future<void> _launchUrl(String url) async {
    // Clean the URL thoroughly
    url = _cleanUrl(url);

    // Check if URL is empty after cleaning
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL is empty')),
        );
      }
      return;
    }

    // Add protocol if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      final Uri uri = Uri.parse(url);

      // Force external application to handle YouTube links properly
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid URL format: $url\nError: $e')),
        );
      }
    }
  }

  Widget _buildDisplayMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Recipe Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit details',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Description section
        if (_descriptionController.text.isNotEmpty) ...[
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              _descriptionController.text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // URL section
        if (_urlController.text.isNotEmpty) ...[
          Text(
            'Website',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _launchUrl(_urlController.text),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _urlController.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],

        // Empty state
        if (_descriptionController.text.isEmpty &&
            _urlController.text.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No details added yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a description or website URL to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (_descriptionController.text.isEmpty &&
                _urlController.text.isEmpty) ...[
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditMode = true;
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Details'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Edit Recipe Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Description field
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _descriptionController,
                maxLength: 60,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter a brief description...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                _descriptionController.clear();
              },
              icon: const Icon(Icons.clear),
              tooltip: 'Clear description',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // URL field
        Text(
          'Website URL',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _urlController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Enter website URL...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                _urlController.clear();
              },
              icon: const Icon(Icons.clear),
              tooltip: 'Clear URL',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                if (widget.initialDescription.isEmpty &&
                    widget.initialUrl.isEmpty) {
                  Navigator.of(context).pop();
                } else {
                  setState(() {
                    _descriptionController.text = widget.initialDescription;
                    _urlController.text = widget.initialUrl;
                    _isEditMode = false;
                  });
                }
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                widget.onSave(
                  _descriptionController.text.trim(),
                  _cleanUrl(_urlController.text),
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: _isEditMode ? _buildEditMode() : _buildDisplayMode(),
        ),
      ),
    );
  }
}
