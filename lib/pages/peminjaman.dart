import 'package:fe_sisfo_sarpas/fetch/model/sisfo_model.dart';
import 'package:fe_sisfo_sarpas/fetch/services/http_sisfo.dart';
import 'package:fe_sisfo_sarpas/fetch/services/peminjaman_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PeminjamanForm extends StatefulWidget {
  const PeminjamanForm({Key? key}) : super(key: key);

  @override
  State<PeminjamanForm> createState() => _PeminjamanFormState();
}

class _PeminjamanFormState extends State<PeminjamanForm> {
  final _formKey = GlobalKey<FormState>();
  // final _namaController = TextEditingController();
  final _alasanController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _tglPinjamController = TextEditingController();
  final _tglKembaliController = TextEditingController();

  final _dateFormat = DateFormat('yyyy-MM-dd');
  List<Barang> _listBarang = [];
  Barang? _selectedBarang;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    fetchBarang();
  }

  Future<void> fetchBarang() async {
    final barangService = HttpSisfo();
    final barangList = await barangService.fetchBarang();
    setState(() {
      _listBarang = barangList;
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = _dateFormat.format(picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedBarang == null) return;

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final idUser = prefs.getInt('id_user');

    if (token == null || idUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login terlebih dahulu.')),
      );
      return;
    }

    try {
      await PeminjamanService.createPeminjaman(
        token: token,
        idUser: idUser,
        idBarang: _selectedBarang!.id,
        // namaPeminjam: _namaController.text,
        alasanPinjam: _alasanController.text,
        jumlah: int.parse(_jumlahController.text),
        tglPinjam: _tglPinjamController.text,
        tglKembali: _tglKembaliController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Peminjaman berhasil ditambahkan!')),
      );
      _formKey.currentState!.reset();
      _tglPinjamController.clear();
      _tglKembaliController.clear();
      setState(() => _selectedBarang = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    // _namaController.dispose();
    _alasanController.dispose();
    _jumlahController.dispose();
    _tglPinjamController.dispose();
    _tglKembaliController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form Peminjaman')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // TextFormField(
                    //   controller: _namaController,
                    //   decoration: InputDecoration(labelText: 'Nama Peminjam'),
                    //   validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    // ),
                    TextFormField(
                      controller: _alasanController,
                      decoration: InputDecoration(labelText: 'Alasan Pinjam'),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: _jumlahController,
                      decoration: InputDecoration(labelText: 'Jumlah'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: _tglPinjamController,
                      readOnly: true,
                      onTap: () => _selectDate(context, _tglPinjamController),
                      decoration: InputDecoration(
                        labelText: 'Tanggal Pinjam',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: _tglKembaliController,
                      readOnly: true,
                      onTap: () => _selectDate(context, _tglKembaliController),
                      decoration: InputDecoration(
                        labelText: 'Tanggal Kembali',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    DropdownButtonFormField<Barang>(
                      value: _selectedBarang,
                      items: _listBarang.map((barang) {
                        return DropdownMenuItem<Barang>(
                          value: barang,
                          child: Text(barang.namaBarang),
                        );
                      }).toList(),
                      onChanged: (barang) {
                        setState(() {
                          _selectedBarang = barang;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Pilih Barang'),
                      validator: (value) => value == null ? 'Pilih barang' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Kirim'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
