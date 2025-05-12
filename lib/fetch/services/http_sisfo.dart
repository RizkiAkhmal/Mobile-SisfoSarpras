
import 'dart:convert';
import 'package:fe_sisfo_sarpas/fetch/model/sisfo_model.dart';
import 'package:http/http.dart' as http;


class HttpSisfo {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/fe';

  // Fungsi untuk mengambil data barang
  Future<List<Barang>> fetchBarang() async {
  final response = await http.get(Uri.parse('$_baseUrl/barang'));

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);

    // Ambil data dari field "data"
    List<dynamic> data = responseData['data'];

    return data.map((item) => Barang.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load barang');
  }
}

}