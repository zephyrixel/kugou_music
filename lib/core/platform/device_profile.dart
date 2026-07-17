import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceProfile {
  const DeviceProfile({
    required this.deviceId,
    this.androidId,
    this.brand,
    this.model,
    this.manufacturer,
    this.basebandVersion,
    this.availableRamBytes,
    this.availableInternalStorageBytes,
    this.availableExternalStorageBytes,
    this.batteryLevel,
    this.batteryStatus,
    this.hasAccelerometer = false,
    this.hasGravity = false,
    this.hasGyroscope = false,
    this.hasLight = false,
    this.hasMagneticField = false,
    this.hasOrientation = false,
    this.hasPressure = false,
    this.hasStepCounter = false,
    this.hasAmbientTemperature = false,
  });

  final String deviceId;
  final String? androidId;
  final String? brand;
  final String? model;
  final String? manufacturer;
  final String? basebandVersion;
  final int? availableRamBytes;
  final int? availableInternalStorageBytes;
  final int? availableExternalStorageBytes;
  final int? batteryLevel;
  final int? batteryStatus;
  final bool hasAccelerometer;
  final bool hasGravity;
  final bool hasGyroscope;
  final bool hasLight;
  final bool hasMagneticField;
  final bool hasOrientation;
  final bool hasPressure;
  final bool hasStepCounter;
  final bool hasAmbientTemperature;
}

abstract interface class DeviceProfileSource {
  Future<DeviceProfile> read();
}

class AndroidDeviceProfileSource implements DeviceProfileSource {
  AndroidDeviceProfileSource(this._storage);

  static const _channel = MethodChannel(
    'com.zephyrixel.kgmusic/device_profile',
  );
  static const _installIdKey = 'kgmusic_install_device_id_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<DeviceProfile> read() async {
    Map<Object?, Object?> facts = const {};
    if (Platform.isAndroid) {
      try {
        facts =
            await _channel.invokeMapMethod<Object?, Object?>('read') ??
            const {};
      } on PlatformException {
        facts = const {};
      } on MissingPluginException {
        facts = const {};
      }
    }

    final androidId = normalizeAndroidDeviceId(facts['androidId']);
    final deviceId = androidId ?? await _persistentInstallId();
    return DeviceProfile(
      deviceId: deviceId,
      androidId: androidId,
      brand: _string(facts['brand']),
      model: _string(facts['model']),
      manufacturer: _string(facts['manufacturer']),
      basebandVersion: _string(facts['basebandVersion']),
      availableRamBytes: _integer(facts['availableRamBytes']),
      availableInternalStorageBytes: _integer(
        facts['availableInternalStorageBytes'],
      ),
      availableExternalStorageBytes: _integer(
        facts['availableExternalStorageBytes'],
      ),
      batteryLevel: _integer(facts['batteryLevel']),
      batteryStatus: _integer(facts['batteryStatus']),
      hasAccelerometer: facts['hasAccelerometer'] == true,
      hasGravity: facts['hasGravity'] == true,
      hasGyroscope: facts['hasGyroscope'] == true,
      hasLight: facts['hasLight'] == true,
      hasMagneticField: facts['hasMagneticField'] == true,
      hasOrientation: facts['hasOrientation'] == true,
      hasPressure: facts['hasPressure'] == true,
      hasStepCounter: facts['hasStepCounter'] == true,
      hasAmbientTemperature: facts['hasAmbientTemperature'] == true,
    );
  }

  Future<String> _persistentInstallId() async {
    final existing = _string(await _storage.read(key: _installIdKey));
    if (existing != null) return existing;
    final random = Random.secure();
    final generated = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _storage.write(key: _installIdKey, value: generated);
    return generated;
  }
}

String? _string(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'unknown') return null;
  return text;
}

String? normalizeAndroidDeviceId(Object? value) {
  final id = _string(value);
  final normalized = id?.toLowerCase();
  if (id == null ||
      normalized == '9774d56d682e549c' ||
      RegExp(r'^0+$').hasMatch(normalized!)) {
    return null;
  }
  return id;
}

int? _integer(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};
