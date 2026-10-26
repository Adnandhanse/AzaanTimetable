import 'package:flutter/material.dart';
import '../services/ownership_transfer_repository.dart';

class OwnershipTransfersScreen extends StatefulWidget {
  const OwnershipTransfersScreen({super.key});
  @override
  State<OwnershipTransfersScreen> createState() => _OwnershipTransfersScreenState();
}

class _OwnershipTransfersScreenState extends State<OwnershipTransfersScreen> {
  bool _busy = false;

  Future<void> _review(String id, Map<String, dynamic> data, bool approve) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(approve ? 'Transfer administration?' : 'Reject request?'),
      content: Text(approve
          ? 'Confirm you have verified the new administrator. ${data['masjidName']} will be managed by ${data['newAdminName']} (${data['newAdminMobile']}). Its followers and all masjid data will stay unchanged.'
          : 'The current administrator and all masjid data will stay unchanged.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(approve ? 'Transfer' : 'Reject'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await OwnershipTransferRepository.review(id, approve: approve);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? 'Administration transferred. Masjid data and followers preserved.' : 'Request rejected.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ownership requests')),
    body: StreamBuilder(
      stream: OwnershipTransferRepository.pending(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Unable to load requests. Check your admin access and Firestore rules.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No pending ownership requests.'));
        return ListView(children: docs.map((doc) {
          final data = doc.data();
          return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text('${data['masjidName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Registration: ${data['registrationNo']}'),
              Text('Current admin: ${data['previousAdminMobile']}'),
              Text('New admin: ${data['newAdminName']} • ${data['newAdminMobile']}'),
              Text('Email: ${data['newAdminEmail']}'),
              if (data['newAdminVerificationMethod'] == 'email_password')
                const Text('International request: email and phone are not OTP-verified. Check the masjid/admin before approval.'),
              const Text('Verify with the masjid before approving.'),
              Wrap(spacing: 12, children: [
                TextButton(onPressed: _busy ? null : () => _review(doc.id, data, false), child: const Text('Reject')),
                ElevatedButton(onPressed: _busy ? null : () => _review(doc.id, data, true), child: const Text('Approve transfer')),
              ]),
            ],
          )));
        }).toList());
      },
    ),
  );
}
