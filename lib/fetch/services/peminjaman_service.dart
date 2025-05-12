import 'dart:convert';
import 'package:fe_sisfo_sarpas/fetch/model/peminjaman_model.dart';
import 'package:http/http.dart' as http;


class PeminjamanApiService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Future<bool> createPeminjaman(Peminjaman peminjaman) async {
    final url = Uri.parse("$baseUrl/peminjaman");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(peminjaman.toJson()),
    );

    if (response.statusCode == 201) {
      print("✅ Berhasil tambah peminjaman");
      return true;
    } else {
      print("❌ Gagal: ${response.body}");
      return false;
    }
  }
}
