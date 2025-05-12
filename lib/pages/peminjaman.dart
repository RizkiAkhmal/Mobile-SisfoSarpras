import 'package:fe_sisfo_sarpas/fetch/model/peminjaman_model.dart';
import 'package:fe_sisfo_sarpas/fetch/services/peminjaman_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'Peminjaman.dart';

class PeminjamanFormPage extends StatefulWidget {
  const PeminjamanFormPage({Key? key}) : super(key: key);

  @override
  State<PeminjamanFormPage> createState() => _PeminjamanFormPageState();
}

class _PeminjamanFormPageState extends State<PeminjamanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = PeminjamanApiService();

  final TextEditingController _idUserController = TextEditingController();
  final TextEditingController _idBarangController = TextEditingController();
  final TextEditingController _namaPeminjamController = TextEditingController();
  final TextEditingController _alasanPinjamController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _tglPinjamController = TextEditingController();
  final TextEditingController _tglKembaliController = TextEditingController();

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime.now()) {
      // Format the selected date into YYYY-MM-DD format
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      controller.text = formattedDate; // Set the formatted date to the controller
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final peminjaman = Peminjaman(
        idUser: int.parse(_idUserController.text),
        idBarang: int.parse(_idBarangController.text),
        namaPeminjam: _namaPeminjamController.text,
        alasanPinjam: _alasanPinjamController.text,
        jumlah: int.parse(_jumlahController.text),
        tglPinjam: _tglPinjamController.text,
        tglKembali: _tglKembaliController.text,
      );

      final success = await _apiService.createPeminjaman(peminjaman);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Berhasil meminjam' : 'Gagal meminjam'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Peminjaman")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idUserController,
                decoration: const InputDecoration(labelText: "ID User"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'ID User tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _idBarangController,
                decoration: const InputDecoration(labelText: "ID Barang"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'ID Barang tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _namaPeminjamController,
                decoration: const InputDecoration(labelText: "Nama Peminjam"),
                validator: (value) =>
                    value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _alasanPinjamController,
                decoration: const InputDecoration(labelText: "Alasan Pinjam"),
                validator: (value) =>
                    value!.isEmpty ? 'Alasan tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _jumlahController,
                decoration: const InputDecoration(labelText: "Jumlah"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
              ),
              // Date picker for tglPinjam
              TextFormField(
                controller: _tglPinjamController,
                decoration: const InputDecoration(labelText: "Tanggal Pinjam"),
                readOnly: true, // Make it read-only to prevent text input
                onTap: () => _selectDate(context, _tglPinjamController), // Show date picker on tap
                validator: (value) =>
                    value!.isEmpty ? 'Tanggal pinjam tidak boleh kosong' : null,
              ),
              // Date picker for tglKembali
              TextFormField(
                controller: _tglKembaliController,
                decoration: const InputDecoration(labelText: "Tanggal Kembali"),
                readOnly: true, // Make it read-only to prevent text input
                onTap: () => _selectDate(context, _tglKembaliController), // Show date picker on tap
                validator: (value) =>
                    value!.isEmpty ? 'Tanggal kembali tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Kirim"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
