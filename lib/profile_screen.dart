import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'user_profile_view_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _activeTab = 0; // 0 for Identity, 1 for Address
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;
  String? _profilePictureBase64;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController tehsilController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  String accountType = 'Inland Citizen';
  String gender = 'Male';
  String province = 'Punjab';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final token = prefs.getString('token') ?? '';

    if (userId.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/profile/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          accountType = data['accountType'] ?? 'Inland Citizen';
          fullNameController.text = data['fullName'] ?? '';
          fatherNameController.text = data['fatherName'] ?? '';
          cnicController.text = data['cnic'] ?? '';
          if (data['dob'] != null) dobController.text = data['dob'].toString().split('T')[0];
          gender = data['gender'] ?? 'Male';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
          province = data['province'] ?? 'Punjab';
          districtController.text = data['district'] ?? '';
          tehsilController.text = data['tehsil'] ?? '';
          addressController.text = data['address'] ?? '';
          _profilePictureBase64 = data['profilePicture'];
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _profilePictureBase64 = "data:image/jpeg;base64,${base64Encode(bytes)}";
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _isLoading = true; _statusMessage = ''; });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getString('userId') ?? '';

    final Map<String, dynamic> updateData = {
      'userId': userId,
      'accountType': accountType,
      'fullName': fullNameController.text,
      'fatherName': fatherNameController.text,
      'cnic': cnicController.text,
      'dob': dobController.text,
      'gender': gender,
      'phone': phoneController.text,
      'province': province,
      'district': districtController.text,
      'tehsil': tehsilController.text,
      'address': addressController.text,
      'newPassword': newPasswordController.text,
      'profilePicture': _profilePictureBase64,
    };

    try {
      final response = await http.put(
        Uri.parse('http://127.0.0.1:5000/api/profile/update'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode(updateData),
      );

      final responseData = json.decode(response.body);

      setState(() {
        _isSuccess = response.statusCode == 200;
        _statusMessage = _isSuccess ? 'Profile updated successfully!' : (responseData['error'] ?? 'Update failed.');
      });

      if (_isSuccess && mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserProfileViewScreen()));
        });
      }
    } catch (e) {
      setState(() => _statusMessage = 'Server unreachable: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        title: const Text('CIVICCARE.AI Setup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner & Avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomLeft,
              children: [
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                  ),
                ),
                Positioned(
                  bottom: -35,
                  left: 20,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          backgroundImage: _profilePictureBase64 != null && _profilePictureBase64!.startsWith('data:image')
                              ? MemoryImage(base64Decode(_profilePictureBase64!.split(',')[1]))
                              : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Citizen') as ImageProvider,
                        ),
                        const Positioned(
                          bottom: 0, right: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF0066FF),
                            child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 45),

            // Tab Toggle Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activeTab == 0 ? const Color(0xFF0066FF) : Colors.white,
                        foregroundColor: _activeTab == 0 ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => setState(() => _activeTab = 0),
                      child: const Text("Identity Details", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activeTab == 1 ? const Color(0xFF0066FF) : Colors.white,
                        foregroundColor: _activeTab == 1 ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => setState(() => _activeTab = 1),
                      child: const Text("Address & Contact", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            if (_statusMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(_statusMessage, style: TextStyle(fontWeight: FontWeight.bold, color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800)),
              ),

            // Form Content Based on Tabs
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_activeTab == 0) ...[
                      const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      _buildDropdown('Account Type', Icons.people, accountType, ['Inland Citizen', 'Overseas Pakistani', 'Foreigner'], (val) => setState(() => accountType = val!)),
                      _buildTextField('Full Name', Icons.person_outline, fullNameController),
                      _buildTextField("Father's Name", Icons.group_outlined, fatherNameController),
                      _buildTextField('National ID (CNIC)', Icons.shield_outlined, cnicController),
                      _buildTextField('Date of Birth (YYYY-MM-DD)', Icons.calendar_today, dobController),
                      _buildDropdown('Gender', Icons.person, gender, ['Male', 'Female', 'Other'], (val) => setState(() => gender = val!)),
                    ] else ...[
                      const Text('Contact & Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      _buildTextField('Email Address', Icons.email_outlined, emailController, isReadOnly: true),
                      _buildTextField('Mobile Number', Icons.phone_outlined, phoneController),
                      _buildDropdown('Province', Icons.map_outlined, province, ['Punjab', 'Sindh', 'KPK', 'Balochistan', 'Islamabad'], (val) => setState(() => province = val!)),
                      _buildTextField('District / City', Icons.home_work_outlined, districtController),
                      _buildTextField('Tehsil', Icons.home_outlined, tehsilController),
                      _buildTextField('Complete Postal Address', Icons.location_city_outlined, addressController, maxLines: 3),
                    ],
                    const SizedBox(height: 20),
                    _buildTextField('Update Password (Optional)', Icons.lock_outline, newPasswordController, isPassword: true),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isReadOnly = false, bool isPassword = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller, readOnly: isReadOnly, obscureText: isPassword, maxLines: maxLines,
            style: TextStyle(fontWeight: FontWeight.bold, color: isReadOnly ? Colors.grey : Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.black38, size: 20),
              filled: true, fillColor: isReadOnly ? Colors.grey.shade100 : Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.black38, size: 20),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}