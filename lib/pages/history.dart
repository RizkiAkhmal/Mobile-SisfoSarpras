import 'package:flutter/material.dart';
import 'package:fe_sisfo_sarpas/fetch/model/peminjaman_model.dart';
import 'package:fe_sisfo_sarpas/fetch/services/peminjaman_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PeminjamanHistoryPage extends StatefulWidget {
  const PeminjamanHistoryPage({super.key});

  @override
  State<PeminjamanHistoryPage> createState() => _PeminjamanHistoryPageState();
}

class _PeminjamanHistoryPageState extends State<PeminjamanHistoryPage> {
  late Future<List<Peminjaman>> _peminjamanFuture;

  @override
  void initState() {
    super.initState();
    _loadPeminjaman();
  }

  Future<void> _loadPeminjaman() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan. Silakan login kembali.')),
      );
      return;
    }

    setState(() {
      _peminjamanFuture = PeminjamanService.fetchPeminjamanUser(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Peminjaman')),
      body: FutureBuilder<List<Peminjaman>>(
        future: _peminjamanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data peminjaman.'));
          }

          final peminjamanList = snapshot.data!;

          return ListView.builder(
            itemCount: peminjamanList.length,
            itemBuilder: (context, index) {
              final peminjaman = peminjamanList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(peminjaman.namaBarang ?? 'Barang tidak diketahui'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alasan: ${peminjaman.alasanPinjam}'),
                      Text('Jumlah: ${peminjaman.jumlah}'),
                      Text('Pinjam: ${peminjaman.tglPinjam}'),
                      Text('Kembali: ${peminjaman.tglKembali}'),
                      Text('Status: ${peminjaman.status ?? 'Tidak diketahui'}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
