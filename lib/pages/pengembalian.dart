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

  final List<String> _kondisiOptions = ['baik', 'rusak', 'hilang'];

  // Add a method to validate the selected condition
  bool _validateKondisi(String kondisi) {
    // Add special validation for 'hilang' condition
    if (kondisi == 'hilang') {
      // Show error message when 'hilang' is selected
      _showSnackBar('Kondisi "hilang" tidak dapat dipilih saat ini', isError: true);
      // Reset to default condition
      _kondisiController.text = 'baik';
      return false;
    }
    return true;
  }

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
    DateTime? borrowDate;
    if (_selectedPeminjaman?.tglPinjam != null) {
      try {
        borrowDate = _dateFormat.parse(_selectedPeminjaman!.tglPinjam!);
      } catch (e) {
        print('Error parsing borrow date: $e');
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: borrowDate ?? DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (borrowDate != null && picked.isBefore(borrowDate)) {
        _showSnackBar('Tanggal kembali tidak boleh sebelum tanggal pinjam', isError: true);
        return;
      }
      
      setState(() {
        _tglKembaliController.text = _dateFormat.format(picked);
      });
    }
  }

  void _updateJumlahKembali() {
    if (_selectedPeminjaman != null) {
      _jumlahKembaliController.text = (_selectedPeminjaman!.jumlah ?? 0).toString();
      
      // Auto-fill return date with the scheduled return date if available
      if (_selectedPeminjaman!.tglKembali != null && _selectedPeminjaman!.tglKembali!.isNotEmpty) {
        _tglKembaliController.text = _selectedPeminjaman!.tglKembali!;
      } else {
        // If no scheduled return date, use today's date
        _tglKembaliController.text = _dateFormat.format(DateTime.now());
      }
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
        title: Text('Pengembalian', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _listPeminjaman.isEmpty
                  ? _buildNoItemsView()
                  : Container(
                      color: Colors.grey[100],
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'FORM PENGEMBALIAN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 20),
                            _buildFormIcon(),
                            SizedBox(height: 16),
                            _buildFormCard(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildFormIcon() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.assignment_return,
        size: 40,
        color: Colors.blue[700],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frame 1: Pilih Peminjaman
              _buildFrame(
                title: 'Pilih Peminjaman',
                icon: Icons.inventory_2_outlined,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<Peminjaman>(
                      decoration: _getInputDecoration(
                        label: 'Pilih Peminjaman',
                        icon: Icons.inventory_2_outlined,
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
                    if (_selectedPeminjaman != null) 
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Nama Barang', _selectedPeminjaman!.namaBarang ?? '-'),
                            _buildDetailRow('Jumlah Dipinjam', '${_selectedPeminjaman!.jumlah}'),
                            _buildDetailRow('Tanggal Pinjam', _selectedPeminjaman!.tglPinjam ?? '-'),
                            _buildDetailRow('Tanggal Kembali', _selectedPeminjaman?.tglKembali ?? '-'),
                            _buildDetailRow('Alasan Peminjaman', _selectedPeminjaman!.alasanPinjam ?? '-'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Frame 2: Detail Pengembalian
              _buildFrame(
                title: 'Detail Pengembalian',
                icon: Icons.assignment_return,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _namaController,
                      label: 'Nama Pengembali',
                      icon: Icons.person_outline,
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Nama pengembali harus diisi' : null,
                    ),
                    SizedBox(height: 16),
                    _buildDateField(),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _jumlahKembaliController,
                      label: 'Jumlah Kembali',
                      icon: Icons.numbers_outlined,
                      keyboardType: TextInputType.number,
                      readOnly: true,
                      enabled: false,
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
                    _buildKondisiField(),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrame({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue[700], size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildPeminjamanDetails() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Nama Barang', _selectedPeminjaman!.namaBarang ?? '-'),
          _buildDetailRow('Jumlah Dipinjam', '${_selectedPeminjaman!.jumlah}'),
          _buildDetailRow('Tanggal Pinjam', _selectedPeminjaman!.tglPinjam ?? '-'),
          _buildDetailRow('Tanggal Kembali', _selectedPeminjaman?.tglKembali ?? '-'),
          _buildDetailRow('Alasan Peminjaman', _selectedPeminjaman!.alasanPinjam ?? '-'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildDropdownField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: _getInputDecoration(
            label: label, 
            icon: icon,
            disabled: !enabled,
          ),
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          enabled: enabled,
          style: TextStyle(color: Colors.black),
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal Kembali',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _tglKembaliController,
          readOnly: true,
          decoration: _getInputDecoration(
            label: 'Tanggal Kembali',
            icon: Icons.calendar_today_outlined,
            suffix: Icon(Icons.date_range, color: Colors.blue),
          ),
          onTap: () => _selectDate(context),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tanggal kembali harus diisi';
            }
            
            if (_selectedPeminjaman?.tglPinjam != null) {
              try {
                final returnDate = _dateFormat.parse(value);
                final borrowDate = _dateFormat.parse(_selectedPeminjaman!.tglPinjam!);
                if (returnDate.isBefore(borrowDate)) {
                  return 'Tanggal kembali tidak boleh sebelum tanggal pinjam';
                }
              } catch (e) {
                return 'Format tanggal tidak valid';
              }
            }
            return null;
          },
        ),
        if (_selectedPeminjaman?.tglPinjam != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              'Tidak boleh sebelum ${_selectedPeminjaman!.tglPinjam}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKondisiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kondisi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: _getInputDecoration(
            label: 'Kondisi',
            icon: Icons.assessment_outlined,
          ),
          value: _kondisiOptions.contains(_kondisiController.text)
              ? _kondisiController.text
              : null,
          items: _kondisiOptions.map((String kondisi) {
            return DropdownMenuItem<String>(
              value: kondisi,
              child: Text(kondisi.toUpperCase()),
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
          isExpanded: true,
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
    bool disabled = false,
  }) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
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
          elevation: 2,
        ),
        child: Text(
          _loading ? 'Memproses...' : 'Kirim',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: Icon(Icons.refresh),
                label: Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoItemsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak Ada Barang untuk Dikembalikan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Semua barang yang dipinjam telah dikembalikan atau belum ada peminjaman yang disetujui',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
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














