// TEMPORARILY DISABLED - SUMSUB KYC
// Preserved data structures for future restoration; no active route uses them.
enum KycDocumentType { passport, idCard, drivingLicence }

enum KycCaptureSide { front, back }

/// Mutable state passed through the KYC ID capture flow.
class KycFlowData {
  KycDocumentType? documentType;
  String? frontImagePath;
  String? backImagePath;
  String? selfieImagePath;
  bool livenessCheckPassed = false;

  bool get needsBackSide =>
      documentType == KycDocumentType.idCard ||
      documentType == KycDocumentType.drivingLicence;

  bool get idDocumentComplete {
    if (frontImagePath == null || documentType == null) return false;
    if (!needsBackSide) return true;
    return backImagePath != null;
  }

  bool get selfieComplete => selfieImagePath != null && livenessCheckPassed;

  bool get verificationComplete => idDocumentComplete && selfieComplete;

  bool isDemoVerification = false;

  static const demoImageToken = 'demo://kyc-image';

  /// Fills demo ID document state without opening the camera.
  void applyDemoIdDocument() {
    documentType = KycDocumentType.passport;
    frontImagePath = demoImageToken;
    backImagePath = null;
    isDemoVerification = true;
  }

  /// Fills demo selfie / liveness state without opening the camera.
  void applyDemoSelfie() {
    livenessCheckPassed = true;
    selfieImagePath = demoImageToken;
    isDemoVerification = true;
  }

  /// Marks both KYC steps complete with static demo data.
  void applyDemoVerification() {
    applyDemoIdDocument();
    applyDemoSelfie();
  }

  String get documentTypeLabel => switch (documentType) {
        KycDocumentType.passport => 'Passport',
        KycDocumentType.idCard => 'ID card',
        KycDocumentType.drivingLicence => 'Driving licence',
        null => 'Government ID',
      };

  String sideLabel(KycCaptureSide side) => switch (side) {
        KycCaptureSide.front => needsBackSide ? 'Front of document' : 'Photo of document',
        KycCaptureSide.back => 'Back of document',
      };

  String? imagePathFor(KycCaptureSide side) =>
      side == KycCaptureSide.front ? frontImagePath : backImagePath;

  void setImagePath(KycCaptureSide side, String path) {
    if (side == KycCaptureSide.front) {
      frontImagePath = path;
    } else {
      backImagePath = path;
    }
  }

  KycCaptureSide? get nextCaptureSide {
    if (documentType == null) return null;
    if (frontImagePath == null) return KycCaptureSide.front;
    if (needsBackSide && backImagePath == null) return KycCaptureSide.back;
    return null;
  }
}

class KycCaptureRouteArgs {
  const KycCaptureRouteArgs({required this.flow, required this.side});

  final KycFlowData flow;
  final KycCaptureSide side;
}

class KycPreviewRouteArgs {
  const KycPreviewRouteArgs({
    required this.flow,
    required this.side,
    required this.imagePath,
  });

  final KycFlowData flow;
  final KycCaptureSide side;
  final String imagePath;
}

class KycSelfiePreviewRouteArgs {
  const KycSelfiePreviewRouteArgs({
    required this.flow,
    required this.imagePath,
  });

  final KycFlowData flow;
  final String imagePath;
}
