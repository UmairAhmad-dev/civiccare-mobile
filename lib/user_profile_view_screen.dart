import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';

class UserProfileViewScreen extends StatefulWidget {
  const UserProfileViewScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final token = prefs.getString('token') ?? '';

    debugPrint("Fetching profile for UserID: $userId with Token: $token");

    if (userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/profile/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint("Profile API Status: ${res.statusCode}");
      debugPrint("Profile API Body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          userData = {
            ...data,
            'fullName': data['fullName'] ?? data['fullname'] ?? data['full_name'],
            'fatherName': data['fatherName'] ?? data['fathername'] ?? data['father_name'],
            'cnic': data['cnic'] ?? data['CNIC'],
            'dob': data['dob'] ?? data['DOB'],
            'profilePicture': data['profilePicture'] ?? data['profile_picture']
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF8FAFC), body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E),
        title: const Text('Digital Identity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                children: [
                  Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF06B6D4)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: userData?['profilePicture'] != null && userData!['profilePicture'].toString().startsWith('data:image')
                              ? MemoryImage(base64Decode(userData!['profilePicture'].toString().split(',')[1]))
                              : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Citizen') as ImageProvider,
                        ),
                        const SizedBox(height: 10),
                        Text(userData?['fullName'] ?? 'Citizen Name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text(userData?['accountType'] ?? 'Citizen', style: const TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildBentoCard(
              title: 'Official Identity',
              icon: Icons.person,
              color: Colors.blue,
              children: [
                _buildInfoRow('CNIC Number', userData?['cnic'] ?? 'Not provided'),
                _buildInfoRow('Father\'s Name', userData?['fatherName'] ?? 'Not provided'),
                _buildInfoRow('Date of Birth', userData?['dob'] != null ? userData!['dob'].toString().split('T')[0] : 'Not provided'),
                _buildInfoRow('Gender', userData?['gender'] ?? 'Not provided'),
              ],
            ),
            const SizedBox(height: 16),

            _buildBentoCard(
              title: 'Contact Channels',
              icon: Icons.phone_in_talk,
              color: Colors.indigo,
              children: [
                _buildInfoRow('Primary Email', userData?['email'] ?? 'Not provided'),
                _buildInfoRow('Mobile Network', userData?['phone'] ?? 'Not provided'),
              ],
            ),
            const SizedBox(height: 16),

            _buildBentoCard(
              title: 'Registered Domicile',
              icon: Icons.location_on,
              color: Colors.teal,
              children: [
                _buildInfoRow('Province', userData?['province'] ?? 'Not provided'),
                _buildInfoRow('District / City', userData?['district'] ?? 'Not provided'),
                _buildInfoRow('Tehsil', userData?['tehsil'] ?? 'Not provided'),
                _buildInfoRow('Complete Address', userData?['address'] ?? 'Not provided'),
              ],
            ),
            const SizedBox(height: 25),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF060D1E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
              icon: const Icon(Icons.dashboard),
              label: const Text('Go to Main Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({required String title, required IconData icon, required Color color, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}