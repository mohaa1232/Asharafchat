import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data()!;
          final privacy = Map<String, dynamic>.from(data['privacy'] ?? {});

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(radius: 44, backgroundImage: data['photoUrl'] != null
                  ? NetworkImage(data['photoUrl']) : null,
                  child: data['photoUrl'] == null ? const Icon(Icons.person, size: 44) : null),
              const SizedBox(height: 12),
              Text(data['displayName'] ?? '', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              Text(data['status'] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const Divider(height: 32),
              const Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Show last seen'),
                value: privacy['lastSeenVisible'] ?? true,
                onChanged: (v) => userDoc.update({'privacy.lastSeenVisible': v}),
              ),
              SwitchListTile(
                title: const Text('Show profile photo'),
                value: privacy['photoVisible'] ?? true,
                onChanged: (v) => userDoc.update({'privacy.photoVisible': v}),
              ),
              SwitchListTile(
                title: const Text('Show status'),
                value: privacy['statusVisible'] ?? true,
                onChanged: (v) => userDoc.update({'privacy.statusVisible': v}),
              ),
              SwitchListTile(
                title: const Text('Read receipts'),
                value: privacy['readReceipts'] ?? true,
                onChanged: (v) => userDoc.update({'privacy.readReceipts': v}),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('App lock (PIN / biometric)'),
                onTap: () {}, // TODO: wire local_auth + flutter_secure_storage PIN
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Blocked users'),
                onTap: () {},
              ),
              const Divider(height: 32),
              FilledButton.tonal(
                onPressed: () async {
                  await AuthRepository().signOut();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
