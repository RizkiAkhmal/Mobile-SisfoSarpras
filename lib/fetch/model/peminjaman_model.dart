class Peminjaman {
  final int idUser;
  final int idBarang;
  final String namaPeminjam;
  final String alasanPinjam;
  final int jumlah;
  final String tglPinjam;
  final String tglKembali;


  Peminjaman({
    required this.idUser,
    required this.idBarang,
    required this.namaPeminjam,
    required this.alasanPinjam,
    required this.jumlah,
    required this.tglPinjam,
    required this.tglKembali,
  });

  Map<String, dynamic> toJson() {
    return {
      "id_user": idUser,
      "id_barang": idBarang,
      "nama_peminjam": namaPeminjam,
      "alasan_pinjam": alasanPinjam,
      "jumlah": jumlah,
      "tgl_pinjam": tglPinjam,
      "tgl_kembali": tglKembali,
    };
  }
}
