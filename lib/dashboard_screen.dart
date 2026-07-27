import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../services/complaint_service.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'screens/resident_portal_tab.dart';
import 'screens/information_center_screen.dart';
import 'screens/services_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Index Mapping: 0=Home, 1=Complaints, 2=Services, 3=Info, 4=SOS, 5=Portal
  int _currentIndex = 0;
  Map<String, dynamic>? userData;
  bool _isLoadingProfile = true;
  bool _isLoadingComplaints = true;

  final ComplaintService _complaintService = ComplaintService();

  List<dynamic> _complaints = [];
  Map<String, dynamic> _stats = {
    'totalLogged': 0,
    'inProgress': 0,
    'resolved': 0,
    'aiAccuracy': '98.4%'
  };

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchDashboardData();
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? prefs.getString('id') ?? '';
    final token = prefs.getString('token') ?? '';

    if (userId.isEmpty) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/profile/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body);
        setState(() {
          userData = {
            ...data,
            'fullName': data['fullName'] ?? data['fullname'] ?? data['full_name'],
            'fatherName': data['fatherName'] ?? data['fathername'] ?? data['father_name'],
            'cnic': data['cnic'] ?? data['CNIC'],
            'dob': data['dob'] ?? data['DOB'],
            'profilePicture': data['profilePicture'] ?? data['profile_picture'],
            'email': data['email']
          };
          _isLoadingProfile = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final statsRes = await _complaintService.fetchDashboardStats();
      final complaintsRes = await _complaintService.fetchUserComplaints();

      if (mounted) {
        setState(() {
          if (statsRes['success'] == true) {
            _stats = statsRes['data']['stats'];
          }
          _complaints = complaintsRes;
          _isLoadingComplaints = false;
        });
      }
    } catch (e) {
      debugPrint("Dashboard data error: $e");
      if (mounted) setState(() => _isLoadingComplaints = false);
    }
  }

  Future<void> _handleDeleteTicket(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently remove this ticket?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _complaintService.deleteComplaint(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket deleted successfully'), backgroundColor: Colors.green),
          );
        }
        _fetchDashboardData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _showTicketDetailsModal(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Ticket #${ticket['id']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(ticket['category'] ?? 'General', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(ticket['status'] ?? 'Open', style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 30),
            const Text("DESCRIPTION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(ticket['description'] ?? 'No description provided', style: const TextStyle(fontSize: 14, height: 1.4)),
            if (ticket['address'] != null && ticket['address'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text("LOCATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF0066FF)),
                  const SizedBox(width: 6),
                  Text(ticket['address'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
            if (ticket['imageUrl'] != null && ticket['imageUrl'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text("ATTACHED EVIDENCE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ticket['imageUrl'].toString().startsWith('data:image')
                    ? Image.memory(
                  base64Decode(ticket['imageUrl'].toString().split(',')[1]),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Image.network(
                  'http://127.0.0.1:5000${ticket['imageUrl']}',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openComplaintModal() {
    String selectedCategory = 'Roads & Potholes';
    final descriptionController = TextEditingController();
    final locationController = TextEditingController(text: 'Sahiwal Block A');
    String? base64Image;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('File Multi-Modal Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 15),
                const Text('Issue Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: ['Roads & Potholes', 'Streetlights', 'Sanitation & Garbage', 'Water & Drainage']
                          .map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 5),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Explain the issue details...',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Attach Photo Evidence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
                    if (file != null) {
                      final bytes = await File(file.path).readAsBytes();
                      setModalState(() {
                        base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: base64Image == null
                        ? Column(
                      children: const [
                        Icon(LucideIcons.uploadCloud, color: Color(0xFF0066FF), size: 28),
                        SizedBox(height: 4),
                        Text("Click to pick image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    )
                        : Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(base64Decode(base64Image!.split(',')[1]), height: 50, width: 50, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        const Text("Image attached!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Location / Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 5),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.mapPin, color: Color(0xFF0066FF), size: 18),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                      if (descriptionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description.')));
                        return;
                      }
                      setModalState(() => isSubmitting = true);
                      try {
                        await _complaintService.createComplaint(
                          category: selectedCategory,
                          description: descriptionController.text,
                          address: locationController.text,
                          imageUrl: base64Image,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          _fetchDashboardData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket submitted successfully!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      } finally {
                        setModalState(() => isSubmitting = false);
                      }
                    },
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Multi-Modal Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentIndex) {
      case 0: return _buildHomeTab();
      case 1: return _buildComplaintsTab();
      case 2: return const ServicesTab();
      case 3: return InformationCenterScreen();
      case 4: return _buildSOSTab();
      case 5: return ResidentPortalTab(userData: userData, isLoadingProfile: _isLoadingProfile);
      default: return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF0066FF), borderRadius: BorderRadius.circular(8)),
              child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('CIVICCARE.AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell, color: Colors.white), onPressed: () {}),
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white24,
                    backgroundImage: userData?['profilePicture'] != null
                        ? (userData!['profilePicture'].toString().startsWith('data:image')
                        ? MemoryImage(base64Decode(userData!['profilePicture'].toString().split(',')[1]))
                        : NetworkImage('http://127.0.0.1:5000${userData!['profilePicture']}') as ImageProvider)
                        : null,
                    child: userData?['profilePicture'] == null
                        ? const Icon(LucideIcons.user, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.chevronDown, color: Colors.white, size: 16),
                ],
              ),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                setState(() => _currentIndex = 5);
              } else if (value == 'settings') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Signed in as", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(userData?['email'] ?? 'Citizen Account', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'profile', child: Row(children: [Icon(LucideIcons.user, size: 18), SizedBox(width: 10), Text("My Profile")])),
              const PopupMenuItem(value: 'settings', child: Row(children: [Icon(LucideIcons.settings, size: 18), SizedBox(width: 10), Text("Account Settings")])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(LucideIcons.logOut, size: 18, color: Colors.red), SizedBox(width: 10), Text("Secure Logout", style: TextStyle(color: Colors.red))])),
            ],
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF060D1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF060D1E)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () { setState(() => _currentIndex = 0); Navigator.pop(context); },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF0066FF), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text('CIVICCARE.AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Smart City Intelligence', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('CITIZEN SERVICES', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
            ListTile(
              leading: const Icon(LucideIcons.layoutDashboard, color: Colors.white70),
              title: const Text('Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              selected: _currentIndex == 0,
              onTap: () { setState(() => _currentIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(LucideIcons.fileText, color: Colors.white70),
              title: const Text('My Complaints', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              selected: _currentIndex == 1,
              onTap: () { setState(() => _currentIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(LucideIcons.briefcase, color: Colors.white70),
              title: const Text('Citizen Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              selected: _currentIndex == 2,
              onTap: () { setState(() => _currentIndex = 2); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(LucideIcons.info, color: Colors.white70),
              title: const Text('Info Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              selected: _currentIndex == 3,
              onTap: () { setState(() => _currentIndex = 3); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(LucideIcons.shieldAlert, color: Colors.white70),
              title: const Text('SOS Emergency', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              selected: _currentIndex == 4,
              onTap: () { setState(() => _currentIndex = 4); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(LucideIcons.clipboardList, color: Colors.white70),
              title: const Text('Resident Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              selected: _currentIndex == 5,
              onTap: () { setState(() => _currentIndex = 5); Navigator.pop(context); },
            ),
            const Divider(color: Colors.white24, height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('AI MODULES (SHOWCASE)', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
            ListTile(
              leading: const Icon(LucideIcons.brainCircuit, color: Colors.white70),
              title: const Text('NLP Text Routing', style: TextStyle(color: Colors.white70, fontSize: 13)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(LucideIcons.eye, color: Colors.white70),
              title: const Text('Damage Detection (CV)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(color: Colors.white24, height: 30),
            ListTile(
              leading: const Icon(LucideIcons.logOut, color: Colors.redAccent),
              title: const Text('Secure Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildComplaintsTab(),
          const ServicesTab(),
          InformationCenterScreen(),
          _buildSOSTab(),
          ResidentPortalTab(userData: userData, isLoadingProfile: _isLoadingProfile),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: [0, 1, 2, 3, 5].contains(_currentIndex) ? [0, 1, 2, 3, 5].indexOf(_currentIndex) : 0,
        onTap: (index) {
          final mappedIndices = [0, 1, 2, 3, 5];
          setState(() => _currentIndex = mappedIndices[index]);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0066FF),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.fileText), label: 'Complaints'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.briefcase), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.info), label: 'Info Hub'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.clipboardList), label: 'Portal'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart City Intelligence Active', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Welcome back, ${userData?['fullName'] ?? 'Citizen'}!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Log infrastructure issues, leverage computer vision damage detection, and monitor resolution timelines.', style: TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0066FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _openComplaintModal,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('File New Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('TOTAL LOGGED', _stats['totalLogged'].toString(), LucideIcons.target, Colors.blue),
              _buildStatCard('IN PROGRESS', _stats['inProgress'].toString(), LucideIcons.clock, Colors.orange),
              _buildStatCard('RESOLVED', _stats['resolved'].toString(), LucideIcons.checkCircle2, Colors.green),
              _buildStatCard('AI ACCURACY', _stats['aiAccuracy'].toString(), LucideIcons.sparkles, Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          const Text('AI Module Showcase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildFeatureCard('Damage Detection', 'CV model inspection', LucideIcons.eye, Colors.teal),
              _buildFeatureCard('NLP Text Route', 'Smart categorization', LucideIcons.brainCircuit, Colors.blue),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.shade600, size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildComplaintsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Complaint Tracking Hub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              IconButton(icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF0066FF), size: 28), onPressed: _openComplaintModal),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingComplaints
                ? const Center(child: CircularProgressIndicator())
                : _complaints.isEmpty
                ? const Center(child: Text("No tickets found", style: TextStyle(fontWeight: FontWeight.bold)))
                : ListView.builder(
              itemCount: _complaints.length,
              itemBuilder: (context, index) {
                final item = _complaints[index];
                final stages = ['Open', 'In Progress', 'Resolved'];
                final currentStage = stages.indexOf(item['status'] ?? 'Open');

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text("Ticket #${item['id']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          item['category'] ?? 'General',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: Color(0xFF0066FF)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showTicketDetailsModal(item),
                                child: const Text("OPEN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0066FF))),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(left: 8),
                                icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                                onPressed: () => _handleDeleteTicket(item['id']),
                              )
                            ],
                          )
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(stages.length, (idx) {
                          final isCompleted = currentStage >= idx;
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isCompleted ? Colors.green : Colors.grey.shade300,
                                child: Text("${idx + 1}", style: TextStyle(color: isCompleted ? Colors.white : Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 4),
                              Text(stages[idx], style: TextStyle(fontSize: 10, fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal, color: isCompleted ? Colors.black87 : Colors.grey)),
                            ],
                          );
                        }),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSOSTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.red, Colors.deepOrange]), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: const [
                Icon(LucideIcons.shieldAlert, color: Colors.white, size: 36),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Response Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('One-touch direct dialing lines for police and medical rescue.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildSOSCard('Police', '15', Colors.blue),
                _buildSOSCard('Ambulance', '115', Colors.red),
                _buildSOSCard('Fire Brigade', '16', Colors.orange),
                _buildSOSCard('Security', '+92300', Colors.green),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSOSCard(String title, String num, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(LucideIcons.phoneCall, color: color, size: 20)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Line: $num', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}