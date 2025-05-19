import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fe_sisfo_sarpas/fetch/model/peminjaman_model.dart';
import 'package:fe_sisfo_sarpas/fetch/services/pengembalian_service.dart';

class PengembalianForm extends StatefulWidget {
  const PengembalianForm({Key? key}) : super(key: key);

  @override
  State<PengembalianForm> createState() => _PengembalianFormState();
}

class _PengembalianFormState extends State<PengembalianForm> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _tglKembaliController = TextEditingController();
  final _jumlahKembaliController = TextEditingController();
  final _kondisiController = TextEditingController();
  String _selectedStatus = 'pending';

  final List<String> _kondisiOptions = ['Baik', 'Rusak', 'Hilang'];

  final _dateFormat = DateFormat('yyyy-MM-dd');
  List<Peminjaman> _listPeminjaman = [];
  Peminjaman? _selectedPeminjaman;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _tglKembaliController.text = _dateFormat.format(DateTime.now());
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final peminjamans = await PengembalianService.fetchPeminjamanForReturn(token);

      setState(() {
        _listPeminjaman = peminjamans;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
      _showSnackBar('Gagal memuat data: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _tglKembaliController.text = _dateFormat.format(picked);
      });
    }
  }

  void _updateJumlahKembali() {
    if (_selectedPeminjaman != null) {
      _jumlahKembaliController.text = (_selectedPeminjaman!.jumlah ?? 0).toString();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedPeminjaman == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final success = await PengembalianService.createPengembalian(
        token: token,
        idPeminjaman: _selectedPeminjaman!.id!,
        namaPengembali: _namaController.text,
        tglKembali: _tglKembaliController.text,
        jumlahKembali: int.parse(_jumlahKembaliController.text),
        kondisi: _kondisiController.text,
        status: _selectedStatus,
        biayaDenda: null, // Dihilangkan dari input form
      );

      setState(() {
        _loading = false;
      });

      if (success) {
        _showSnackBar('Pengembalian berhasil disimpan');
        _resetForm();
        _loadData();
      } else {
        _showSnackBar('Gagal mengirim pengembalian', isError: true);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedPeminjaman = null;
    });
    _formKey.currentState?.reset();
    _namaController.clear();
    _tglKembaliController.text = _dateFormat.format(DateTime.now());
    _jumlahKembaliController.clear();
    _kondisiController.clear();
    _selectedStatus = 'pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Pengembalian'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildForm(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Terjadi kesalahan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeminjamanSelector(),
            SizedBox(height: 16),
            _buildPengembalianForm(),
            SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeminjamanSelector() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Peminjaman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<Peminjaman>(
              decoration: InputDecoration(
                labelText: 'Pilih Peminjaman',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              value: _selectedPeminjaman,
              items: _listPeminjaman.map((peminjaman) {
                return DropdownMenuItem<Peminjaman>(
                  value: peminjaman,
                  child: Text('${peminjaman.namaBarang} (${peminjaman.jumlah} unit)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeminjaman = value;
                  _updateJumlahKembali();
                });
              },
              validator: (value) => value == null ? 'Peminjaman harus dipilih' : null,
              isExpanded: true,
            ),
            if (_selectedPeminjaman != null) ...[
              SizedBox(height: 16),
              _buildPeminjamanDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeminjamanDetails() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Nama Barang', _selectedPeminjaman!.namaBarang ?? '-'),
          _buildDetailRow('Jumlah Dipinjam', '${_selectedPeminjaman!.jumlah}'),
          _buildDetailRow('Tanggal Pinjam', _selectedPeminjaman!.tglPinjam ?? '-'),
          _buildDetailRow('Tanggal Kembali', _tglKembaliController.text),
          _buildDetailRow('Alasan Peminjaman', _selectedPeminjaman!.alasanPinjam ?? '-'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPengembalianForm() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Pengembalian',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _namaController,
              decoration: InputDecoration(
                labelText: 'Nama Pengembali',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Nama pengembali harus diisi' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _tglKembaliController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Tanggal Kembali',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () => _selectDate(context),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Tanggal kembali harus diisi' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _jumlahKembaliController,
              decoration: InputDecoration(
                labelText: 'Jumlah Kembali',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Jumlah kembali harus diisi';
                final jumlah = int.tryParse(value);
                if (jumlah == null) return 'Jumlah harus berupa angka';
                if (jumlah <= 0) return 'Jumlah harus lebih dari 0';
                if (_selectedPeminjaman != null && jumlah > (_selectedPeminjaman!.jumlah ?? 0)) {
                  return 'Jumlah kembali tidak boleh melebihi jumlah pinjam';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Kondisi',
                border: OutlineInputBorder(),
              ),
              value: _kondisiOptions.contains(_kondisiController.text)
                  ? _kondisiController.text
                  : null,
              items: _kondisiOptions.map((String kondisi) {
                return DropdownMenuItem<String>(
                  value: kondisi,
                  child: Text(kondisi),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _kondisiController.text = value;
                  });
                }
              },
              validator: (_) =>
                  _kondisiController.text.isEmpty ? 'Kondisi harus dipilih' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _submitForm,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _loading ? 'Memproses...' : 'Kirim Pengembalian',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tglKembaliController.dispose();
    _jumlahKembaliController.dispose();
    _kondisiController.dispose();
    super.dispose();
  }
}
