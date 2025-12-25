// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KYCScreen extends StatefulWidget {
  final bool showSkipOption;
  final VoidCallback? onSkip;

  const KYCScreen({
    super.key,
    this.showSkipOption = false,
    this.onSkip,
  });

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  final Color primaryColor = const Color(0xffFF4D00);
  final ImagePicker _picker = ImagePicker();
  late ColorNotifire notifire;

  // Document states
  Map<String, DocumentData> documents = {
    'id_proof': DocumentData(
        title: 'ID Proof',
        description: 'Passport, Driver\'s License, or National ID'),
    'address_proof': DocumentData(
        title: 'Address Proof', description: 'Utility Bill or Bank Statement'),
    'business_license': DocumentData(
        title: 'Business License',
        description: 'Valid business registration document'),
  };

  getdarkmodepreviousstate() async {
    final prefs = await SharedPreferences.getInstance();
    bool? previusstate = prefs.getBool("setIsDark");
    if (previusstate == null) {
      notifire.setIsDark = false;
    } else {
      notifire.setIsDark = previusstate;
    }
  }

  @override
  void initState() {
    super.initState();
    getdarkmodepreviousstate();
  }

  @override
  Widget build(BuildContext context) {
    notifire = Provider.of<ColorNotifire>(context, listen: true);
    return Scaffold(
      backgroundColor: notifire.getbgcolor,
      appBar: AppBar(
        title: const Text('KYC Verification'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: BackButton(
          color: notifire.getwhiteblackcolor,
          onPressed: () {
            Get.back();
          },
        ),
        actions: widget.showSkipOption
            ? [
                TextButton(
                  onPressed: widget.onSkip,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImportantInfoCard(),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final key = documents.keys.elementAt(index);
                final doc = documents[key]!;
                return _buildDocumentCard(key, doc);
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildImportantInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Notice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete KYC verification to list your properties. Unverified partners\' listings will not be visible to users.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String key, DocumentData doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doc.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (doc.approvalStatus != null)
                _buildStatusBadge(doc.approvalStatus!),
            ],
          ),
          const SizedBox(height: 16),
          _buildUploadBox(key, doc),
          if (doc.approvalStatus == ApprovalStatus.rejected &&
              doc.rejectionReason != null)
            _buildRejectionReasonBox(doc.rejectionReason!),
        ],
      ),
    );
  }

  Widget _buildUploadBox(String key, DocumentData doc) {
    final hasDocument = doc.filePath != null || doc.networkUrl != null;

    return GestureDetector(
      onTap: () => _pickDocument(key),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: hasDocument ? primaryColor : Colors.grey[400]!,
            width: hasDocument ? 2 : 1,
            style: hasDocument
                ? BorderStyle.solid
                : BorderStyle.values[1], // dotted effect
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasDocument ? Colors.grey[100] : Colors.grey[50],
        ),
        child: hasDocument
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: doc.filePath != null
                        ? Image.file(
                            File(doc.filePath!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            doc.networkUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.white, size: 20),
                        onPressed: () => _pickDocument(key),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 70,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.cancel, color: primaryColor, size: 20),
                        onPressed: () => _removeDocument(key),
                      ),
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to upload document',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG or JPEG (Max 5MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusBadge(ApprovalStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case ApprovalStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.schedule;
        label = 'Pending';
        break;
      case ApprovalStatus.approved:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle;
        label = 'Approved';
        break;
      case ApprovalStatus.rejected:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel;
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReasonBox(String reason) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejection Reason',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[900],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final allDocumentsUploaded = documents.values.every(
      (doc) => doc.filePath != null || doc.networkUrl != null,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: allDocumentsUploaded ? _submitDocuments : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            disabledBackgroundColor: Colors.grey[300],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Submit for Verification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDocument(String key) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        documents[key] = documents[key]!.copyWith(
          filePath: image.path,
          approvalStatus: ApprovalStatus.pending,
        );
      });
    }
  }

  Future<void> _removeDocument(String key) async {
    setState(() {
      documents[key] = documents[key]!.copyWith(
        filePath: null,
        approvalStatus: ApprovalStatus.pending,
      );
    });
  }

  void _submitDocuments() {
    // Implement submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Documents submitted for verification'),
        backgroundColor: primaryColor,
      ),
    );
  }
}

enum ApprovalStatus { pending, approved, rejected }

class DocumentData {
  final String title;
  final String description;
  final String? filePath;
  final String? networkUrl;
  final ApprovalStatus? approvalStatus;
  final String? rejectionReason;

  DocumentData({
    required this.title,
    required this.description,
    this.filePath,
    this.networkUrl,
    this.approvalStatus,
    this.rejectionReason,
  });

  DocumentData copyWith({
    String? title,
    String? description,
    String? filePath,
    String? networkUrl,
    ApprovalStatus? approvalStatus,
    String? rejectionReason,
  }) {
    return DocumentData(
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      networkUrl: networkUrl ?? this.networkUrl,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
