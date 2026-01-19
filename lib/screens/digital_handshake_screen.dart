import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/theme/app_theme.dart';

class DigitalHandshakeScreen extends StatefulWidget {
  final String? jobId;
  final String? userId; // Contractor or Homeowner ID
  final bool isContractor;

  const DigitalHandshakeScreen({
    super.key, 
    this.jobId = 'JOB-12345-MOCK', 
    this.userId = 'USER-789',
    this.isContractor = false,
  });

  @override
  State<DigitalHandshakeScreen> createState() => _DigitalHandshakeScreenState();
}

class _DigitalHandshakeScreenState extends State<DigitalHandshakeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MobileScannerController _scannerController = MobileScannerController();
  bool _handshakeComplete = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onScan(BarcodeCapture capture) {
    if (_handshakeComplete) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        // In a real app, verify the code matches the Job ID cryptographically
        debugPrint('Scanned: ${barcode.rawValue}');
        
        setState(() {
          _handshakeComplete = true;
        });
        
        // Haptic check would go here
        
        _showSuccessDialog();
        break; 
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 80)
                  .animate().scale(curve: Curves.elasticOut, duration: 800.ms),
              const SizedBox(height: 24),
              Text(
                'Handshake Verified!',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isContractor 
                  ? 'Funds have been released to your wallet.' 
                  : 'Job marked as complete. Warranty active.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close screen
                  },
                  child: const Text('Done', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Digital Handshake', style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00E5FF),
          tabs: const [
             Tab(icon: Icon(Icons.qr_code), text: "My Code"),
             Tab(icon: Icon(Icons.camera_alt), text: "Scan Partner"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCodeTab(),
          _buildScannerTab(),
        ],
      ),
    );
  }

  Widget _buildMyCodeTab() {
    // Payload: protocol://handshake/jobId/userId
    final qrData = "rap://handshake/${widget.jobId}/${widget.userId}";

    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 10))
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ).animate().flip(duration: 600.ms),
            const SizedBox(height: 48),
            Text(
              "Job ID: ${widget.jobId}",
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              "Show this to ${widget.isContractor ? 'Homeowner' : 'Contractor'} to verify.",
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Icon(Icons.nfc, color: Color(0xFF00E5FF), size: 40).animate(onPlay: (c) => c.repeat(reverse: true)).fade(),
            const SizedBox(height: 8),
            Text("NFC Active", style: GoogleFonts.inter(color: const Color(0xFF00E5FF), fontSize: 12))
          ],
        ),
    );
  }

  Widget _buildScannerTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onScan,
        ),
        // Overlay
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00E5FF), width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Text(
            "Align partner's code in frame",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [
               const Shadow(color: Colors.black, blurRadius: 10),
            ]),
          ),
        )
      ],
    );
  }
}
