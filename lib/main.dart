import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

final String supabaseUrl = 'https://mtjpgthpfealtbupwgfm.supabase.co';
final String supabaseKey = 'sb_publishable_O2hXXaFf9Pv62u4oBUZnWg_AXLSiY7vD';

final SupabaseClient supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase Foto',
      home: HomePage(),
    );
  }
}
