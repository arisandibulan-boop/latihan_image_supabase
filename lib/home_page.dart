import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  String? uploadedImageUrl;
  bool isLoading = false;

  Future<void> _handleUpload() async {
    try {
      // 1. Pilih gambar dari galeri
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => isLoading = true);

      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      // 2. Upload ke Supabase Storage
      await supabase.storage
          .from('bucket_images')
          .upload('uploads/$fileName', file);

      // 3. Dapatkan public URL
      final publicUrl = supabase.storage
          .from('bucket_images')
          .getPublicUrl('uploads/$fileName');

      setState(() {
        uploadedImageUrl = publicUrl;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Upload error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Upload ke Public Bucket',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Tombol untuk memilih dan mengupload gambar
            OutlinedButton(
              onPressed: isLoading ? null : _handleUpload,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                side: BorderSide(color: Colors.purple.shade100),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      'Pilih & Upload Gambar',
                      style: TextStyle(
                        color: Colors.purple.shade300,
                        fontSize: 16,
                      ),
                    ),
            ),

            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.center,
              child: Text(
                'Gambar dari Public URL:',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // Tampilkan URL gambar yang sudah diupload
            if (uploadedImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SelectableText(
                  uploadedImageUrl!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
