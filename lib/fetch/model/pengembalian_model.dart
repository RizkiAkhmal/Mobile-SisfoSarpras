import 'package:fe_sisfo_sarpas/fetch/model/peminjaman_model.dart';

class Pengembalian {
  final int? id;
  final int? idPeminjaman;
  final String? namaPengembali;
  final String? tglKembali;
  final int? jumlahKembali;
  final String? kondisi;
  final double? biayaDenda;
  final String? status;
  final Map<String, dynamic>? peminjaman;
  
  Pengembalian({
    this.id,
    this.idPeminjaman,
    this.namaPengembali,
    this.tglKembali,
    this.jumlahKembali,
    this.kondisi,
    this.biayaDenda,
    this.status,
    this.peminjaman,
  });
  
  factory Pengembalian.fromJson(Map<String, dynamic> json) {
    return Pengembalian(
      id: int.tryParse(json['id'].toString()),
      idPeminjaman: int.tryParse(json['id_peminjaman'].toString()),
      namaPengembali: json['nama_pengembali'],
      tglKembali: json['tgl_kembali'],
      jumlahKembali: int.tryParse(json['jumlah_kembali'].toString()) ?? 0,
      kondisi: json['kondisi'],
      biayaDenda: double.tryParse(json['biaya_denda'].toString()) ?? 0.0,
      status: json['status'],
      peminjaman: json['peminjaman'] as Map<String, dynamic>?,
      
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_peminjaman': idPeminjaman,
      'nama_pengembali': namaPengembali,
      'tgl_kembali': tglKembali,
      'jumlah_kembali': jumlahKembali,
      'kondisi': kondisi,
      'biaya_denda': biayaDenda,
      'status': status,
      'peminjaman': peminjaman,

    };
  }
} 