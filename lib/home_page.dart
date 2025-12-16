import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart';

// Inisialisasi Supabase Client
final supabase = Supabase.instance.client;

// Nama bucket untuk penyimpanan gambar
const String kImageBucket = 'Supabase Foto';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  // Pilih Gambar dari Galeri
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null; // Reset URL saat gambar baru dipilih
      });
    }
  }

  // Upload Gambar ke Supabase Storage
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context as BuildContext).showSnackBar(
            const SnackBar(
              content: Text('Error: User tidak login. Silakan login.'),
            ),
          );
        }
        return;
      }

      // Buat path unik untuk file yang diupload
      final fileExtension = extension(_imageFile!.path);
      final uploadPath =
          '$userId/${DateTime.now().microsecondsSinceEpoch}$fileExtension';

      // Upload file ke Supabase Storage
      await supabase.storage
          .from(kImageBucket)
          .upload(
            uploadPath,
            _imageFile!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Dapatkan public URL dari file yang diupload
      final publicUrl = supabase.storage
          .from(kImageBucket)
          .getPublicUrl(uploadPath);

      setState(() {
        _imageUrl = publicUrl;
        // Hapus referensi file lokal agar tampilan beralih ke Image.network
        _imageFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context as BuildContext,
        ).showSnackBar(const SnackBar(content: Text('Upload berhasil!')));
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context as BuildContext,
        ).showSnackBar(SnackBar(content: Text('Error Storage: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context as BuildContext,
        ).showSnackBar(SnackBar(content: Text('Terjadi error umum: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //Gabungkan Pemilihan dan Upload Gambar
  Future<void> _pickAndUploadImage() async {
    // Mulai loading
    setState(() {
      _isLoading = true;
    });

    await _pickImage();

    // Jika gambar terpilih, lanjutkan upload
    if (_imageFile != null) {
      // Fungsi _uploadImage akan mengatur _isLoading menjadi false di akhirnya
      await _uploadImage();
    } else {
      // Jika tidak ada gambar yang dipilih, hentikan loading
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 50),

                const Text(
                  'Upload ke Public Bucket',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                ),

                const SizedBox(height: 50),

                // Tombol "Pilih & Upload Gambar"
                ElevatedButton(
                  onPressed: _isLoading ? null : _pickAndUploadImage,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.purple.shade50,
                    foregroundColor: Colors.purple.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.purple,
                          ),
                        )
                      : const Text(
                          'Pilih & Upload Gambar',
                          style: TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 50),

                // Label "Gambar dari Public URL:"
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Gambar dari Public URL:',
                    style: TextStyle(fontSize: 14),
                  ),
                ),

                const SizedBox(height: 10),

                // Tampilkan Gambar atau Placeholder
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    color: Colors.white,
                  ),
                  child: _isLoading && _imageFile != null
                      ? const Center(child: CircularProgressIndicator())
                      : _imageUrl != null && _imageUrl!.isNotEmpty
                      ? Image.network(
                          _imageUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('Gagal memuat gambar dari URL.'),
                            );
                          },
                        )
                      : (_imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.contain)
                            : const Center(
                                child: Text(
                                  'URL Gambar akan ditampilkan di sini.',
                                ),
                              )),
                ),

                const SizedBox(height: 20),

                // Tampilkan URL Gambar jika ada
                if (_imageUrl != null && _imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: SelectableText(
                      _imageUrl!,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 50),

                // Info Bucket 
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Buckets',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('Supabase Foto'), Text('Public')],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
