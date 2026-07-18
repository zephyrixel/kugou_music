import 'package:shared_preferences/shared_preferences.dart';

typedef PreferenceDecoder<T> = T? Function(Object? value);
typedef PreferenceEncoder<T> = Object Function(T value);

class PreferenceKey<T> {
  const PreferenceKey({
    required this.name,
    required this.defaultValue,
    required this.decode,
    required this.encode,
  });

  final String name;
  final T defaultValue;
  final PreferenceDecoder<T> decode;
  final PreferenceEncoder<T> encode;
}

abstract interface class PreferenceStore {
  Future<T> read<T>(PreferenceKey<T> key);
  Future<void> write<T>(PreferenceKey<T> key, T value);
}

class SharedPreferenceStore implements PreferenceStore {
  SharedPreferenceStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<T> read<T>(PreferenceKey<T> key) async {
    final values = await _preferences.getAll(allowList: {key.name});
    return key.decode(values[key.name]) ?? key.defaultValue;
  }

  @override
  Future<void> write<T>(PreferenceKey<T> key, T value) {
    final encoded = key.encode(value);
    return switch (encoded) {
      bool value => _preferences.setBool(key.name, value),
      int value => _preferences.setInt(key.name, value),
      double value => _preferences.setDouble(key.name, value),
      String value => _preferences.setString(key.name, value),
      List<String> value => _preferences.setStringList(key.name, value),
      _ => throw UnsupportedError(
        'Unsupported preference value for ${key.name}: ${encoded.runtimeType}',
      ),
    };
  }
}
