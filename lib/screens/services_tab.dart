import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/municipal_api_service.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({Key? key}) : super(key: key);

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> with AutomaticKeepAliveClientMixin {
  final MunicipalApiService _apiService = MunicipalApiService();
  List<dynamic> _services = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final services = await _apiService.fetchPublicServices();
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading services: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openRequestSheet(Map<String, dynamic> service) {
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Request ${service['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'SLA: Guaranteed resolution in ${service['defaultDeadlineDays'] ?? 3} Days',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('DELIVERY ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: 'e.g., House 12, Block A',
                    prefixIcon: const Icon(LucideIcons.mapPin, color: Color(0xFF0066FF), size: 18),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('NOTES / INSTRUCTIONS (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Specific details for the municipal team...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                      if (addressController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery address is required.')));
                        return;
                      }

                      setModalState(() => isSubmitting = true);

                      bool success = false;
                      String errorMessage = '';

                      try {
                        // Safely parse the service ID
                        final int serviceId = service['id'] is int ? service['id'] : int.parse(service['id'].toString());
                        success = await _apiService.requestService(serviceId, addressController.text, notesController.text);
                      } catch (e) {
                        errorMessage = e.toString().replaceAll("Exception: ", "");
                        debugPrint("==== API ERROR: $errorMessage ====");
                      }

                      // Force the modal to close BEFORE showing the result so it doesn't get hidden
                      if (mounted) {
                        Navigator.pop(context);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Service requested successfully!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: ${errorMessage.isNotEmpty ? errorMessage : 'Server unreachable'}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirm Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Municipal Service Catalog', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Request equipment dispatch or recurring sanitation services.', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadServices,
              child: _services.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.briefcase, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text("No public services published yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  final isSubscription = service['type'] == 'SUBSCRIPTION';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSubscription ? Colors.purple.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                service['type'] ?? 'ONE_TIME',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: isSubscription ? Colors.purple : Colors.green),
                              ),
                            ),
                            Text('Rs. ${service['fee'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(service['name'] ?? 'Service', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(
                          service['description'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF0066FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _openRequestSheet(service),
                            child: const Text('Request Service', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}