import 'dart:convert';
import 'package:fe_sisfo_sarpas/fetch/model/peminjaman_model.dart';
import 'package:http/http.dart' as http;

class PeminjamanService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  /// Membuat peminjaman baru
  static Future<void> createPeminjaman({
    required String token,
    required int idUser,
    required int idBarang,
    // required String namaPeminjam,
    required String alasanPinjam,
    required int jumlah,
    required String tglPinjam,
    required String tglKembali,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/peminjaman'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_user': idUser,
        'id_barang': idBarang,
        // 'nama_peminjam': namaPeminjam,
        'alasan_pinjam': alasanPinjam,
        'jumlah': jumlah,
        'tgl_pinjam': tglPinjam,
        'tgl_kembali': tglKembali,
        'status': 'pending', // default status
      }),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      print('❌ Gagal create: ${response.body}');
      throw Exception(body['message'] ?? 'Gagal membuat peminjaman');
    } else {
      print('✅ Berhasil create peminjaman');
    }
  }

  /// Mengambil riwayat peminjaman user yang login
  static Future<List<Peminjaman>> fetchPeminjamanUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/peminjaman/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body)['data'];
      return jsonData.map((e) => Peminjaman.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data peminjaman user: ${response.body}');
    }
  }
}
