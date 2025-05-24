// lib/Views/pick_and_upload_image.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Let the user pick an image, upload it to Supabase Storage,
/// and return the public URL (or null on failure).
Future<String?> pickAndUploadImage() async {
  final picker = ImagePicker();
  final XFile? xfile = await picker.pickImage(source: ImageSource.gallery);
  if (xfile == null) {
    debugPrint('📷 User canceled image picker');
    return null;
  }

  debugPrint('✅ Image selected: ${xfile.name}');

  Uint8List fileBytes;
  try {
    fileBytes = await xfile.readAsBytes();
  } catch (e) {
    debugPrint('❌ Failed to read file bytes: $e');
    return null;
  }

  final ext = p.extension(xfile.path);
  final fileName = '${const Uuid().v4()}$ext';
  final storagePath = 'products/$fileName';

  final storage = Supabase.instance.client.storage.from('product-images');

  try {
    await storage.uploadBinary(
      storagePath,
      fileBytes,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
      ),
    );
    debugPrint('✅ Uploaded to Supabase Storage: $storagePath');
  } catch (e) {
    debugPrint('❌ Supabase upload error: $e');
    return null;
  }

  try {
    final urlOrResponse = storage.getPublicUrl(storagePath);
    debugPrint('🔗 Public URL result: $urlOrResponse');
    if (urlOrResponse is String) return urlOrResponse;
    final dataField = (urlOrResponse as dynamic).data;
    if (dataField is String) return dataField;
    return urlOrResponse.toString();
  } catch (e) {
    debugPrint('❌ Failed to get public URL: $e');
    return null;
  }
}
