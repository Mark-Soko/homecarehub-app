import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/base_scaffold_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:handyman_provider_flutter/components/price_widget.dart';
import 'package:nb_utils/nb_utils.dart';

class RefundRequestsScreen extends StatefulWidget {
  @override
  State<RefundRequestsScreen> createState() => _RefundRequestsScreenState();
}

class _RefundRequestsScreenState extends State<RefundRequestsScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await getRefundRequests();
      if (mounted) setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      toast(e.toString());
    }
  }

  String _statusLabel(String? status) {
    if (status == null) return 'Pending';
    switch (status.toString().toLowerCase()) {
      case 'pending': return 'Pending';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'processed': return 'Processed';
      default: return status.toString();
    }
  }

  Color _statusColor(String? status) {
    switch (status.toString().toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'processed': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Refund Requests',
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? Loader()
            : _list.isEmpty
                ? Center(child: Text('No refund requests', style: secondaryTextStyle()))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (context, index) {
                      final item = _list[index];
                      final booking = item['booking'] as Map<String, dynamic>?;
                      final service = booking != null ? booking['service'] as Map<String, dynamic>? : null;
                      final serviceName = service?['name'] ?? 'Booking #${item['booking_id']}';
                      final amount = (item['amount'] is num) ? (item['amount'] as num).toDouble() : 0.0;
                      final status = item['status'] as String?;
                      final reason = item['reason'] as String?;
                      final createdAt = item['created_at'] as String?;
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          title: Text(serviceName, style: boldTextStyle(size: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (reason != null && reason.isNotEmpty) Text(reason, style: secondaryTextStyle(size: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              4.height,
                              PriceWidget(price: amount, size: 14, color: context.primaryColor),
                              if (createdAt != null) Text(createdAt, style: secondaryTextStyle(size: 11)),
                            ],
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.15),
                              borderRadius: radius(4),
                            ),
                            child: Text(_statusLabel(status), style: boldTextStyle(size: 12, color: _statusColor(status))),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
