import 'dart:convert';
import 'dart:io';
import 'package:fe_sisfo_sarpas/fetch/model/peminjaman_model.dart';
import 'package:fe_sisfo_sarpas/fetch/model/pengembalian_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PengembalianService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Get the base URL based on platform
  static String getBaseUrl() {
    if (kIsWeb) {
      // For web deployment, use relative URL
      return '/api';
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // For Android emulator, use 10.0.2.2 to access host machine
      return 'http://127.0.0.1:8000/api';
    } else {
      // Default URL
      return baseUrl;
    }
  }

  static Future<bool> createPengembalian({
    required String token,
    required int idPeminjaman,
    required String namaPengembali,
    required String tglKembali,
    required int jumlahKembali,
    required String kondisi,
    required String status,
    double? biayaDenda,
  }) async {
    final url = Uri.parse('$baseUrl/pengembalian');
    
    final data = {
      'id_peminjaman': idPeminjaman,
      'nama_pengembali': namaPengembali,
      'tgl_kembali': tglKembali,
      'jumlah_kembali': jumlahKembali,
      'kondisi': kondisi,
      'status': status,
      'biaya_denda': biayaDenda ?? 0,
    };
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Respon berhasil, jika perlu bisa memparsing data tambahan dari server
      return true;
    } else {
      print('Gagal kirim: ${response.body}');
      return false;
    }
  }

  // Fetch all peminjaman that can be returned (status = approved)
  static Future<List<Peminjaman>> fetchPeminjamanForReturn(String token) async {
    final url = Uri.parse('$baseUrl/peminjaman');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        
        // Filter only peminjaman with status "approved"
        final List filteredData = data.where((item) => item['status'] == 'approved').toList();
        
        // Process each item to ensure barang data is properly handled
        for (var item in filteredData) {
          if (item['barang'] == null || item['barang']['nama_barang'] == null) {
            // If barang data is missing, add a placeholder
            item['barang'] = {'nama_barang': 'Barang tidak diketahui'};
          }
        }
        
        return filteredData.map((json) => Peminjaman.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mengambil data peminjaman: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Get all pengembalian records
  static Future<List<Pengembalian>> getAllPengembalian(String token) async {
    final url = Uri.parse('${getBaseUrl()}/pengembalian/index');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => Pengembalian.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mengambil data pengembalian: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Get a specific pengembalian record by ID
  static Future<Pengembalian> getPengembalianById(String token, int id) async {
    final url = Uri.parse('${getBaseUrl()}/pengembalian/$id');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Pengembalian.fromJson(responseData['data']);
      } else {
        throw Exception('Gagal mengambil detail pengembalian: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
} 