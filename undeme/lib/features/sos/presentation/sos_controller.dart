import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

import '../../../core/config/app_config.dart';
import '../data/offline_sos_queue.dart';
import '../data/sos_repository.dart';
import '../domain/sos_location.dart';

enum SosPhase {
  idle,
  countdown,
  sending,
  success,
  queuedOffline,
  error,
}

class SosController extends ChangeNotifier {
  SosController({
    SosRepository? repository,
    OfflineSosQueue? offlineQueue,
    Connectivity? connectivity,
  })  : _repository = repository ?? SosRepository(),
        _offlineQueue = offlineQueue ?? OfflineSosQueue.instance,
        _connectivity = connectivity ?? Connectivity();

  final SosRepository _repository;
  final OfflineSosQueue _offlineQueue;
  final Connectivity _connectivity;

  SosPhase phase = SosPhase.idle;
  int countdown = AppConfig.sosCountdownSeconds;
  int pendingQueueCount = 0;
  int completedSosCount = 0;
  SosLocation? lastLocation;
  String lastReason = '';
  String lastSosMessage = '';
  String statusMessage = 'Ұзақ басып тұрыңыз';

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _disposed = false;

  Future<void> init() async {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((item) => item != ConnectivityResult.none)) {
        flushQueue();
      }
    });

    pendingQueueCount = (await _offlineQueue.load()).length;
    _notify();
    await flushQueue();
  }

  Future<void> startCountdown({String reason = ''}) async {
    if (phase == SosPhase.sending || phase == SosPhase.countdown) {
      return;
    }

    await _vibrate(80);

    phase = SosPhase.countdown;
    countdown = AppConfig.sosCountdownSeconds;
    statusMessage = 'SOS $countdown сек кейін жіберіледі';
    _notify();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      countdown -= 1;

      if (countdown <= 0) {
        timer.cancel();
        await triggerSos(reason: reason);
        return;
      }

      statusMessage = 'SOS $countdown сек кейін жіберіледі';
      _notify();
    });
  }

  void cancelCountdown() {
    if (phase != SosPhase.countdown) {
      return;
    }

    _timer?.cancel();
    phase = SosPhase.idle;
    countdown = AppConfig.sosCountdownSeconds;
    statusMessage = 'SOS тоқтатылды';
    _notify();
  }

  Future<void> triggerSos({String reason = ''}) async {
    _timer?.cancel();
    phase = SosPhase.sending;
    statusMessage = 'Орын анықталып, хабарлама жіберілуде...';
    _notify();

    try {
      final location = await _resolveLocation();
      lastLocation = location;
      lastReason = reason;
      lastSosMessage = _buildManualShareMessage(location: location, reason: reason);
      final isOnline = await _isOnline();

      if (!isOnline) {
        await _queueOffline(location: location, reason: reason);
        return;
      }

      Object? lastError;
      var backendReachable = false;
      for (int attempt = 1; attempt <= AppConfig.sosSendRetries; attempt++) {
        try {
          await _repository.triggerSos(
              location: location, reason: reason, force: attempt > 1);
          backendReachable = true;
          break;
        } catch (error) {
          lastError = error;
        }
      }

      await _vibrate(250);
      phase = SosPhase.success;
      if (backendReachable) {
        statusMessage = 'SOS дайын. WhatsApp арқылы қолмен жіберіңіз';
      } else {
        statusMessage =
            'SOS дайын. WhatsApp арқылы қолмен жіберіңіз (backend уақытша қолжетімсіз)';
        if (kDebugMode && lastError != null) {
          debugPrint('SOS backend sync failed: $lastError');
        }
      }
      completedSosCount += 1;
      _notify();
    } catch (error) {
      phase = SosPhase.error;
      statusMessage = error.toString().replaceFirst('Exception: ', '');
      _notify();
    }
  }

  Future<void> flushQueue() async {
    final items = await _offlineQueue.load();
    pendingQueueCount = items.length;
    _notify();

    if (items.isEmpty) {
      return;
    }

    if (!await _isOnline()) {
      return;
    }

    final remaining = <PendingSosItem>[];

    for (final item in items) {
      try {
        await _repository.triggerSos(
          location: item.location,
          reason: item.reason,
          force: true,
        );
      } catch (_) {
        if (item.attempt < AppConfig.sosSendRetries) {
          remaining.add(item.copyWith(attempt: item.attempt + 1));
        }
      }
    }

    await _offlineQueue.save(remaining);
    pendingQueueCount = remaining.length;
    _notify();
  }

  bool get hasPendingQueue => pendingQueueCount > 0;

  Future<void> _queueOffline(
      {required SosLocation location, required String reason}) async {
    await _offlineQueue.enqueue(
      PendingSosItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        location: location,
        reason: reason,
        createdAt: DateTime.now(),
      ),
    );
    pendingQueueCount += 1;
    lastLocation = location;
    lastReason = reason;
    lastSosMessage = _buildManualShareMessage(location: location, reason: reason);

    phase = SosPhase.queuedOffline;
    statusMessage = 'Интернет жоқ. SOS кезекке қойылды';
    completedSosCount += 1;
    _notify();
  }

  String _buildManualShareMessage({
    required SosLocation location,
    required String reason,
  }) {
    final mapsUrl = 'https://maps.google.com/?q=${location.latitude},${location.longitude}';

    return [
      '🚨 UNDEME SOS',
      if (reason.trim().isNotEmpty) 'Себеп: ${reason.trim()}',
      'Орналасуы: $mapsUrl',
      'Уақыты: ${DateTime.now().toIso8601String()}',
      'Егер тікелей қауіп болса, 112 нөміріне дереу хабарласыңыз.',
    ].join('\n');
  }

  Future<SosLocation> _resolveLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Геолокация қосылмаған');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Геолокация рұқсаты берілмеген');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return SosLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      provider: position.isMocked ? 'mock' : 'gps',
      capturedAt: position.timestamp,
    );
  }

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((item) => item != ConnectivityResult.none);
  }

  Future<void> _vibrate(int durationMs) async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: durationMs);
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
