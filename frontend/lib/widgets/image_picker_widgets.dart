import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/utils/image_handler.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Widget pour sélectionner une image unique avec aperçu
class SingleImagePickerWidget extends StatefulWidget {
  final Function(String base64Image) onImageSelected;
  final String? initialImage;
  final String label;
  final double maxWidth;
  final double maxHeight;

  const SingleImagePickerWidget({
    Key? key,
    required this.onImageSelected,
    this.initialImage,
    this.label = 'Ajouter une photo',
    this.maxWidth = 400,
    this.maxHeight = 300,
  }) : super(key: key);

  @override
  State<SingleImagePickerWidget> createState() => _SingleImagePickerWidgetState();
}

class _SingleImagePickerWidgetState extends State<SingleImagePickerWidget> {
  String? selectedImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedImage = widget.initialImage;
  }

  Uint8List? _decodeBase64Image(String base64String) {
    try {
      String cleanBase64 = base64String;
      if (base64String.startsWith('data:')) {
        // Extraire le base64 après la virgule: data:image/jpeg;base64,...
        cleanBase64 = base64String.split(',').last;
      }
      return base64Decode(cleanBase64);
    } catch (e) {
      print('Erreur décodage image: $e');
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => isLoading = true);
    try {
      final base64 = await ImageHandler.pickImageAsBase64(
        source: source,
        maxWidthDp: widget.maxWidth.toInt(),
        maxHeightDp: widget.maxHeight.toInt(),
      );
      if (base64 != null) {
        setState(() => selectedImage = base64);
        widget.onImageSelected(base64);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearImage() {
    setState(() => selectedImage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (selectedImage != null)
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _decodeBase64Image(selectedImage!) != null
                      ? Image.memory(
                          _decodeBase64Image(selectedImage!)!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.error_outline, color: Colors.red[400]),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.error_outline, color: Colors.red[400]),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _clearImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.grey[50],
            ),
            child: Center(
              child: Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.image),
                label: const Text('Galerie'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget pour sélectionner plusieurs images avec aperçu
class MultiImagePickerWidget extends StatefulWidget {
  final Function(List<String> base64Images) onImagesSelected;
  final List<String> initialImages;
  final String label;
  final int maxImages;
  final double maxWidth;
  final double maxHeight;

  const MultiImagePickerWidget({
    Key? key,
    required this.onImagesSelected,
    this.initialImages = const [],
    this.label = 'Ajouter des photos (max 3)',
    this.maxImages = 3,
    this.maxWidth = 400,
    this.maxHeight = 300,
  }) : super(key: key);

  @override
  State<MultiImagePickerWidget> createState() => _MultiImagePickerWidgetState();
}

class _MultiImagePickerWidgetState extends State<MultiImagePickerWidget> {
  late List<String> selectedImages;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedImages = List.from(widget.initialImages);
  }

  Uint8List? _decodeBase64Image(String base64String) {
    try {
      String cleanBase64 = base64String;
      if (base64String.startsWith('data:')) {
        // Extraire le base64 après la virgule: data:image/jpeg;base64,...
        cleanBase64 = base64String.split(',').last;
      }
      return base64Decode(cleanBase64);
    } catch (e) {
      print('Erreur décodage image: $e');
      return null;
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    if (selectedImages.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxImages} images autorisées')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final base64List = await ImageHandler.pickMultipleImagesAsBase64(
        source: source,
        maxImages: widget.maxImages - selectedImages.length,
        maxWidthDp: widget.maxWidth.toInt(),
        maxHeightDp: widget.maxHeight.toInt(),
      );
      if (base64List.isNotEmpty) {
        setState(() {
          selectedImages.addAll(base64List);
          if (selectedImages.length > widget.maxImages) {
            selectedImages = selectedImages.sublist(0, widget.maxImages);
          }
        });
        widget.onImagesSelected(selectedImages);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _removeImage(int index) {
    setState(() => selectedImages.removeAt(index));
    widget.onImagesSelected(selectedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label} (${selectedImages.length}/${widget.maxImages})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (selectedImages.isEmpty)
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.grey[50],
            ),
            child: Center(
              child: Icon(Icons.image_not_supported_outlined, 
                size: 48, 
                color: Colors.grey[400]
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: selectedImages.length,
            itemBuilder: (context, index) {
              final imageBytes = _decodeBase64Image(selectedImages[index]);
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.error_outline, color: Colors.red[400]),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.error_outline, color: Colors.red[400]),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        onTap: () => _removeImage(index),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        if (selectedImages.length < widget.maxImages)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () => _pickImages(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text('Galerie'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () => _pickImages(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Caméra'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
