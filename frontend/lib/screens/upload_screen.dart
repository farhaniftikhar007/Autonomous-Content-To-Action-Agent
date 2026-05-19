import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/upload_service.dart';
import '../services/command_center_provider.dart';
import '../services/error_handler.dart';
import '../widgets/resilient_widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final UploadService _uploadService = UploadService();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _feedController = TextEditingController();
  
  bool _isUploading = false;
  double _progress = 0.0;
  String _statusMessage = "";

  // Production-grade resilient upload retry states
  AppError? _uploadError;
  PlatformFile? _lastSelectedFile;
  String? _lastUploadType;

  void _showErrorSnackBar(AppError appError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ingestion alert: ${appError.message}"),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: "RETRY",
          textColor: Colors.white,
          onPressed: () {
            print("[DEBUG] [UploadScreen] Retry triggered via SnackBar action.");
            _retryLastUpload();
          },
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: type == 'pdf' ? ['pdf'] : ['csv'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.single;
      final fileName = file.name;
      final fileSize = file.size;

      print("[DEBUG] [UploadScreen] Selection Ingestion: File: $fileName | Size: $fileSize bytes | Ingest Type: $type");

      setState(() {
        _isUploading = true;
        _uploadError = null;
        _progress = 0.0;
        _statusMessage = "Uploading $fileName...";
        _lastSelectedFile = file;
        _lastUploadType = type;
      });

      try {
        if (kIsWeb) {
          final bytes = file.bytes;
          if (bytes == null) {
            throw Exception("Byte Stream Interrupted: Could not populate file memory bytes on Web client.");
          }
          await _uploadService.uploadFile(
            bytes: bytes,
            fileName: fileName,
            endpoint: type == 'pdf' ? '/upload/pdf' : '/upload/csv',
            onProgress: (p) => setState(() => _progress = p),
          );
        } else {
          final path = file.path;
          if (path == null) {
            throw Exception("Local Access Interrupted: System failed to resolve local physical storage path.");
          }
          await _uploadService.uploadFile(
            filePath: path,
            fileName: fileName,
            endpoint: type == 'pdf' ? '/upload/pdf' : '/upload/csv',
            onProgress: (p) => setState(() => _progress = p),
          );
        }

        setState(() {
          _isUploading = false;
          _uploadError = null;
          _statusMessage = "Success! Data processed and ingested.";
        });
        
        print("[VERIFICATION] [UploadScreen] Ingestion complete. Invoking provider cache clear and instant hot refresh...");
        final provider = Provider.of<CommandCenterProvider>(context, listen: false);
        provider.clearSimulationAndImpact();
        provider.forceInstantRefresh();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ingestion gateway processed data feed successfully."),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("[DEBUG] [UploadScreen] Ingestion failure: $e");
        final appErr = AppErrorHandler.handle(e);
        setState(() {
          _isUploading = false;
          _uploadError = appErr;
          _statusMessage = "Ingestion error: ${appErr.message}";
        });
        _showErrorSnackBar(appErr);
      }
    }
  }

  Future<void> _retryLastUpload() async {
    if (_lastSelectedFile == null || _lastUploadType == null) return;
    final file = _lastSelectedFile!;
    final type = _lastUploadType!;
    final fileName = file.name;

    setState(() {
      _isUploading = true;
      _uploadError = null;
      _progress = 0.0;
      _statusMessage = "Retrying upload of $fileName...";
    });

    try {
      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) {
          throw Exception("Byte Stream Interrupted: Could not populate file bytes.");
        }
        await _uploadService.uploadFile(
          bytes: bytes,
          fileName: fileName,
          endpoint: type == 'pdf' ? '/upload/pdf' : '/upload/csv',
          onProgress: (p) => setState(() => _progress = p),
        );
      } else {
        final path = file.path;
        if (path == null) {
          throw Exception("Local Access Interrupted: Failed to resolve local path.");
        }
        await _uploadService.uploadFile(
          filePath: path,
          fileName: fileName,
          endpoint: type == 'pdf' ? '/upload/pdf' : '/upload/csv',
          onProgress: (p) => setState(() => _progress = p),
        );
      }

      setState(() {
        _isUploading = false;
        _uploadError = null;
        _statusMessage = "Success! Ingest completed on retry.";
      });

      print("[VERIFICATION] [UploadScreen] Ingest retry complete. Clearing cache and hot-refreshing...");
      final provider = Provider.of<CommandCenterProvider>(context, listen: false);
      provider.clearSimulationAndImpact();
      provider.forceInstantRefresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingestion completed successfully on retry!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      final appErr = AppErrorHandler.handle(e);
      setState(() {
        _isUploading = false;
        _uploadError = appErr;
        _statusMessage = "Retry Ingestion error: ${appErr.message}";
      });
      _showErrorSnackBar(appErr);
    }
  }

  Future<void> _submitUrl() async {
    if (_urlController.text.isEmpty) return;
    setState(() {
      _isUploading = true;
      _uploadError = null;
      _statusMessage = "Analyzing online source endpoint...";
    });
    try {
      await _uploadService.analyzeUrl(_urlController.text);
      setState(() {
        _isUploading = false;
        _uploadError = null;
        _statusMessage = "URL intelligence scrap completed successfully!";
        _urlController.clear();
      });
      
      print("[VERIFICATION] [UploadScreen] URL Intel complete. Clearing cache and hot-refreshing...");
      final provider = Provider.of<CommandCenterProvider>(context, listen: false);
      provider.clearSimulationAndImpact();
      provider.forceInstantRefresh();
    } catch (e) {
      final appErr = AppErrorHandler.handle(e);
      setState(() {
        _isUploading = false;
        _uploadError = appErr;
        _statusMessage = "Scrape error: ${appErr.message}";
      });
      _showErrorSnackBar(appErr);
    }
  }

  Future<void> _submitLiveFeed() async {
    if (_feedController.text.isEmpty) return;
    setState(() {
      _isUploading = true;
      _uploadError = null;
      _statusMessage = "Broadcasting live feed stream event...";
    });
    try {
      await _uploadService.sendLiveFeed(
        source: "Dashboard Manual Terminal Ingestion",
        content: _feedController.text,
        credibility: 0.85,
      );
      setState(() {
        _isUploading = false;
        _uploadError = null;
        _statusMessage = "Live feed broadcast complete!";
        _feedController.clear();
      });
      
      print("[VERIFICATION] [UploadScreen] Live Feed broadcast complete. Clearing cache and hot-refreshing...");
      final provider = Provider.of<CommandCenterProvider>(context, listen: false);
      provider.clearSimulationAndImpact();
      provider.forceInstantRefresh();
    } catch (e) {
      final appErr = AppErrorHandler.handle(e);
      setState(() {
        _isUploading = false;
        _uploadError = appErr;
        _statusMessage = "Broadcast error: ${appErr.message}";
      });
      _showErrorSnackBar(appErr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F15),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
              ),
              child: const Icon(Icons.cloud_upload, color: Color(0xFF00E5FF), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              "INGESTION GATEWAY",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF00E5FF).withOpacity(0.15),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_uploadError != null) ...[
              ErrorCard(
                title: "INGESTION ATTEMPT BLOCKED",
                error: _uploadError,
                onRetry: _retryLastUpload,
              ),
              const SizedBox(height: 16),
            ],
            if (_isUploading) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _progress, color: const Color(0xFF00E5FF), backgroundColor: Colors.white10),
              const SizedBox(height: 16),
            ],
            if (_statusMessage.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains("error") 
                      ? const Color(0xFF1A0B0B) 
                      : const Color(0xFF0B1A0F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains("error")
                        ? Colors.redAccent.withOpacity(0.3)
                        : Colors.greenAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage.contains("error") ? Icons.error_outline : Icons.check_circle_outline,
                      color: _statusMessage.contains("error") ? Colors.redAccent : Colors.greenAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains("error") ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildUploadCard(
              title: "PDF Ingestion",
              subtitle: "Upload official reports, manifests and supply documentation",
              icon: Icons.picture_as_pdf,
              color: Colors.redAccent,
              onTap: () => _pickAndUpload('pdf'),
            ),
            const SizedBox(height: 16),
            _buildUploadCard(
              title: "CSV Ingestion",
              subtitle: "Import warehouse stocks lists, reorders and ledger dumps",
              icon: Icons.table_chart,
              color: Colors.greenAccent,
              onTap: () => _pickAndUpload('csv'),
            ),
            const SizedBox(height: 24),
            _buildInputSection(
              title: "URL SCRAPER INTEL",
              controller: _urlController,
              hint: "https://shipping-news.org/strike-report",
              icon: Icons.link_rounded,
              btnText: "SCAN ENDPOINT",
              onPressed: _submitUrl,
            ),
            const SizedBox(height: 20),
            _buildInputSection(
              title: "REAL-TIME LOGISTICS EVENT",
              controller: _feedController,
              hint: "e.g., Warehouse shortage or delay warning parsed dynamically...",
              icon: Icons.rss_feed_rounded,
              btnText: "BROADCAST FIELD REPORT",
              onPressed: _submitLiveFeed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF14141F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.01),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white38, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.cloud_upload_outlined, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String btnText,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF00E5FF), letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            prefixIcon: Icon(icon, color: Colors.white38, size: 18),
            filled: true,
            fillColor: const Color(0xFF14141F),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00E5FF)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
              foregroundColor: const Color(0xFF00E5FF),
              side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              btnText,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}
