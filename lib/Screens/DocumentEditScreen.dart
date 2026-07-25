import 'package:flutter/material.dart';

class DocumentEditScreen extends StatefulWidget {
  final List<Document> documents;

  const DocumentEditScreen({super.key, required this.documents});

  @override
  _DocumentEditScreenState createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends State<DocumentEditScreen> {
  late List<Document> editedDocuments;

  @override
  void initState() {
    super.initState();
    // Create a copy of the documents to edit locally
    editedDocuments = widget.documents.map((doc) => Document(doc.title, doc.isPresent)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A57D1),
        title: const Text("Edit Documents", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Save changes and return to the previous screen
              Navigator.pop(context, editedDocuments);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: editedDocuments.length,
        itemBuilder: (context, index) {
          return _buildDocumentEditCard(editedDocuments[index]);
        },
      ),
    );
  }

  Widget _buildDocumentEditCard(Document document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: document.title,
            decoration: const InputDecoration(
              labelText: "Document Title",
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                document.title = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Is Present",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Switch(
                value: document.isPresent,
                activeColor: Colors.green,
                onChanged: (value) {
                  setState(() {
                    document.isPresent = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Document {
  String title;
  bool isPresent;

  Document(this.title, this.isPresent);
}
