import 'package:flutter/material.dart';
import 'package:fe_sisfo_sarpas/fetch/model/sisfo_model.dart';
import 'package:fe_sisfo_sarpas/fetch/services/http_sisfo.dart';

class HomePage extends StatelessWidget {
  final HttpSisfo apiService = HttpSisfo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Barang'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: FutureBuilder<List<Barang>>(
        future: apiService.fetchBarang(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            List<Barang> barangList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: barangList.length,
              itemBuilder: (context, index) {
                Barang barang = barangList[index];

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        barang.foto, 
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                      ),
                    ),
                    title: Text(
                      barang.namaBarang,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Kategori: ${barang.kategori.namaKategori}\nJumlah: ${barang.jumlahBarang}',
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Tidak ada data barang.'));
          }
        },
      ),
    );
  }
}
