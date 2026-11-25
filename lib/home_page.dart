import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'crud_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudService service = CrudService();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  bool showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Firebase | Alimong'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            tooltip: showFavoritesOnly ? 'Show all' : 'Show favorites only',
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ), // AppBar
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => openAddDialog(context),
      ), // FloatingActionButton
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;

          if (showFavoritesOnly) {
            docs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data != null && data['isFavorite'] == true;
            }).toList();
          }

          if (docs.isEmpty) {
            return Center(
              child: Text(
                showFavoritesOnly ? "No favorite items found" : "No items found",
                style: const TextStyle(fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var item = docs[index];
              final data = item.data() as Map<String, dynamic>?;
              final bool isFav = data != null && data['isFavorite'] == true;
              final String? imageUrl = data?['image_url'];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ), // Image.network
                        ) // ClipRRect
                      : null,
                  title: Text(
                    data?['name'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ), // Text
                  subtitle: Text(
                    "Quantity ${data?['quantity'] ?? 0}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ), // Text
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () => service.toggleFavorite(item.id, isFav),
                      ), // IconButton
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => openEditDialog(context, item),
                      ), // IconButton
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, item.id),
                      ), // IconButton
                    ],
                  ), // Row
                ), // ListTile
              ); // Card
            },
          ); // ListView.builder
        },
      ), // StreamBuilder
    ); // Scaffold
  }

  //DELETE UI
  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              service.deleteItem(id);
              Navigator.pop(context);
            },
          ), // TextButton
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ), // TextButton
        ],
      ), // AlertDialog
    );
  }

  //ADD UI
  void openAddDialog(BuildContext context) {
    nameCtrl.clear();
    qtyCtrl.clear();

    File? selectedImageFile;
    String? selectedImageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ), // InputDecoration
              ), // TextField
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ), // InputDecoration
                keyboardType: TextInputType.number,
              ), // TextField
              const SizedBox(height: 10),
              if (selectedImageFile != null || selectedImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: selectedImageFile != null && !kIsWeb
                      ? Image.file(
                          selectedImageFile!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ) // Image.file
                      : Image.network(
                          selectedImageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ), // Image.network
                ), // ClipRRect
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(isUploading ? 'Uploading...' : 'upload image'),
                onPressed: isUploading
                    ? null
                    : () async {
                        setState(() => isUploading = true);
                        try {
                          final pickedFile = await service.pickImageForAddItem();
                          if (pickedFile != null) {
                            setState(() {
                              selectedImageFile = pickedFile.file;
                              selectedImageUrl = pickedFile.url;
                            });
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Upload failed: $e')),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() => isUploading = false);
                          }
                        }
                      },
              ), // ElevatedButton.icon
            ],
          ), // Column
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ), // TextButton
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Save"),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                  await service.addItemWithImage(
                    nameCtrl.text,
                    int.parse(qtyCtrl.text),
                    selectedImageUrl,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ), // ElevatedButton
          ],
        ), // AlertDialog
      ), // StatefulBuilder
    );
  }

  //EDIT UI
  void openEditDialog(BuildContext context, DocumentSnapshot item) {
    nameCtrl.text = item['name'];
    qtyCtrl.text = item['quantity'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ), // InputDecoration
            ), // TextField
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              decoration: InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ), // InputDecoration
            ), // TextField
          ],
        ), // Column
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ), // TextButton
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update'),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                service.updateItem(item.id, nameCtrl.text, int.parse(qtyCtrl.text));
                Navigator.pop(context);
              }
            },
          ), // ElevatedButton
        ],
      ), // AlertDialog
    );
  }
}
