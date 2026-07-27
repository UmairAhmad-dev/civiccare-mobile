import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class InformationCenterScreen extends StatefulWidget {
  @override
  _InformationCenterScreenState createState() => _InformationCenterScreenState();
}

class _InformationCenterScreenState extends State<InformationCenterScreen> with AutomaticKeepAliveClientMixin {
  int activeTabIndex = 0; // 0: Notices, 1: Directory, 2: Lost & Found
  bool isLoading = false;
  String searchQuery = '';
  String serviceCategoryFilter = 'All';

  List<dynamic> notices = [];
  List<dynamic> services = [];
  List<dynamic> lostFoundItems = [];

  final List<String> serviceCategories = ['All', 'Emergency', 'Maintenance', 'Medical', 'Utilities'];

  final List<Map<String, dynamic>> dummyServices = [
    { 'id': 'd1', 'name': 'Central Emergency Police Dispatch', 'category': 'Emergency', 'phone': '15', 'description': 'Immediate law enforcement response unit.' },
    { 'id': 'd2', 'name': 'Municipal Rescue & Ambulance', 'category': 'Medical', 'phone': '115', 'description': '24/7 rapid medical response.' },
    { 'id': 'd3', 'name': 'WASA Water Supply & Drainage', 'category': 'Utilities', 'phone': '0489230222', 'description': 'Report pipeline bursts or low water pressure.' },
    { 'id': 'd4', 'name': 'FESCO Electricity Fault Grid', 'category': 'Maintenance', 'phone': '118', 'description': 'Power outage reports and emergency line repairs.' },
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchTabData();
  }

  Future<void> fetchTabData() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      if (activeTabIndex == 0) {
        final res = await http.get(Uri.parse('http://127.0.0.1:5000/api/info/notices'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && mounted) {
          setState(() => notices = json.decode(res.body)['data'] ?? []);
        }
      } else if (activeTabIndex == 1) {
        try {
          final res = await http.get(Uri.parse('http://127.0.0.1:5000/api/info/services'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 && mounted) {
            final data = json.decode(res.body)['data'];
            setState(() => services = (data != null && data.isNotEmpty) ? data : dummyServices);
          } else {
            setState(() => services = dummyServices);
          }
        } catch (_) {
          setState(() => services = dummyServices);
        }
      } else if (activeTabIndex == 2) {
        final res = await http.get(Uri.parse('http://127.0.0.1:5000/api/info/lost-and-found'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && mounted) {
          setState(() => lostFoundItems = json.decode(res.body)['data'] ?? []);
        }
      }
    } catch (e) {
      if (activeTabIndex == 1) setState(() => services = dummyServices);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _launchCaller(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer.')));
    }
  }

  IconData _getServiceIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('emergency')) return Icons.local_police;
    if (cat.contains('medical')) return Icons.medical_services;
    if (cat.contains('maintenance')) return Icons.build;
    return Icons.business;
  }

  Color _getServiceColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('emergency')) return Colors.redAccent;
    if (cat.contains('medical')) return Colors.teal;
    if (cat.contains('maintenance')) return Colors.orange;
    return const Color(0xFF0066FF);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroHeader()),
          SliverToBoxAdapter(child: _buildToolbar()),
          if (activeTabIndex == 1) SliverToBoxAdapter(child: _buildCategoryFilters()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            sliver: _buildContentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0066FF),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFF0066FF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: Colors.cyanAccent, size: 14),
                SizedBox(width: 4),
                Text('CIVICCARE HUB', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Information\nCenter', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 12),
          Text('Stay synchronized with municipal announcements and community services.', style: TextStyle(color: Colors.blue[100], fontSize: 14)),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton(0, 'Notices', Icons.campaign),
                const SizedBox(width: 8),
                _buildTabButton(1, 'Directory', Icons.call),
                const SizedBox(width: 8),
                _buildTabButton(2, 'Lost & Found', Icons.local_offer),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    bool isActive = activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          activeTabIndex = index;
          searchQuery = '';
        });
        fetchTabData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? const Color(0xFF0066FF) : Colors.white),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? const Color(0xFF0066FF) : Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        onChanged: (val) => setState(() => searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: serviceCategories.length,
        itemBuilder: (context, index) {
          String cat = serviceCategories[index];
          bool isActive = serviceCategoryFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat, style: TextStyle(color: isActive ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)),
              selected: isActive,
              selectedColor: const Color(0xFF060D1E),
              backgroundColor: Colors.white,
              onSelected: (selected) => setState(() => serviceCategoryFilter = cat),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentList() {
    if (isLoading) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())));

    if (activeTabIndex == 0) {
      final filtered = notices.where((n) => n['title'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
      if (filtered.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(30), child: Text("No notices found"))));
      return SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildNoticeCard(filtered[index]), childCount: filtered.length));
    } else if (activeTabIndex == 1) {
      final filtered = services.where((s) {
        final matchesSearch = s['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
        final matchesCat = serviceCategoryFilter == 'All' || s['category'].toString() == serviceCategoryFilter;
        return matchesSearch && matchesCat;
      }).toList();
      if (filtered.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(30), child: Text("No services found"))));
      return SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildServiceCard(filtered[index]), childCount: filtered.length));
    } else {
      final filtered = lostFoundItems.where((i) => i['title'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
      if (filtered.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(30), child: Text("No lost items reported"))));
      return SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildLostFoundCard(filtered[index]), childCount: filtered.length));
    }
  }

  Widget _buildNoticeCard(Map<String, dynamic> notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                child: Text(notice['category'] ?? 'Notice', style: const TextStyle(color: Color(0xFF0066FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              Text(notice['createdAt'] != null ? notice['createdAt'].toString().substring(0, 10) : '', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(notice['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(notice['description'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    Color iconColor = _getServiceColor(service['category'] ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(_getServiceIcon(service['category'] ?? ''), color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((service['category'] ?? '').toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(service['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(service['description'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchCaller(service['phone'] ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: const Color(0xFF0066FF),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.phone, size: 18),
              label: Text('Call ${service['phone'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLostFoundCard(Map<String, dynamic> item) {
    bool isLost = item['type'] == 'Lost';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['imageUrl'] != null && item['imageUrl'].isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(item['imageUrl'], height: 180, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: isLost ? Colors.red[50] : Colors.green[50], borderRadius: BorderRadius.circular(12)),
                  child: Text('${item['type']} ITEM', style: TextStyle(color: isLost ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 12),
                Text(item['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(item['description'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Color(0xFF0066FF)),
                    const SizedBox(width: 8),
                    Text(item['contactInfo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0066FF))),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}