import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe_sisfo_sarpas/fetch/model/sisfo_model.dart';
import 'package:fe_sisfo_sarpas/fetch/services/http_sisfo.dart';
import 'package:fe_sisfo_sarpas/fetch/services/peminjaman_service.dart';

class PeminjamanForm extends StatefulWidget {
  const PeminjamanForm({Key? key}) : super(key: key);

  @override
  State<PeminjamanForm> createState() => _PeminjamanFormState();
}

class _PeminjamanFormState extends State<PeminjamanForm> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _tglPinjamController = TextEditingController();
  final _tglKembaliController = TextEditingController();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  List<Barang> _listBarang = [];
  Barang? _selectedBarang;
  bool _loading = false;
  
  // Add this line to define _barangFuture
  late Future<List<Barang>> _barangFuture;

  @override
  void initState() {
    super.initState();
    _barangFuture = fetchBarang();
    // Set tanggal pinjam ke hari ini
    _tglPinjamController.text = _dateFormat.format(DateTime.now());
  }

  Future<List<Barang>> fetchBarang() async {
    final barangService = HttpSisfo();
    final barangList = await barangService.fetchBarang();
    setState(() {
      _listBarang = barangList;
    });
    return barangList;
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    // Only allow date selection for return date
    if (controller != _tglPinjamController) {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(), // Start from today
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        controller.text = _dateFormat.format(picked);
      }
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
    _alasanController.dispose();
    _jumlahController.dispose();
    _tglPinjamController.dispose();
    _tglKembaliController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Peminjaman', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
          setState(() {
            _barangFuture = fetchBarang();
          });
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form content
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Peminjaman',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Dropdown untuk memilih barang
                          FutureBuilder<List<Barang>>(
                            future: _barangFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Text('Tidak ada data barang tersedia');
                              }
                              
                              return DropdownButtonFormField<Barang>(
                                decoration: InputDecoration(
                                  labelText: 'Pilih Barang',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(Icons.inventory),
                                ),
                                value: _selectedBarang,
                                items: snapshot.data!.map((barang) {
                                  return DropdownMenuItem<Barang>(
                                    value: barang,
                                    child: Text('${barang.namaBarang} (Stock: ${barang.jumlahBarang})'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBarang = value;
                                  });
                                },
                                validator: (value) => value == null ? 'Pilih barang terlebih dahulu' : null,
                              );
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Jumlah barang yang dipinjam
                          TextFormField(
                            controller: _jumlahController,
                            decoration: InputDecoration(
                              labelText: 'Jumlah',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Jumlah harus diisi';
                              }
                              final jumlah = int.tryParse(value);
                              if (jumlah == null) {
                                return 'Jumlah harus berupa angka';
                              }
                              if (jumlah <= 0) {
                                return 'Jumlah harus lebih dari 0';
                              }
                              if (_selectedBarang != null && jumlah > _selectedBarang!.jumlahBarang) {
                                return 'Jumlah melebihi stok yang tersedia';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Alasan peminjaman
                          TextFormField(
                            controller: _alasanController,
                            decoration: InputDecoration(
                              labelText: 'Alasan Peminjaman',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Alasan peminjaman harus diisi';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Tanggal peminjaman
                          TextFormField(
                            controller: _tglPinjamController,
                            decoration: InputDecoration(
                              labelText: 'Tanggal Pinjam',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.calendar_today),
                              filled: true,
                              fillColor: Colors.white,
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                              ),
                            ),
                            readOnly: true, // Make it read-only
                            enabled: false, // Disable the field completely
                            style: TextStyle(color: Colors.black), // Keep text color the same
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tanggal pinjam harus diisi';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          
                          // Tanggal pengembalian
                          TextFormField(
                            controller: _tglKembaliController,
                            decoration: InputDecoration(
                              labelText: 'Tanggal Kembali',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.event_available),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context, _tglKembaliController),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Tanggal kembali harus diisi';
                              }
                              
                              // Validasi tanggal kembali harus setelah tanggal pinjam
                              if (_tglPinjamController.text.isNotEmpty) {
                                final pinjam = _parseDate(_tglPinjamController.text);
                                final kembali = _parseDate(value);
                                if (kembali.isBefore(pinjam)) {
                                  return 'Tanggal kembali harus setelah tanggal pinjam';
                                }
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),
                          
                          // Tombol submit
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _loading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'Ajukan Peminjaman',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Add extra space at bottom for better scrolling
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime _parseDate(String date) {
    final parts = date.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
