import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Snapshot lokasi yang akan dikirim ke backend.
class LocationSnapshot {
  final double latitude;
  final double longitude;
  final double? accuracy; // dalam meter
  final double? altitude;
  final String? address; // alamat hasil reverse geocoding (opsional)

  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.address,
  });

  /// Koordinat presisi 6 desimal (~0.11 m) untuk disimpan di Firestore.
  Map<String, dynamic> toMap({bool includeAddress = true}) {
    final m = <String, dynamic>{
      'lat': _round6(latitude),
      'lng': _round6(longitude),
      'accuracy': accuracy,
      'captured_at': DateTime.now().toIso8601String(),
    };
    if (includeAddress && address != null && address!.isNotEmpty) {
      m['address'] = address;
    }
    return m;
  }

  static double _round6(double v) => double.parse(v.toStringAsFixed(6));

  String get latLngLabel =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

/// Service pembungkus geolocator + geocoding agar UI tinggal panggil satu method.
class LocationService {
  static const Duration _timeout = Duration(seconds: 20);

  /// Meminta izin, lalu mengambil posisi saat ini.
  /// Mengembalikan null jika pengguna menolak / layanan tidak tersedia / timeout.
  static Future<LocationSnapshot?> getCurrent({
    bool withAddress = true,
  }) async {
    try {
      // 1) Layanan lokasi nyala?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // 2) Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // 3) Ambil posisi
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        ),
      );

      // 4) Reverse geocode (best-effort; jangan gagalkan snapshot)
      String? address;
      if (withAddress) {
        try {
          final placemarks = await placemarkFromCoordinates(
            pos.latitude,
            pos.longitude,
          ).timeout(const Duration(seconds: 6));
          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            address = _formatAddress(pm);
          }
        } catch (_) {
          // fallback: tidak fatal
        }
      }

      return LocationSnapshot(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        address: address,
      );
    } catch (_) {
      return null;
    }
  }

  static String _formatAddress(Placemark pm) {
    final parts = <String>[
      if ((pm.name ?? '').isNotEmpty) pm.name!,
      if ((pm.subLocality ?? '').isNotEmpty) pm.subLocality!,
      if ((pm.locality ?? '').isNotEmpty) pm.locality!,
      if ((pm.subAdministrativeArea ?? '').isNotEmpty) pm.subAdministrativeArea!,
      if ((pm.administrativeArea ?? '').isNotEmpty) pm.administrativeArea!,
      if ((pm.postalCode ?? '').isNotEmpty) pm.postalCode!,
      if ((pm.country ?? '').isNotEmpty) pm.country!,
    ];
    return parts.join(', ');
  }
}
