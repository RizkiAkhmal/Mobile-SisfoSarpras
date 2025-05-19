class Peminjaman {
  final int? id;
  final int? idUser;
  final int? idBarang;
  final String? alasanPinjam;
  final int? jumlah;
  final String? tglPinjam;
  final String? tglKembali;
  final String? status;
  final String? namaBarang;

  Peminjaman({
    this.id,
    this.idUser,
    this.idBarang,
    this.alasanPinjam,
    this.jumlah,
    this.tglPinjam,
    this.tglKembali,
    this.status,
    this.namaBarang,
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    String? itemName;
    
    // Try to extract nama_barang from different possible structures
    if (json['barang'] != null && json['barang'] is Map) {
      itemName = json['barang']['nama_barang'];
    } else if (json['nama_barang'] != null) {
      itemName = json['nama_barang'];
    } else if (json['barang_nama'] != null) {
      itemName = json['barang_nama'];
    }
    
    // If still null, use default value
    if (itemName == null || itemName.isEmpty) {
      itemName = 'Barang tidak diketahui';
    }
    
    return Peminjaman(
      id: int.tryParse(json['id'].toString()),
      idUser: int.tryParse(json['id_user'].toString()),
      idBarang: int.tryParse(json['id_barang'].toString()),
      alasanPinjam: json['alasan_pinjam'],
      jumlah: int.tryParse(json['jumlah'].toString()) ?? 0,
      tglPinjam: json['tgl_pinjam'],
      tglKembali: json['tgl_kembali'],
      status: json['status'],
      namaBarang: itemName
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': idUser,
      'id_barang': idBarang,
      'alasan_pinjam': alasanPinjam,
      'jumlah': jumlah,
      'tgl_pinjam': tglPinjam,
      'tgl_kembali': tglKembali,
      'status': status,
      'barang': {'nama_barang': namaBarang},
    };
  }
}
