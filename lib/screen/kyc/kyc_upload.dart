// ignore_for_file: deprecated_member_use

// Screen
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'dart:io';

import 'package:opendoors/screen/kyc/widget2/kyc_controller.dart';
import 'package:opendoors/screen/kyc/widget2/kyc_model.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KYCAuthScreen extends StatefulWidget {
  final bool showSkipOption;
  final VoidCallback? onSkip;
  final int userId;

  const KYCAuthScreen({
    super.key,
    this.showSkipOption = false,
    this.onSkip,
    required this.userId,
  });

  @override
  State<KYCAuthScreen> createState() => _KYCAuthScreenState();
}

class _KYCAuthScreenState extends State<KYCAuthScreen> {
  late ColorNotifire notifire;
  KYC2Controller controller = Get.find<KYC2Controller>();

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
      //  backgroundColor: notifire.getbgcolor,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('KYC Verification'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: widget.showSkipOption
            ? [
                TextButton(
                  onPressed: widget.onSkip,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: controller.primaryColor),
                  ),
                ),
              ]
            : null,
      ),
      body: Obx(() {
        if (controller.isLoadingRequirements.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildOverallStatusBar(controller),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: () => controller.fetchMyDocuments().then((_) {
                  setState(() {});
                }),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildImportantInfoCard(controller),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.requiredDocuments.length,
                        itemBuilder: (context, index) {
                          final doc = controller.requiredDocuments[index];
                          return _buildDocumentCard(controller, doc);
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: _buildSubmitButton(controller, widget.onSkip),
    );
  }

  Widget _buildOverallStatusBar(KYC2Controller controller) {
    return Obx(() {
      final status = controller.overallStatus.value;
      Color backgroundColor;
      Color textColor;
      IconData icon;
      String message;

      switch (status) {
        case 'approved':
          backgroundColor = Colors.green;
          textColor = Colors.white;
          icon = Icons.check_circle;
          message = 'All documents approved';
          break;
        case 'pending':
          backgroundColor = Colors.orange;
          textColor = Colors.white;
          icon = Icons.schedule;
          message = 'Documents under review';
          break;
        case 'rejected':
          backgroundColor = Colors.red;
          textColor = Colors.white;
          icon = Icons.error;
          message = 'Some documents need attention';
          break;
        default:
          backgroundColor = Colors.grey;
          textColor = Colors.white;
          icon = Icons.upload_file;
          message = 'Upload required documents';
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildImportantInfoCard(KYC2Controller controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: controller.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: controller.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: controller.primaryColor, size: 24),
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
                    color: controller.primaryColor,
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

  Widget _buildDocumentCard(
      KYC2Controller controller, DocumentRequirement doc) {
    final status = controller.getDocumentStatus(doc.name);
    final rejectionReason = controller.getRejectionReason(doc.name);

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
                      doc.name,
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
              if (status != 'not_uploaded')
                _buildStatusBadge(controller, status),
            ],
          ),
          const SizedBox(height: 16),
          if (doc.isMultiple)
            _buildMultipleUploadBox(controller, doc)
          else
            _buildSingleUploadBox(controller, doc),
          if (status == 'rejected' && rejectionReason != null)
            _buildRejectionReasonBox(controller, rejectionReason),
        ],
      ),
    );
  }

  Widget _buildSingleUploadBox(
      KYC2Controller controller, DocumentRequirement doc) {
    return Obx(() {
      final hasLocalFile = controller.hasLocalFile(doc.name);
      final hasUploadedFile = controller.hasUploadedFile(doc.name);
      final uploadedUrl = controller.getUploadedFileUrl(doc.name);
      final localFile = controller.localFiles[doc.name]?['single'];

      return GestureDetector(
        onTap: () => controller.pickDocument(doc.name, doc).then((_) {
          // setState to refresh UI after picking document
          log('Picked document for ${doc.name}, refreshing UI');
          setState(() {});
        }),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: (hasLocalFile || hasUploadedFile)
                  ? controller.primaryColor
                  : Colors.grey[400]!,
              width: (hasLocalFile || hasUploadedFile) ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: (hasLocalFile || hasUploadedFile)
                ? Colors.grey[100]
                : Colors.grey[50],
          ),
          child: (hasLocalFile || hasUploadedFile)
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasLocalFile && localFile != null
                          ? (controller.isPdf(localFile)
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.picture_as_pdf,
                                          size: 64, color: Colors.red[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        localFile.path.split('/').last,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700]),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                )
                              : Image.file(
                                  localFile,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ))
                          : (uploadedUrl!.toLowerCase().endsWith('.pdf')
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.picture_as_pdf,
                                          size: 64, color: Colors.red[400]),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'PDF Document',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              : Image.network(
                                  uploadedUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(Icons.insert_drive_file,
                                          size: 48, color: Colors.grey[400]),
                                    );
                                  },
                                )),
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
                          onPressed: () =>
                              controller.pickDocument(doc.name, doc),
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
                      Icon(Icons.cloud_upload_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to upload document',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doc.acceptableFileTypes.map((t) => t.toUpperCase()).join(', ')} (Max 5MB)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildMultipleUploadBox(
      KYC2Controller controller, DocumentRequirement doc) {
    return Obx(() {
      return Row(
        children: [
          Expanded(
              child:
                  _buildMultipleUploadItem(controller, doc, 'front', 'Front')),
          const SizedBox(width: 12),
          Expanded(
              child: _buildMultipleUploadItem(controller, doc, 'back', 'Back')),
        ],
      );
    });
  }

  Widget _buildMultipleUploadItem(
    KYC2Controller controller,
    DocumentRequirement doc,
    String type,
    String label,
  ) {
    final hasLocalFile = controller.hasLocalFile(doc.name, type: type);
    final hasUploadedFile = controller.hasUploadedFile(doc.name, type: type);
    final uploadedUrl = controller.getUploadedFileUrl(doc.name, type: type);
    final localFile = controller.localFiles[doc.name]?[type];

    // print(hasUploadedFile);
    // print(doc.name);
    // print(doc.)

    return GestureDetector(
      onTap: () => controller.pickDocument(doc.name, doc, type: type).then((_) {
        // setState to refresh UI after picking document
        setState(() {});
      }),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: (hasLocalFile || hasUploadedFile)
                ? controller.primaryColor
                : Colors.grey[400]!,
            width: (hasLocalFile || hasUploadedFile) ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: (hasLocalFile || hasUploadedFile)
              ? Colors.grey[100]
              : Colors.grey[50],
        ),
        child: (hasLocalFile || hasUploadedFile)
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasLocalFile && localFile != null
                        ? (controller.isPdf(localFile)
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.picture_as_pdf,
                                        size: 48, color: Colors.red[400]),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PDF',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              )
                            : Image.file(
                                localFile,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ))
                        : (uploadedUrl!.toLowerCase().endsWith('.pdf')
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.picture_as_pdf,
                                        size: 48, color: Colors.red[400]),
                                    const SizedBox(height: 4),
                                    const Text('PDF',
                                        style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                              )
                            : Image.network(
                                uploadedUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(Icons.insert_drive_file,
                                        size: 36, color: Colors.grey[400]),
                                  );
                                },
                              )),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.white, size: 16),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 30, minHeight: 30),
                        onPressed: () =>
                            controller.pickDocument(doc.name, doc, type: type),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 36, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton(KYC2Controller controller, Function? onSkip) {
    return Obx(() {
      final canSubmit = controller.canSubmit();

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
            onPressed: canSubmit && !controller.isUploading.value
                ? () => controller.submitAllDocuments(widget.userId).then((_) {
                      log('closing!!');
                      Navigator.of(context).pop();
                    })
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.primaryColor,
              disabledBackgroundColor: Colors.grey[300],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: controller.isUploading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit All Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildStatusBadge(KYC2Controller controller, String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    print('Building status badge for status: $status');

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.schedule;
        label = 'Pending';
        break;
      case 'approved':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle;
        label = 'Approved';
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel;
        label = 'Rejected';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        icon = Icons.upload_file;
        label = 'Not Uploaded';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReasonBox(KYC2Controller controller, String reason) {
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
}
