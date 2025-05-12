class Barang {
  final int id;
  final String namaBarang;
  final int jumlahBarang;
  final int idKategori;
  final String foto; // Tambahan field foto
  final Kategori kategori;

  Barang({
    required this.id,
    required this.namaBarang,
    required this.jumlahBarang,
    required this.idKategori,
    required this.foto,
    required this.kategori,
  });

  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'],
      namaBarang: json['nama_barang'],
      jumlahBarang: json['jumlah_barang'],
      idKategori: json['id_kategori'],
      foto: json['foto'], // Ambil dari JSON
      kategori: Kategori.fromJson(json['kategori']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_barang': namaBarang,
      'jumlah_barang': jumlahBarang,
      'id_kategori': idKategori,
      'foto': foto, // Tambah ke JSON
      'kategori': kategori.toJson(),
    };
  }
}

class Kategori {
  final int id;
  final String namaKategori;

  Kategori({
    required this.id,
    required this.namaKategori,
  });

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      id: json['id'],
      namaKategori: json['nama_kategori'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_kategori': namaKategori,
    };
  }
}
