import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResidentPortalTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isLoadingProfile;

  const ResidentPortalTab({Key? key, required this.userData, required this.isLoadingProfile}) : super(key: key);

  @override
  State<ResidentPortalTab> createState() => _ResidentPortalTabState();
}

class _ResidentPortalTabState extends State<ResidentPortalTab> with AutomaticKeepAliveClientMixin {
  String _activeView = 'grid';
  bool _isLoading = false;

  List<dynamic> _family = [];
  List<dynamic> _vehicles = [];
  List<dynamic> _tenants = [];
  List<dynamic> _servants = [];

  int? _deleteConfirmId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchPortfolio();
  }

  void _showInlineMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isError ? LucideIcons.alertTriangle : LucideIcons.checkCircle2, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          backgroundColor: isError ? Colors.red.shade600 : Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        )
    );
  }

  Future<void> _fetchPortfolio() async {
    if (_family.isEmpty && _vehicles.isEmpty && _tenants.isEmpty && _servants.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final res = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/resident/portfolio'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = json.decode(res.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _family = data['data']['familyMembers'] ?? [];
          _vehicles = data['data']['vehicles'] ?? [];
          _tenants = data['data']['tenants'] ?? [];
          _servants = data['data']['servants'] ?? [];
        });
      }
    } catch (e) {
      _showInlineMessage("Failed to load resident data", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executeDelete(String category, int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await http.delete(
        Uri.parse('http://127.0.0.1:5000/api/resident/$category/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(res.body);
      if (data['success']) {
        _showInlineMessage("Record deleted successfully");
        if (mounted) setState(() => _deleteConfirmId = null);
        _fetchPortfolio();
      } else {
        _showInlineMessage(data['message'] ?? "Deletion failed", isError: true);
        if (mounted) setState(() => _deleteConfirmId = null);
      }
    } catch (e) {
      _showInlineMessage("Network error", isError: true);
      if (mounted) setState(() => _deleteConfirmId = null);
    }
  }

  void _openFormModal(String category, String title, List<Map<String, String>> fields, {Map<String, dynamic>? existingData}) {
    final isUpdating = existingData != null;
    final Map<String, TextEditingController> controllers = {
      for (var field in fields)
        field['name']!: TextEditingController(text: isUpdating ? existingData[field['name']]?.toString() ?? '' : '')
    };
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isUpdating ? 'Update $title' : 'Register New $title', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...fields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field['label']!.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controllers[field['name']],
                        decoration: InputDecoration(
                          hintText: field['placeholder'],
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2)),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isSubmitting ? null : () async {
                      setModalState(() => isSubmitting = true);
                      Map<String, String> payload = {
                        for (var field in fields) field['name']!: controllers[field['name']]!.text
                      };
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token') ?? '';

                        final url = isUpdating
                            ? 'http://127.0.0.1:5000/api/resident/$category/${existingData['id']}'
                            : 'http://127.0.0.1:5000/api/resident/$category/add';

                        final response = isUpdating
                            ? await http.put(Uri.parse(url), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: json.encode(payload))
                            : await http.post(Uri.parse(url), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: json.encode(payload));

                        final data = json.decode(response.body);

                        if (data['success'] && mounted) {
                          Navigator.pop(context);
                          _showInlineMessage("$title ${isUpdating ? 'updated' : 'added'} successfully!");
                          _fetchPortfolio();
                        } else {
                          _showInlineMessage(data['message'], isError: true);
                        }
                      } catch (e) {
                        _showInlineMessage("Network Error", isError: true);
                      } finally {
                        setModalState(() => isSubmitting = false);
                      }
                    },
                    icon: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(LucideIcons.save, size: 20, color: Colors.white),
                    label: Text(isUpdating ? 'Save Changes' : 'Submit Record', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildProfileTab() {
    if (widget.isLoadingProfile) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _activeView = 'grid'),
              icon: const Icon(LucideIcons.arrowLeft, size: 16, color: Color(0xFF060D1E)),
              label: const Text("Back to Portal", style: TextStyle(color: Color(0xFF060D1E), fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300))
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
            child: Column(
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF06B6D4)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: widget.userData?['profilePicture'] != null && widget.userData!['profilePicture'].toString().isNotEmpty
                            ? (widget.userData!['profilePicture'].toString().startsWith('data:image')
                            ? MemoryImage(base64Decode(widget.userData!['profilePicture'].toString().split(',')[1]))
                            : NetworkImage('http://127.0.0.1:5000${widget.userData!['profilePicture']}') as ImageProvider)
                            : NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=${widget.userData?['fullName'] ?? 'Citizen'}') as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      Text(widget.userData?['fullName'] ?? 'Citizen Name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const Text('Resident Head', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListModule(String apiCategory, String title, List<dynamic> dataArray, IconData icon, MaterialColor color, List<Map<String, String>> formFields) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF060D1E)),
                onPressed: () => setState(() { _activeView = 'grid'; _deleteConfirmId = null; }),
                style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300))),
              ),
              const SizedBox(width: 12),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color.shade600, size: 20)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : dataArray.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text("No records found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dataArray.length,
            itemBuilder: (ctx, i) {
              final item = dataArray[i];
              final isConfirmingDelete = _deleteConfirmId == item['id'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['fullName'] ?? "${item['make']} ${item['model']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              if(item['relation'] != null) _buildTag(item['relation'], color),
                              if(item['role'] != null) _buildTag(item['role'], color),
                              if(item['plateNumber'] != null) _buildTag(item['plateNumber'], Colors.grey),
                              if(item['cnic'] != null && item['cnic'].toString().isNotEmpty) _buildTag(item['cnic'], Colors.grey),
                            ],
                          )
                        ],
                      ),
                    ),
                    if (isConfirmingDelete)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Delete?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 10)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _executeDelete(apiCategory, item['id']),
                              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: const Text("Yes", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => setState(() => _deleteConfirmId = null),
                              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: const Text("No", style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold))),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.edit2, color: Colors.blue, size: 18),
                            onPressed: () => _openFormModal(apiCategory, title, formFields, existingData: item),
                            style: IconButton.styleFrom(backgroundColor: Colors.blue.shade50),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                            onPressed: () => setState(() => _deleteConfirmId = item['id']),
                            style: IconButton.styleFrom(backgroundColor: Colors.red.shade50),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          )
                        ],
                      )
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text("Add New $title", style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _openFormModal(apiCategory, title, formFields),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color == Colors.grey ? Colors.grey.shade100 : color.shade50, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color == Colors.grey ? Colors.black87 : color.shade700, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for KeepAlive
    if (_activeView == 'profile') return _buildProfileTab();

    if (_activeView == 'family') return _buildListModule('family', 'Family', _family, LucideIcons.users, Colors.pink, [
      {'name': 'fullName', 'label': 'Full Name', 'placeholder': 'Enter full legal name'},
      {'name': 'relation', 'label': 'Relation', 'placeholder': 'e.g., Spouse, Child'},
      {'name': 'cnic', 'label': 'CNIC (Optional)', 'placeholder': '00000-0000000-0'},
      {'name': 'contact', 'label': 'Contact Number', 'placeholder': '03XX-XXXXXXX'},
    ]);

    if (_activeView == 'vehicles') return _buildListModule('vehicles', 'Vehicles', _vehicles, LucideIcons.car, Colors.teal, [
      {'name': 'make', 'label': 'Make', 'placeholder': 'e.g., Toyota'},
      {'name': 'model', 'label': 'Model', 'placeholder': 'e.g., Corolla 2022'},
      {'name': 'plateNumber', 'label': 'License Plate', 'placeholder': 'ABC-123'},
      {'name': 'color', 'label': 'Color', 'placeholder': 'e.g., White'},
    ]);

    if (_activeView == 'tenants') return _buildListModule('tenants', 'Tenants', _tenants, LucideIcons.key, Colors.orange, [
      {'name': 'fullName', 'label': 'Full Name', 'placeholder': 'Enter registered name'},
      {'name': 'cnic', 'label': 'CNIC', 'placeholder': '00000-0000000-0'},
      {'name': 'contact', 'label': 'Contact Number', 'placeholder': '03XX-XXXXXXX'},
    ]);

    if (_activeView == 'servants') return _buildListModule('servants', 'Servants', _servants, LucideIcons.userCheck, Colors.purple, [
      {'name': 'fullName', 'label': 'Full Name', 'placeholder': 'Enter registered name'},
      {'name': 'role', 'label': 'Role', 'placeholder': 'e.g., Maid, Driver'},
      {'name': 'cnic', 'label': 'CNIC', 'placeholder': '00000-0000000-0'},
      {'name': 'contact', 'label': 'Contact Number', 'placeholder': '03XX-XXXXXXX'},
    ]);

    final List<Map<String, dynamic>> modules = [
      {'id': 'profile', 'title': 'My Profile', 'desc': 'View primary records', 'icon': LucideIcons.fileBadge, 'color': Colors.blue},
      {'id': 'family', 'title': 'Family Registry', 'desc': 'Add household members', 'icon': LucideIcons.users, 'color': Colors.pink},
      {'id': 'vehicles', 'title': 'Vehicle Access', 'desc': 'Manage car/bike passes', 'icon': LucideIcons.car, 'color': Colors.teal},
      {'id': 'tenants', 'title': 'Tenant Details', 'desc': 'Register lease holders', 'icon': LucideIcons.key, 'color': Colors.orange},
      {'id': 'servants', 'title': 'Staff Clearances', 'desc': 'Verify maids & drivers', 'icon': LucideIcons.userCheck, 'color': Colors.purple},
    ];

    return RefreshIndicator(
      onRefresh: _fetchPortfolio,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(LucideIcons.clipboardList, size: 28, color: Color(0xFF0066FF)),
                  ),
                  const SizedBox(width: 16),
                  const Text('Resident Data', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF060D1E))),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 1.3, crossAxisSpacing: 16, mainAxisSpacing: 16,
                ),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final mod = modules[index];
                  return InkWell(
                    onTap: () => setState(() { _activeView = mod['id']; _deleteConfirmId = null; }),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(mod['icon'], color: (mod['color'] as MaterialColor).shade600, size: 28),
                          const SizedBox(height: 8),
                          Text(mod['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          Flexible(
                            child: Text(mod['desc'], style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}