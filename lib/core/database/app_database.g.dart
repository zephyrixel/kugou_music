// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StoredSongsTable extends StoredSongs
    with TableInfo<$StoredSongsTable, StoredSong> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecsMeta = const VerificationMeta(
    'durationSecs',
  );
  @override
  late final GeneratedColumn<int> durationSecs = GeneratedColumn<int>(
    'duration_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _privilegeMeta = const VerificationMeta(
    'privilege',
  );
  @override
  late final GeneratedColumn<int> privilege = GeneratedColumn<int>(
    'privilege',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mixSongIdMeta = const VerificationMeta(
    'mixSongId',
  );
  @override
  late final GeneratedColumn<int> mixSongId = GeneratedColumn<int>(
    'mix_song_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashStandardMeta = const VerificationMeta(
    'hashStandard',
  );
  @override
  late final GeneratedColumn<String> hashStandard = GeneratedColumn<String>(
    'hash_standard',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashHighMeta = const VerificationMeta(
    'hashHigh',
  );
  @override
  late final GeneratedColumn<String> hashHigh = GeneratedColumn<String>(
    'hash_high',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashFlacMeta = const VerificationMeta(
    'hashFlac',
  );
  @override
  late final GeneratedColumn<String> hashFlac = GeneratedColumn<String>(
    'hash_flac',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashHiResMeta = const VerificationMeta(
    'hashHiRes',
  );
  @override
  late final GeneratedColumn<String> hashHiRes = GeneratedColumn<String>(
    'hash_hi_res',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashSuperMeta = const VerificationMeta(
    'hashSuper',
  );
  @override
  late final GeneratedColumn<String> hashSuper = GeneratedColumn<String>(
    'hash_super',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artist,
    album,
    durationSecs,
    artworkUrl,
    privilege,
    albumId,
    mixSongId,
    hashStandard,
    hashHigh,
    hashFlac,
    hashHiRes,
    hashSuper,
    lastPlayedAt,
    playCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredSong> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('duration_secs')) {
      context.handle(
        _durationSecsMeta,
        durationSecs.isAcceptableOrUnknown(
          data['duration_secs']!,
          _durationSecsMeta,
        ),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('privilege')) {
      context.handle(
        _privilegeMeta,
        privilege.isAcceptableOrUnknown(data['privilege']!, _privilegeMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('mix_song_id')) {
      context.handle(
        _mixSongIdMeta,
        mixSongId.isAcceptableOrUnknown(data['mix_song_id']!, _mixSongIdMeta),
      );
    }
    if (data.containsKey('hash_standard')) {
      context.handle(
        _hashStandardMeta,
        hashStandard.isAcceptableOrUnknown(
          data['hash_standard']!,
          _hashStandardMeta,
        ),
      );
    }
    if (data.containsKey('hash_high')) {
      context.handle(
        _hashHighMeta,
        hashHigh.isAcceptableOrUnknown(data['hash_high']!, _hashHighMeta),
      );
    }
    if (data.containsKey('hash_flac')) {
      context.handle(
        _hashFlacMeta,
        hashFlac.isAcceptableOrUnknown(data['hash_flac']!, _hashFlacMeta),
      );
    }
    if (data.containsKey('hash_hi_res')) {
      context.handle(
        _hashHiResMeta,
        hashHiRes.isAcceptableOrUnknown(data['hash_hi_res']!, _hashHiResMeta),
      );
    }
    if (data.containsKey('hash_super')) {
      context.handle(
        _hashSuperMeta,
        hashSuper.isAcceptableOrUnknown(data['hash_super']!, _hashSuperMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredSong map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredSong(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      durationSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_secs'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      privilege: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}privilege'],
      ),
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      ),
      mixSongId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mix_song_id'],
      ),
      hashStandard: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_standard'],
      ),
      hashHigh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_high'],
      ),
      hashFlac: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_flac'],
      ),
      hashHiRes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_hi_res'],
      ),
      hashSuper: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_super'],
      ),
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
    );
  }

  @override
  $StoredSongsTable createAlias(String alias) {
    return $StoredSongsTable(attachedDatabase, alias);
  }
}

class StoredSong extends DataClass implements Insertable<StoredSong> {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final int? durationSecs;
  final String? artworkUrl;
  final int? privilege;
  final int? albumId;
  final int? mixSongId;
  final String? hashStandard;
  final String? hashHigh;
  final String? hashFlac;
  final String? hashHiRes;
  final String? hashSuper;
  final DateTime? lastPlayedAt;
  final int playCount;
  const StoredSong({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.durationSecs,
    this.artworkUrl,
    this.privilege,
    this.albumId,
    this.mixSongId,
    this.hashStandard,
    this.hashHigh,
    this.hashFlac,
    this.hashHiRes,
    this.hashSuper,
    this.lastPlayedAt,
    required this.playCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || durationSecs != null) {
      map['duration_secs'] = Variable<int>(durationSecs);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    if (!nullToAbsent || privilege != null) {
      map['privilege'] = Variable<int>(privilege);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<int>(albumId);
    }
    if (!nullToAbsent || mixSongId != null) {
      map['mix_song_id'] = Variable<int>(mixSongId);
    }
    if (!nullToAbsent || hashStandard != null) {
      map['hash_standard'] = Variable<String>(hashStandard);
    }
    if (!nullToAbsent || hashHigh != null) {
      map['hash_high'] = Variable<String>(hashHigh);
    }
    if (!nullToAbsent || hashFlac != null) {
      map['hash_flac'] = Variable<String>(hashFlac);
    }
    if (!nullToAbsent || hashHiRes != null) {
      map['hash_hi_res'] = Variable<String>(hashHiRes);
    }
    if (!nullToAbsent || hashSuper != null) {
      map['hash_super'] = Variable<String>(hashSuper);
    }
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['play_count'] = Variable<int>(playCount);
    return map;
  }

  StoredSongsCompanion toCompanion(bool nullToAbsent) {
    return StoredSongsCompanion(
      id: Value(id),
      title: Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      durationSecs: durationSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSecs),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      privilege: privilege == null && nullToAbsent
          ? const Value.absent()
          : Value(privilege),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      mixSongId: mixSongId == null && nullToAbsent
          ? const Value.absent()
          : Value(mixSongId),
      hashStandard: hashStandard == null && nullToAbsent
          ? const Value.absent()
          : Value(hashStandard),
      hashHigh: hashHigh == null && nullToAbsent
          ? const Value.absent()
          : Value(hashHigh),
      hashFlac: hashFlac == null && nullToAbsent
          ? const Value.absent()
          : Value(hashFlac),
      hashHiRes: hashHiRes == null && nullToAbsent
          ? const Value.absent()
          : Value(hashHiRes),
      hashSuper: hashSuper == null && nullToAbsent
          ? const Value.absent()
          : Value(hashSuper),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      playCount: Value(playCount),
    );
  }

  factory StoredSong.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredSong(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      durationSecs: serializer.fromJson<int?>(json['durationSecs']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      privilege: serializer.fromJson<int?>(json['privilege']),
      albumId: serializer.fromJson<int?>(json['albumId']),
      mixSongId: serializer.fromJson<int?>(json['mixSongId']),
      hashStandard: serializer.fromJson<String?>(json['hashStandard']),
      hashHigh: serializer.fromJson<String?>(json['hashHigh']),
      hashFlac: serializer.fromJson<String?>(json['hashFlac']),
      hashHiRes: serializer.fromJson<String?>(json['hashHiRes']),
      hashSuper: serializer.fromJson<String?>(json['hashSuper']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      playCount: serializer.fromJson<int>(json['playCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'durationSecs': serializer.toJson<int?>(durationSecs),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'privilege': serializer.toJson<int?>(privilege),
      'albumId': serializer.toJson<int?>(albumId),
      'mixSongId': serializer.toJson<int?>(mixSongId),
      'hashStandard': serializer.toJson<String?>(hashStandard),
      'hashHigh': serializer.toJson<String?>(hashHigh),
      'hashFlac': serializer.toJson<String?>(hashFlac),
      'hashHiRes': serializer.toJson<String?>(hashHiRes),
      'hashSuper': serializer.toJson<String?>(hashSuper),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'playCount': serializer.toJson<int>(playCount),
    };
  }

  StoredSong copyWith({
    String? id,
    String? title,
    Value<String?> artist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    Value<int?> durationSecs = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    Value<int?> privilege = const Value.absent(),
    Value<int?> albumId = const Value.absent(),
    Value<int?> mixSongId = const Value.absent(),
    Value<String?> hashStandard = const Value.absent(),
    Value<String?> hashHigh = const Value.absent(),
    Value<String?> hashFlac = const Value.absent(),
    Value<String?> hashHiRes = const Value.absent(),
    Value<String?> hashSuper = const Value.absent(),
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    int? playCount,
  }) => StoredSong(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist.present ? artist.value : this.artist,
    album: album.present ? album.value : this.album,
    durationSecs: durationSecs.present ? durationSecs.value : this.durationSecs,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    privilege: privilege.present ? privilege.value : this.privilege,
    albumId: albumId.present ? albumId.value : this.albumId,
    mixSongId: mixSongId.present ? mixSongId.value : this.mixSongId,
    hashStandard: hashStandard.present ? hashStandard.value : this.hashStandard,
    hashHigh: hashHigh.present ? hashHigh.value : this.hashHigh,
    hashFlac: hashFlac.present ? hashFlac.value : this.hashFlac,
    hashHiRes: hashHiRes.present ? hashHiRes.value : this.hashHiRes,
    hashSuper: hashSuper.present ? hashSuper.value : this.hashSuper,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    playCount: playCount ?? this.playCount,
  );
  StoredSong copyWithCompanion(StoredSongsCompanion data) {
    return StoredSong(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      durationSecs: data.durationSecs.present
          ? data.durationSecs.value
          : this.durationSecs,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      privilege: data.privilege.present ? data.privilege.value : this.privilege,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      mixSongId: data.mixSongId.present ? data.mixSongId.value : this.mixSongId,
      hashStandard: data.hashStandard.present
          ? data.hashStandard.value
          : this.hashStandard,
      hashHigh: data.hashHigh.present ? data.hashHigh.value : this.hashHigh,
      hashFlac: data.hashFlac.present ? data.hashFlac.value : this.hashFlac,
      hashHiRes: data.hashHiRes.present ? data.hashHiRes.value : this.hashHiRes,
      hashSuper: data.hashSuper.present ? data.hashSuper.value : this.hashSuper,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredSong(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('privilege: $privilege, ')
          ..write('albumId: $albumId, ')
          ..write('mixSongId: $mixSongId, ')
          ..write('hashStandard: $hashStandard, ')
          ..write('hashHigh: $hashHigh, ')
          ..write('hashFlac: $hashFlac, ')
          ..write('hashHiRes: $hashHiRes, ')
          ..write('hashSuper: $hashSuper, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('playCount: $playCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    artist,
    album,
    durationSecs,
    artworkUrl,
    privilege,
    albumId,
    mixSongId,
    hashStandard,
    hashHigh,
    hashFlac,
    hashHiRes,
    hashSuper,
    lastPlayedAt,
    playCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredSong &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.durationSecs == this.durationSecs &&
          other.artworkUrl == this.artworkUrl &&
          other.privilege == this.privilege &&
          other.albumId == this.albumId &&
          other.mixSongId == this.mixSongId &&
          other.hashStandard == this.hashStandard &&
          other.hashHigh == this.hashHigh &&
          other.hashFlac == this.hashFlac &&
          other.hashHiRes == this.hashHiRes &&
          other.hashSuper == this.hashSuper &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.playCount == this.playCount);
}

class StoredSongsCompanion extends UpdateCompanion<StoredSong> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<int?> durationSecs;
  final Value<String?> artworkUrl;
  final Value<int?> privilege;
  final Value<int?> albumId;
  final Value<int?> mixSongId;
  final Value<String?> hashStandard;
  final Value<String?> hashHigh;
  final Value<String?> hashFlac;
  final Value<String?> hashHiRes;
  final Value<String?> hashSuper;
  final Value<DateTime?> lastPlayedAt;
  final Value<int> playCount;
  final Value<int> rowid;
  const StoredSongsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.privilege = const Value.absent(),
    this.albumId = const Value.absent(),
    this.mixSongId = const Value.absent(),
    this.hashStandard = const Value.absent(),
    this.hashHigh = const Value.absent(),
    this.hashFlac = const Value.absent(),
    this.hashHiRes = const Value.absent(),
    this.hashSuper = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredSongsCompanion.insert({
    required String id,
    required String title,
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.privilege = const Value.absent(),
    this.albumId = const Value.absent(),
    this.mixSongId = const Value.absent(),
    this.hashStandard = const Value.absent(),
    this.hashHigh = const Value.absent(),
    this.hashFlac = const Value.absent(),
    this.hashHiRes = const Value.absent(),
    this.hashSuper = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<StoredSong> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<int>? durationSecs,
    Expression<String>? artworkUrl,
    Expression<int>? privilege,
    Expression<int>? albumId,
    Expression<int>? mixSongId,
    Expression<String>? hashStandard,
    Expression<String>? hashHigh,
    Expression<String>? hashFlac,
    Expression<String>? hashHiRes,
    Expression<String>? hashSuper,
    Expression<DateTime>? lastPlayedAt,
    Expression<int>? playCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (durationSecs != null) 'duration_secs': durationSecs,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (privilege != null) 'privilege': privilege,
      if (albumId != null) 'album_id': albumId,
      if (mixSongId != null) 'mix_song_id': mixSongId,
      if (hashStandard != null) 'hash_standard': hashStandard,
      if (hashHigh != null) 'hash_high': hashHigh,
      if (hashFlac != null) 'hash_flac': hashFlac,
      if (hashHiRes != null) 'hash_hi_res': hashHiRes,
      if (hashSuper != null) 'hash_super': hashSuper,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (playCount != null) 'play_count': playCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredSongsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? artist,
    Value<String?>? album,
    Value<int?>? durationSecs,
    Value<String?>? artworkUrl,
    Value<int?>? privilege,
    Value<int?>? albumId,
    Value<int?>? mixSongId,
    Value<String?>? hashStandard,
    Value<String?>? hashHigh,
    Value<String?>? hashFlac,
    Value<String?>? hashHiRes,
    Value<String?>? hashSuper,
    Value<DateTime?>? lastPlayedAt,
    Value<int>? playCount,
    Value<int>? rowid,
  }) {
    return StoredSongsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationSecs: durationSecs ?? this.durationSecs,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      privilege: privilege ?? this.privilege,
      albumId: albumId ?? this.albumId,
      mixSongId: mixSongId ?? this.mixSongId,
      hashStandard: hashStandard ?? this.hashStandard,
      hashHigh: hashHigh ?? this.hashHigh,
      hashFlac: hashFlac ?? this.hashFlac,
      hashHiRes: hashHiRes ?? this.hashHiRes,
      hashSuper: hashSuper ?? this.hashSuper,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      playCount: playCount ?? this.playCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (durationSecs.present) {
      map['duration_secs'] = Variable<int>(durationSecs.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (privilege.present) {
      map['privilege'] = Variable<int>(privilege.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (mixSongId.present) {
      map['mix_song_id'] = Variable<int>(mixSongId.value);
    }
    if (hashStandard.present) {
      map['hash_standard'] = Variable<String>(hashStandard.value);
    }
    if (hashHigh.present) {
      map['hash_high'] = Variable<String>(hashHigh.value);
    }
    if (hashFlac.present) {
      map['hash_flac'] = Variable<String>(hashFlac.value);
    }
    if (hashHiRes.present) {
      map['hash_hi_res'] = Variable<String>(hashHiRes.value);
    }
    if (hashSuper.present) {
      map['hash_super'] = Variable<String>(hashSuper.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredSongsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('privilege: $privilege, ')
          ..write('albumId: $albumId, ')
          ..write('mixSongId: $mixSongId, ')
          ..write('hashStandard: $hashStandard, ')
          ..write('hashHigh: $hashHigh, ')
          ..write('hashFlac: $hashFlac, ')
          ..write('hashHiRes: $hashHiRes, ')
          ..write('hashSuper: $hashSuper, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('playCount: $playCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredPlaylistsTable extends StoredPlaylists
    with TableInfo<$StoredPlaylistsTable, StoredPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteListIdMeta = const VerificationMeta(
    'remoteListId',
  );
  @override
  late final GeneratedColumn<int> remoteListId = GeneratedColumn<int>(
    'remote_list_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _globalCollectionIdMeta =
      const VerificationMeta('globalCollectionId');
  @override
  late final GeneratedColumn<String> globalCollectionId =
      GeneratedColumn<String>(
        'global_collection_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _introMeta = const VerificationMeta('intro');
  @override
  late final GeneratedColumn<String> intro = GeneratedColumn<String>(
    'intro',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _listTypeMeta = const VerificationMeta(
    'listType',
  );
  @override
  late final GeneratedColumn<int> listType = GeneratedColumn<int>(
    'list_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatorUserIdMeta = const VerificationMeta(
    'creatorUserId',
  );
  @override
  late final GeneratedColumn<int> creatorUserId = GeneratedColumn<int>(
    'creator_user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatorNameMeta = const VerificationMeta(
    'creatorName',
  );
  @override
  late final GeneratedColumn<String> creatorName = GeneratedColumn<String>(
    'creator_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrivateMeta = const VerificationMeta(
    'isPrivate',
  );
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
    'is_private',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_private" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isMyFavoriteMeta = const VerificationMeta(
    'isMyFavorite',
  );
  @override
  late final GeneratedColumn<bool> isMyFavorite = GeneratedColumn<bool>(
    'is_my_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_my_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDefaultCollectMeta = const VerificationMeta(
    'isDefaultCollect',
  );
  @override
  late final GeneratedColumn<bool> isDefaultCollect = GeneratedColumn<bool>(
    'is_default_collect',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default_collect" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tracksLoadedMeta = const VerificationMeta(
    'tracksLoaded',
  );
  @override
  late final GeneratedColumn<bool> tracksLoaded = GeneratedColumn<bool>(
    'tracks_loaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tracks_loaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    remoteListId,
    globalCollectionId,
    name,
    intro,
    artworkUrl,
    count,
    listType,
    creatorUserId,
    creatorName,
    isPrivate,
    isMyFavorite,
    isDefaultCollect,
    tracksLoaded,
    tags,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredPlaylist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('remote_list_id')) {
      context.handle(
        _remoteListIdMeta,
        remoteListId.isAcceptableOrUnknown(
          data['remote_list_id']!,
          _remoteListIdMeta,
        ),
      );
    }
    if (data.containsKey('global_collection_id')) {
      context.handle(
        _globalCollectionIdMeta,
        globalCollectionId.isAcceptableOrUnknown(
          data['global_collection_id']!,
          _globalCollectionIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('intro')) {
      context.handle(
        _introMeta,
        intro.isAcceptableOrUnknown(data['intro']!, _introMeta),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('list_type')) {
      context.handle(
        _listTypeMeta,
        listType.isAcceptableOrUnknown(data['list_type']!, _listTypeMeta),
      );
    }
    if (data.containsKey('creator_user_id')) {
      context.handle(
        _creatorUserIdMeta,
        creatorUserId.isAcceptableOrUnknown(
          data['creator_user_id']!,
          _creatorUserIdMeta,
        ),
      );
    }
    if (data.containsKey('creator_name')) {
      context.handle(
        _creatorNameMeta,
        creatorName.isAcceptableOrUnknown(
          data['creator_name']!,
          _creatorNameMeta,
        ),
      );
    }
    if (data.containsKey('is_private')) {
      context.handle(
        _isPrivateMeta,
        isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta),
      );
    }
    if (data.containsKey('is_my_favorite')) {
      context.handle(
        _isMyFavoriteMeta,
        isMyFavorite.isAcceptableOrUnknown(
          data['is_my_favorite']!,
          _isMyFavoriteMeta,
        ),
      );
    }
    if (data.containsKey('is_default_collect')) {
      context.handle(
        _isDefaultCollectMeta,
        isDefaultCollect.isAcceptableOrUnknown(
          data['is_default_collect']!,
          _isDefaultCollectMeta,
        ),
      );
    }
    if (data.containsKey('tracks_loaded')) {
      context.handle(
        _tracksLoadedMeta,
        tracksLoaded.isAcceptableOrUnknown(
          data['tracks_loaded']!,
          _tracksLoadedMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  StoredPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredPlaylist(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      remoteListId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_list_id'],
      ),
      globalCollectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}global_collection_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      intro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intro'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      listType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_type'],
      ),
      creatorUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}creator_user_id'],
      ),
      creatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_name'],
      ),
      isPrivate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_private'],
      )!,
      isMyFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_my_favorite'],
      )!,
      isDefaultCollect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default_collect'],
      )!,
      tracksLoaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tracks_loaded'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $StoredPlaylistsTable createAlias(String alias) {
    return $StoredPlaylistsTable(attachedDatabase, alias);
  }
}

class StoredPlaylist extends DataClass implements Insertable<StoredPlaylist> {
  final String localId;
  final int? remoteListId;
  final String? globalCollectionId;
  final String name;
  final String? intro;
  final String? artworkUrl;
  final int count;
  final int? listType;
  final int? creatorUserId;
  final String? creatorName;
  final bool isPrivate;
  final bool isMyFavorite;
  final bool isDefaultCollect;
  final bool tracksLoaded;
  final String? tags;
  final int sortOrder;
  const StoredPlaylist({
    required this.localId,
    this.remoteListId,
    this.globalCollectionId,
    required this.name,
    this.intro,
    this.artworkUrl,
    required this.count,
    this.listType,
    this.creatorUserId,
    this.creatorName,
    required this.isPrivate,
    required this.isMyFavorite,
    required this.isDefaultCollect,
    required this.tracksLoaded,
    this.tags,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || remoteListId != null) {
      map['remote_list_id'] = Variable<int>(remoteListId);
    }
    if (!nullToAbsent || globalCollectionId != null) {
      map['global_collection_id'] = Variable<String>(globalCollectionId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || intro != null) {
      map['intro'] = Variable<String>(intro);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    map['count'] = Variable<int>(count);
    if (!nullToAbsent || listType != null) {
      map['list_type'] = Variable<int>(listType);
    }
    if (!nullToAbsent || creatorUserId != null) {
      map['creator_user_id'] = Variable<int>(creatorUserId);
    }
    if (!nullToAbsent || creatorName != null) {
      map['creator_name'] = Variable<String>(creatorName);
    }
    map['is_private'] = Variable<bool>(isPrivate);
    map['is_my_favorite'] = Variable<bool>(isMyFavorite);
    map['is_default_collect'] = Variable<bool>(isDefaultCollect);
    map['tracks_loaded'] = Variable<bool>(tracksLoaded);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  StoredPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return StoredPlaylistsCompanion(
      localId: Value(localId),
      remoteListId: remoteListId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteListId),
      globalCollectionId: globalCollectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(globalCollectionId),
      name: Value(name),
      intro: intro == null && nullToAbsent
          ? const Value.absent()
          : Value(intro),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      count: Value(count),
      listType: listType == null && nullToAbsent
          ? const Value.absent()
          : Value(listType),
      creatorUserId: creatorUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorUserId),
      creatorName: creatorName == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorName),
      isPrivate: Value(isPrivate),
      isMyFavorite: Value(isMyFavorite),
      isDefaultCollect: Value(isDefaultCollect),
      tracksLoaded: Value(tracksLoaded),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      sortOrder: Value(sortOrder),
    );
  }

  factory StoredPlaylist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredPlaylist(
      localId: serializer.fromJson<String>(json['localId']),
      remoteListId: serializer.fromJson<int?>(json['remoteListId']),
      globalCollectionId: serializer.fromJson<String?>(
        json['globalCollectionId'],
      ),
      name: serializer.fromJson<String>(json['name']),
      intro: serializer.fromJson<String?>(json['intro']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      count: serializer.fromJson<int>(json['count']),
      listType: serializer.fromJson<int?>(json['listType']),
      creatorUserId: serializer.fromJson<int?>(json['creatorUserId']),
      creatorName: serializer.fromJson<String?>(json['creatorName']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      isMyFavorite: serializer.fromJson<bool>(json['isMyFavorite']),
      isDefaultCollect: serializer.fromJson<bool>(json['isDefaultCollect']),
      tracksLoaded: serializer.fromJson<bool>(json['tracksLoaded']),
      tags: serializer.fromJson<String?>(json['tags']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'remoteListId': serializer.toJson<int?>(remoteListId),
      'globalCollectionId': serializer.toJson<String?>(globalCollectionId),
      'name': serializer.toJson<String>(name),
      'intro': serializer.toJson<String?>(intro),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'count': serializer.toJson<int>(count),
      'listType': serializer.toJson<int?>(listType),
      'creatorUserId': serializer.toJson<int?>(creatorUserId),
      'creatorName': serializer.toJson<String?>(creatorName),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'isMyFavorite': serializer.toJson<bool>(isMyFavorite),
      'isDefaultCollect': serializer.toJson<bool>(isDefaultCollect),
      'tracksLoaded': serializer.toJson<bool>(tracksLoaded),
      'tags': serializer.toJson<String?>(tags),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  StoredPlaylist copyWith({
    String? localId,
    Value<int?> remoteListId = const Value.absent(),
    Value<String?> globalCollectionId = const Value.absent(),
    String? name,
    Value<String?> intro = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    int? count,
    Value<int?> listType = const Value.absent(),
    Value<int?> creatorUserId = const Value.absent(),
    Value<String?> creatorName = const Value.absent(),
    bool? isPrivate,
    bool? isMyFavorite,
    bool? isDefaultCollect,
    bool? tracksLoaded,
    Value<String?> tags = const Value.absent(),
    int? sortOrder,
  }) => StoredPlaylist(
    localId: localId ?? this.localId,
    remoteListId: remoteListId.present ? remoteListId.value : this.remoteListId,
    globalCollectionId: globalCollectionId.present
        ? globalCollectionId.value
        : this.globalCollectionId,
    name: name ?? this.name,
    intro: intro.present ? intro.value : this.intro,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    count: count ?? this.count,
    listType: listType.present ? listType.value : this.listType,
    creatorUserId: creatorUserId.present
        ? creatorUserId.value
        : this.creatorUserId,
    creatorName: creatorName.present ? creatorName.value : this.creatorName,
    isPrivate: isPrivate ?? this.isPrivate,
    isMyFavorite: isMyFavorite ?? this.isMyFavorite,
    isDefaultCollect: isDefaultCollect ?? this.isDefaultCollect,
    tracksLoaded: tracksLoaded ?? this.tracksLoaded,
    tags: tags.present ? tags.value : this.tags,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  StoredPlaylist copyWithCompanion(StoredPlaylistsCompanion data) {
    return StoredPlaylist(
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteListId: data.remoteListId.present
          ? data.remoteListId.value
          : this.remoteListId,
      globalCollectionId: data.globalCollectionId.present
          ? data.globalCollectionId.value
          : this.globalCollectionId,
      name: data.name.present ? data.name.value : this.name,
      intro: data.intro.present ? data.intro.value : this.intro,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      count: data.count.present ? data.count.value : this.count,
      listType: data.listType.present ? data.listType.value : this.listType,
      creatorUserId: data.creatorUserId.present
          ? data.creatorUserId.value
          : this.creatorUserId,
      creatorName: data.creatorName.present
          ? data.creatorName.value
          : this.creatorName,
      isPrivate: data.isPrivate.present ? data.isPrivate.value : this.isPrivate,
      isMyFavorite: data.isMyFavorite.present
          ? data.isMyFavorite.value
          : this.isMyFavorite,
      isDefaultCollect: data.isDefaultCollect.present
          ? data.isDefaultCollect.value
          : this.isDefaultCollect,
      tracksLoaded: data.tracksLoaded.present
          ? data.tracksLoaded.value
          : this.tracksLoaded,
      tags: data.tags.present ? data.tags.value : this.tags,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredPlaylist(')
          ..write('localId: $localId, ')
          ..write('remoteListId: $remoteListId, ')
          ..write('globalCollectionId: $globalCollectionId, ')
          ..write('name: $name, ')
          ..write('intro: $intro, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('count: $count, ')
          ..write('listType: $listType, ')
          ..write('creatorUserId: $creatorUserId, ')
          ..write('creatorName: $creatorName, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('isMyFavorite: $isMyFavorite, ')
          ..write('isDefaultCollect: $isDefaultCollect, ')
          ..write('tracksLoaded: $tracksLoaded, ')
          ..write('tags: $tags, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    remoteListId,
    globalCollectionId,
    name,
    intro,
    artworkUrl,
    count,
    listType,
    creatorUserId,
    creatorName,
    isPrivate,
    isMyFavorite,
    isDefaultCollect,
    tracksLoaded,
    tags,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredPlaylist &&
          other.localId == this.localId &&
          other.remoteListId == this.remoteListId &&
          other.globalCollectionId == this.globalCollectionId &&
          other.name == this.name &&
          other.intro == this.intro &&
          other.artworkUrl == this.artworkUrl &&
          other.count == this.count &&
          other.listType == this.listType &&
          other.creatorUserId == this.creatorUserId &&
          other.creatorName == this.creatorName &&
          other.isPrivate == this.isPrivate &&
          other.isMyFavorite == this.isMyFavorite &&
          other.isDefaultCollect == this.isDefaultCollect &&
          other.tracksLoaded == this.tracksLoaded &&
          other.tags == this.tags &&
          other.sortOrder == this.sortOrder);
}

class StoredPlaylistsCompanion extends UpdateCompanion<StoredPlaylist> {
  final Value<String> localId;
  final Value<int?> remoteListId;
  final Value<String?> globalCollectionId;
  final Value<String> name;
  final Value<String?> intro;
  final Value<String?> artworkUrl;
  final Value<int> count;
  final Value<int?> listType;
  final Value<int?> creatorUserId;
  final Value<String?> creatorName;
  final Value<bool> isPrivate;
  final Value<bool> isMyFavorite;
  final Value<bool> isDefaultCollect;
  final Value<bool> tracksLoaded;
  final Value<String?> tags;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const StoredPlaylistsCompanion({
    this.localId = const Value.absent(),
    this.remoteListId = const Value.absent(),
    this.globalCollectionId = const Value.absent(),
    this.name = const Value.absent(),
    this.intro = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.count = const Value.absent(),
    this.listType = const Value.absent(),
    this.creatorUserId = const Value.absent(),
    this.creatorName = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.isMyFavorite = const Value.absent(),
    this.isDefaultCollect = const Value.absent(),
    this.tracksLoaded = const Value.absent(),
    this.tags = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredPlaylistsCompanion.insert({
    required String localId,
    this.remoteListId = const Value.absent(),
    this.globalCollectionId = const Value.absent(),
    required String name,
    this.intro = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.count = const Value.absent(),
    this.listType = const Value.absent(),
    this.creatorUserId = const Value.absent(),
    this.creatorName = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.isMyFavorite = const Value.absent(),
    this.isDefaultCollect = const Value.absent(),
    this.tracksLoaded = const Value.absent(),
    this.tags = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       name = Value(name);
  static Insertable<StoredPlaylist> custom({
    Expression<String>? localId,
    Expression<int>? remoteListId,
    Expression<String>? globalCollectionId,
    Expression<String>? name,
    Expression<String>? intro,
    Expression<String>? artworkUrl,
    Expression<int>? count,
    Expression<int>? listType,
    Expression<int>? creatorUserId,
    Expression<String>? creatorName,
    Expression<bool>? isPrivate,
    Expression<bool>? isMyFavorite,
    Expression<bool>? isDefaultCollect,
    Expression<bool>? tracksLoaded,
    Expression<String>? tags,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (remoteListId != null) 'remote_list_id': remoteListId,
      if (globalCollectionId != null)
        'global_collection_id': globalCollectionId,
      if (name != null) 'name': name,
      if (intro != null) 'intro': intro,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (count != null) 'count': count,
      if (listType != null) 'list_type': listType,
      if (creatorUserId != null) 'creator_user_id': creatorUserId,
      if (creatorName != null) 'creator_name': creatorName,
      if (isPrivate != null) 'is_private': isPrivate,
      if (isMyFavorite != null) 'is_my_favorite': isMyFavorite,
      if (isDefaultCollect != null) 'is_default_collect': isDefaultCollect,
      if (tracksLoaded != null) 'tracks_loaded': tracksLoaded,
      if (tags != null) 'tags': tags,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredPlaylistsCompanion copyWith({
    Value<String>? localId,
    Value<int?>? remoteListId,
    Value<String?>? globalCollectionId,
    Value<String>? name,
    Value<String?>? intro,
    Value<String?>? artworkUrl,
    Value<int>? count,
    Value<int?>? listType,
    Value<int?>? creatorUserId,
    Value<String?>? creatorName,
    Value<bool>? isPrivate,
    Value<bool>? isMyFavorite,
    Value<bool>? isDefaultCollect,
    Value<bool>? tracksLoaded,
    Value<String?>? tags,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return StoredPlaylistsCompanion(
      localId: localId ?? this.localId,
      remoteListId: remoteListId ?? this.remoteListId,
      globalCollectionId: globalCollectionId ?? this.globalCollectionId,
      name: name ?? this.name,
      intro: intro ?? this.intro,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      count: count ?? this.count,
      listType: listType ?? this.listType,
      creatorUserId: creatorUserId ?? this.creatorUserId,
      creatorName: creatorName ?? this.creatorName,
      isPrivate: isPrivate ?? this.isPrivate,
      isMyFavorite: isMyFavorite ?? this.isMyFavorite,
      isDefaultCollect: isDefaultCollect ?? this.isDefaultCollect,
      tracksLoaded: tracksLoaded ?? this.tracksLoaded,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (remoteListId.present) {
      map['remote_list_id'] = Variable<int>(remoteListId.value);
    }
    if (globalCollectionId.present) {
      map['global_collection_id'] = Variable<String>(globalCollectionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (intro.present) {
      map['intro'] = Variable<String>(intro.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (listType.present) {
      map['list_type'] = Variable<int>(listType.value);
    }
    if (creatorUserId.present) {
      map['creator_user_id'] = Variable<int>(creatorUserId.value);
    }
    if (creatorName.present) {
      map['creator_name'] = Variable<String>(creatorName.value);
    }
    if (isPrivate.present) {
      map['is_private'] = Variable<bool>(isPrivate.value);
    }
    if (isMyFavorite.present) {
      map['is_my_favorite'] = Variable<bool>(isMyFavorite.value);
    }
    if (isDefaultCollect.present) {
      map['is_default_collect'] = Variable<bool>(isDefaultCollect.value);
    }
    if (tracksLoaded.present) {
      map['tracks_loaded'] = Variable<bool>(tracksLoaded.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredPlaylistsCompanion(')
          ..write('localId: $localId, ')
          ..write('remoteListId: $remoteListId, ')
          ..write('globalCollectionId: $globalCollectionId, ')
          ..write('name: $name, ')
          ..write('intro: $intro, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('count: $count, ')
          ..write('listType: $listType, ')
          ..write('creatorUserId: $creatorUserId, ')
          ..write('creatorName: $creatorName, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('isMyFavorite: $isMyFavorite, ')
          ..write('isDefaultCollect: $isDefaultCollect, ')
          ..write('tracksLoaded: $tracksLoaded, ')
          ..write('tags: $tags, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredPlaylistTracksTable extends StoredPlaylistTracks
    with TableInfo<$StoredPlaylistTracksTable, StoredPlaylistTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredPlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistLocalIdMeta = const VerificationMeta(
    'playlistLocalId',
  );
  @override
  late final GeneratedColumn<String> playlistLocalId = GeneratedColumn<String>(
    'playlist_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<int> fileId = GeneratedColumn<int>(
    'file_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    playlistLocalId,
    songId,
    fileId,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredPlaylistTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_local_id')) {
      context.handle(
        _playlistLocalIdMeta,
        playlistLocalId.isAcceptableOrUnknown(
          data['playlist_local_id']!,
          _playlistLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playlistLocalIdMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistLocalId, songId};
  @override
  StoredPlaylistTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredPlaylistTrack(
      playlistLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_local_id'],
      )!,
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_id'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $StoredPlaylistTracksTable createAlias(String alias) {
    return $StoredPlaylistTracksTable(attachedDatabase, alias);
  }
}

class StoredPlaylistTrack extends DataClass
    implements Insertable<StoredPlaylistTrack> {
  final String playlistLocalId;
  final String songId;
  final int? fileId;
  final int position;
  const StoredPlaylistTrack({
    required this.playlistLocalId,
    required this.songId,
    this.fileId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_local_id'] = Variable<String>(playlistLocalId);
    map['song_id'] = Variable<String>(songId);
    if (!nullToAbsent || fileId != null) {
      map['file_id'] = Variable<int>(fileId);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  StoredPlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return StoredPlaylistTracksCompanion(
      playlistLocalId: Value(playlistLocalId),
      songId: Value(songId),
      fileId: fileId == null && nullToAbsent
          ? const Value.absent()
          : Value(fileId),
      position: Value(position),
    );
  }

  factory StoredPlaylistTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredPlaylistTrack(
      playlistLocalId: serializer.fromJson<String>(json['playlistLocalId']),
      songId: serializer.fromJson<String>(json['songId']),
      fileId: serializer.fromJson<int?>(json['fileId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistLocalId': serializer.toJson<String>(playlistLocalId),
      'songId': serializer.toJson<String>(songId),
      'fileId': serializer.toJson<int?>(fileId),
      'position': serializer.toJson<int>(position),
    };
  }

  StoredPlaylistTrack copyWith({
    String? playlistLocalId,
    String? songId,
    Value<int?> fileId = const Value.absent(),
    int? position,
  }) => StoredPlaylistTrack(
    playlistLocalId: playlistLocalId ?? this.playlistLocalId,
    songId: songId ?? this.songId,
    fileId: fileId.present ? fileId.value : this.fileId,
    position: position ?? this.position,
  );
  StoredPlaylistTrack copyWithCompanion(StoredPlaylistTracksCompanion data) {
    return StoredPlaylistTrack(
      playlistLocalId: data.playlistLocalId.present
          ? data.playlistLocalId.value
          : this.playlistLocalId,
      songId: data.songId.present ? data.songId.value : this.songId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredPlaylistTrack(')
          ..write('playlistLocalId: $playlistLocalId, ')
          ..write('songId: $songId, ')
          ..write('fileId: $fileId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistLocalId, songId, fileId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredPlaylistTrack &&
          other.playlistLocalId == this.playlistLocalId &&
          other.songId == this.songId &&
          other.fileId == this.fileId &&
          other.position == this.position);
}

class StoredPlaylistTracksCompanion
    extends UpdateCompanion<StoredPlaylistTrack> {
  final Value<String> playlistLocalId;
  final Value<String> songId;
  final Value<int?> fileId;
  final Value<int> position;
  final Value<int> rowid;
  const StoredPlaylistTracksCompanion({
    this.playlistLocalId = const Value.absent(),
    this.songId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredPlaylistTracksCompanion.insert({
    required String playlistLocalId,
    required String songId,
    this.fileId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : playlistLocalId = Value(playlistLocalId),
       songId = Value(songId);
  static Insertable<StoredPlaylistTrack> custom({
    Expression<String>? playlistLocalId,
    Expression<String>? songId,
    Expression<int>? fileId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistLocalId != null) 'playlist_local_id': playlistLocalId,
      if (songId != null) 'song_id': songId,
      if (fileId != null) 'file_id': fileId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredPlaylistTracksCompanion copyWith({
    Value<String>? playlistLocalId,
    Value<String>? songId,
    Value<int?>? fileId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return StoredPlaylistTracksCompanion(
      playlistLocalId: playlistLocalId ?? this.playlistLocalId,
      songId: songId ?? this.songId,
      fileId: fileId ?? this.fileId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistLocalId.present) {
      map['playlist_local_id'] = Variable<String>(playlistLocalId.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<int>(fileId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredPlaylistTracksCompanion(')
          ..write('playlistLocalId: $playlistLocalId, ')
          ..write('songId: $songId, ')
          ..write('fileId: $fileId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibrarySyncStatesTable extends LibrarySyncStates
    with TableInfo<$LibrarySyncStatesTable, LibrarySyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibrarySyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baselineCompleteMeta = const VerificationMeta(
    'baselineComplete',
  );
  @override
  late final GeneratedColumn<bool> baselineComplete = GeneratedColumn<bool>(
    'baseline_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("baseline_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    userId,
    baselineComplete,
    lastSyncedAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibrarySyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('baseline_complete')) {
      context.handle(
        _baselineCompleteMeta,
        baselineComplete.isAcceptableOrUnknown(
          data['baseline_complete']!,
          _baselineCompleteMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  LibrarySyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibrarySyncState(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      baselineComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}baseline_complete'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $LibrarySyncStatesTable createAlias(String alias) {
    return $LibrarySyncStatesTable(attachedDatabase, alias);
  }
}

class LibrarySyncState extends DataClass
    implements Insertable<LibrarySyncState> {
  final int singletonId;
  final int userId;
  final bool baselineComplete;
  final DateTime? lastSyncedAt;
  final String? lastError;
  const LibrarySyncState({
    required this.singletonId,
    required this.userId,
    required this.baselineComplete,
    this.lastSyncedAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    map['user_id'] = Variable<int>(userId);
    map['baseline_complete'] = Variable<bool>(baselineComplete);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  LibrarySyncStatesCompanion toCompanion(bool nullToAbsent) {
    return LibrarySyncStatesCompanion(
      singletonId: Value(singletonId),
      userId: Value(userId),
      baselineComplete: Value(baselineComplete),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory LibrarySyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibrarySyncState(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      userId: serializer.fromJson<int>(json['userId']),
      baselineComplete: serializer.fromJson<bool>(json['baselineComplete']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'userId': serializer.toJson<int>(userId),
      'baselineComplete': serializer.toJson<bool>(baselineComplete),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  LibrarySyncState copyWith({
    int? singletonId,
    int? userId,
    bool? baselineComplete,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => LibrarySyncState(
    singletonId: singletonId ?? this.singletonId,
    userId: userId ?? this.userId,
    baselineComplete: baselineComplete ?? this.baselineComplete,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  LibrarySyncState copyWithCompanion(LibrarySyncStatesCompanion data) {
    return LibrarySyncState(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      userId: data.userId.present ? data.userId.value : this.userId,
      baselineComplete: data.baselineComplete.present
          ? data.baselineComplete.value
          : this.baselineComplete,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibrarySyncState(')
          ..write('singletonId: $singletonId, ')
          ..write('userId: $userId, ')
          ..write('baselineComplete: $baselineComplete, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singletonId,
    userId,
    baselineComplete,
    lastSyncedAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibrarySyncState &&
          other.singletonId == this.singletonId &&
          other.userId == this.userId &&
          other.baselineComplete == this.baselineComplete &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.lastError == this.lastError);
}

class LibrarySyncStatesCompanion extends UpdateCompanion<LibrarySyncState> {
  final Value<int> singletonId;
  final Value<int> userId;
  final Value<bool> baselineComplete;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> lastError;
  const LibrarySyncStatesCompanion({
    this.singletonId = const Value.absent(),
    this.userId = const Value.absent(),
    this.baselineComplete = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  LibrarySyncStatesCompanion.insert({
    this.singletonId = const Value.absent(),
    required int userId,
    this.baselineComplete = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<LibrarySyncState> custom({
    Expression<int>? singletonId,
    Expression<int>? userId,
    Expression<bool>? baselineComplete,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (userId != null) 'user_id': userId,
      if (baselineComplete != null) 'baseline_complete': baselineComplete,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (lastError != null) 'last_error': lastError,
    });
  }

  LibrarySyncStatesCompanion copyWith({
    Value<int>? singletonId,
    Value<int>? userId,
    Value<bool>? baselineComplete,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? lastError,
  }) {
    return LibrarySyncStatesCompanion(
      singletonId: singletonId ?? this.singletonId,
      userId: userId ?? this.userId,
      baselineComplete: baselineComplete ?? this.baselineComplete,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (baselineComplete.present) {
      map['baseline_complete'] = Variable<bool>(baselineComplete.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibrarySyncStatesCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('userId: $userId, ')
          ..write('baselineComplete: $baselineComplete, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $CachedResponsesTable extends CachedResponses
    with TableInfo<$CachedResponsesTable, CachedResponse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountUserIdMeta = const VerificationMeta(
    'accountUserId',
  );
  @override
  late final GeneratedColumn<int> accountUserId = GeneratedColumn<int>(
    'account_user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codecVersionMeta = const VerificationMeta(
    'codecVersion',
  );
  @override
  late final GeneratedColumn<int> codecVersion = GeneratedColumn<int>(
    'codec_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    accountUserId,
    codecVersion,
    payload,
    updatedAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_responses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedResponse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('account_user_id')) {
      context.handle(
        _accountUserIdMeta,
        accountUserId.isAcceptableOrUnknown(
          data['account_user_id']!,
          _accountUserIdMeta,
        ),
      );
    }
    if (data.containsKey('codec_version')) {
      context.handle(
        _codecVersionMeta,
        codecVersion.isAcceptableOrUnknown(
          data['codec_version']!,
          _codecVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codecVersionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CachedResponse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedResponse(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      accountUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_user_id'],
      ),
      codecVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}codec_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      )!,
    );
  }

  @override
  $CachedResponsesTable createAlias(String alias) {
    return $CachedResponsesTable(attachedDatabase, alias);
  }
}

class CachedResponse extends DataClass implements Insertable<CachedResponse> {
  final String cacheKey;
  final int? accountUserId;
  final int codecVersion;
  final String payload;
  final DateTime updatedAt;
  final DateTime lastAccessedAt;
  const CachedResponse({
    required this.cacheKey,
    this.accountUserId,
    required this.codecVersion,
    required this.payload,
    required this.updatedAt,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    if (!nullToAbsent || accountUserId != null) {
      map['account_user_id'] = Variable<int>(accountUserId);
    }
    map['codec_version'] = Variable<int>(codecVersion);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    return map;
  }

  CachedResponsesCompanion toCompanion(bool nullToAbsent) {
    return CachedResponsesCompanion(
      cacheKey: Value(cacheKey),
      accountUserId: accountUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountUserId),
      codecVersion: Value(codecVersion),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory CachedResponse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedResponse(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      accountUserId: serializer.fromJson<int?>(json['accountUserId']),
      codecVersion: serializer.fromJson<int>(json['codecVersion']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'accountUserId': serializer.toJson<int?>(accountUserId),
      'codecVersion': serializer.toJson<int>(codecVersion),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  CachedResponse copyWith({
    String? cacheKey,
    Value<int?> accountUserId = const Value.absent(),
    int? codecVersion,
    String? payload,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
  }) => CachedResponse(
    cacheKey: cacheKey ?? this.cacheKey,
    accountUserId: accountUserId.present
        ? accountUserId.value
        : this.accountUserId,
    codecVersion: codecVersion ?? this.codecVersion,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  CachedResponse copyWithCompanion(CachedResponsesCompanion data) {
    return CachedResponse(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      accountUserId: data.accountUserId.present
          ? data.accountUserId.value
          : this.accountUserId,
      codecVersion: data.codecVersion.present
          ? data.codecVersion.value
          : this.codecVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedResponse(')
          ..write('cacheKey: $cacheKey, ')
          ..write('accountUserId: $accountUserId, ')
          ..write('codecVersion: $codecVersion, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cacheKey,
    accountUserId,
    codecVersion,
    payload,
    updatedAt,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedResponse &&
          other.cacheKey == this.cacheKey &&
          other.accountUserId == this.accountUserId &&
          other.codecVersion == this.codecVersion &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class CachedResponsesCompanion extends UpdateCompanion<CachedResponse> {
  final Value<String> cacheKey;
  final Value<int?> accountUserId;
  final Value<int> codecVersion;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const CachedResponsesCompanion({
    this.cacheKey = const Value.absent(),
    this.accountUserId = const Value.absent(),
    this.codecVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedResponsesCompanion.insert({
    required String cacheKey,
    this.accountUserId = const Value.absent(),
    required int codecVersion,
    required String payload,
    required DateTime updatedAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       codecVersion = Value(codecVersion),
       payload = Value(payload),
       updatedAt = Value(updatedAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<CachedResponse> custom({
    Expression<String>? cacheKey,
    Expression<int>? accountUserId,
    Expression<int>? codecVersion,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (accountUserId != null) 'account_user_id': accountUserId,
      if (codecVersion != null) 'codec_version': codecVersion,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedResponsesCompanion copyWith({
    Value<String>? cacheKey,
    Value<int?>? accountUserId,
    Value<int>? codecVersion,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<DateTime>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return CachedResponsesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      accountUserId: accountUserId ?? this.accountUserId,
      codecVersion: codecVersion ?? this.codecVersion,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (accountUserId.present) {
      map['account_user_id'] = Variable<int>(accountUserId.value);
    }
    if (codecVersion.present) {
      map['codec_version'] = Variable<int>(codecVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedResponsesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('accountUserId: $accountUserId, ')
          ..write('codecVersion: $codecVersion, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StoredSongsTable storedSongs = $StoredSongsTable(this);
  late final $StoredPlaylistsTable storedPlaylists = $StoredPlaylistsTable(
    this,
  );
  late final $StoredPlaylistTracksTable storedPlaylistTracks =
      $StoredPlaylistTracksTable(this);
  late final $LibrarySyncStatesTable librarySyncStates =
      $LibrarySyncStatesTable(this);
  late final $CachedResponsesTable cachedResponses = $CachedResponsesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    storedSongs,
    storedPlaylists,
    storedPlaylistTracks,
    librarySyncStates,
    cachedResponses,
  ];
}

typedef $$StoredSongsTableCreateCompanionBuilder =
    StoredSongsCompanion Function({
      required String id,
      required String title,
      Value<String?> artist,
      Value<String?> album,
      Value<int?> durationSecs,
      Value<String?> artworkUrl,
      Value<int?> privilege,
      Value<int?> albumId,
      Value<int?> mixSongId,
      Value<String?> hashStandard,
      Value<String?> hashHigh,
      Value<String?> hashFlac,
      Value<String?> hashHiRes,
      Value<String?> hashSuper,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<int> rowid,
    });
typedef $$StoredSongsTableUpdateCompanionBuilder =
    StoredSongsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> artist,
      Value<String?> album,
      Value<int?> durationSecs,
      Value<String?> artworkUrl,
      Value<int?> privilege,
      Value<int?> albumId,
      Value<int?> mixSongId,
      Value<String?> hashStandard,
      Value<String?> hashHigh,
      Value<String?> hashFlac,
      Value<String?> hashHiRes,
      Value<String?> hashSuper,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<int> rowid,
    });

class $$StoredSongsTableFilterComposer
    extends Composer<_$AppDatabase, $StoredSongsTable> {
  $$StoredSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get privilege => $composableBuilder(
    column: $table.privilege,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mixSongId => $composableBuilder(
    column: $table.mixSongId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashStandard => $composableBuilder(
    column: $table.hashStandard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashHigh => $composableBuilder(
    column: $table.hashHigh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashFlac => $composableBuilder(
    column: $table.hashFlac,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashHiRes => $composableBuilder(
    column: $table.hashHiRes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashSuper => $composableBuilder(
    column: $table.hashSuper,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredSongsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoredSongsTable> {
  $$StoredSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get privilege => $composableBuilder(
    column: $table.privilege,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mixSongId => $composableBuilder(
    column: $table.mixSongId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashStandard => $composableBuilder(
    column: $table.hashStandard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashHigh => $composableBuilder(
    column: $table.hashHigh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashFlac => $composableBuilder(
    column: $table.hashFlac,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashHiRes => $composableBuilder(
    column: $table.hashHiRes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashSuper => $composableBuilder(
    column: $table.hashSuper,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredSongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoredSongsTable> {
  $$StoredSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get privilege =>
      $composableBuilder(column: $table.privilege, builder: (column) => column);

  GeneratedColumn<int> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<int> get mixSongId =>
      $composableBuilder(column: $table.mixSongId, builder: (column) => column);

  GeneratedColumn<String> get hashStandard => $composableBuilder(
    column: $table.hashStandard,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hashHigh =>
      $composableBuilder(column: $table.hashHigh, builder: (column) => column);

  GeneratedColumn<String> get hashFlac =>
      $composableBuilder(column: $table.hashFlac, builder: (column) => column);

  GeneratedColumn<String> get hashHiRes =>
      $composableBuilder(column: $table.hashHiRes, builder: (column) => column);

  GeneratedColumn<String> get hashSuper =>
      $composableBuilder(column: $table.hashSuper, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);
}

class $$StoredSongsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoredSongsTable,
          StoredSong,
          $$StoredSongsTableFilterComposer,
          $$StoredSongsTableOrderingComposer,
          $$StoredSongsTableAnnotationComposer,
          $$StoredSongsTableCreateCompanionBuilder,
          $$StoredSongsTableUpdateCompanionBuilder,
          (
            StoredSong,
            BaseReferences<_$AppDatabase, $StoredSongsTable, StoredSong>,
          ),
          StoredSong,
          PrefetchHooks Function()
        > {
  $$StoredSongsTableTableManager(_$AppDatabase db, $StoredSongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> privilege = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> mixSongId = const Value.absent(),
                Value<String?> hashStandard = const Value.absent(),
                Value<String?> hashHigh = const Value.absent(),
                Value<String?> hashFlac = const Value.absent(),
                Value<String?> hashHiRes = const Value.absent(),
                Value<String?> hashSuper = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredSongsCompanion(
                id: id,
                title: title,
                artist: artist,
                album: album,
                durationSecs: durationSecs,
                artworkUrl: artworkUrl,
                privilege: privilege,
                albumId: albumId,
                mixSongId: mixSongId,
                hashStandard: hashStandard,
                hashHigh: hashHigh,
                hashFlac: hashFlac,
                hashHiRes: hashHiRes,
                hashSuper: hashSuper,
                lastPlayedAt: lastPlayedAt,
                playCount: playCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> privilege = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> mixSongId = const Value.absent(),
                Value<String?> hashStandard = const Value.absent(),
                Value<String?> hashHigh = const Value.absent(),
                Value<String?> hashFlac = const Value.absent(),
                Value<String?> hashHiRes = const Value.absent(),
                Value<String?> hashSuper = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredSongsCompanion.insert(
                id: id,
                title: title,
                artist: artist,
                album: album,
                durationSecs: durationSecs,
                artworkUrl: artworkUrl,
                privilege: privilege,
                albumId: albumId,
                mixSongId: mixSongId,
                hashStandard: hashStandard,
                hashHigh: hashHigh,
                hashFlac: hashFlac,
                hashHiRes: hashHiRes,
                hashSuper: hashSuper,
                lastPlayedAt: lastPlayedAt,
                playCount: playCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredSongsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoredSongsTable,
      StoredSong,
      $$StoredSongsTableFilterComposer,
      $$StoredSongsTableOrderingComposer,
      $$StoredSongsTableAnnotationComposer,
      $$StoredSongsTableCreateCompanionBuilder,
      $$StoredSongsTableUpdateCompanionBuilder,
      (
        StoredSong,
        BaseReferences<_$AppDatabase, $StoredSongsTable, StoredSong>,
      ),
      StoredSong,
      PrefetchHooks Function()
    >;
typedef $$StoredPlaylistsTableCreateCompanionBuilder =
    StoredPlaylistsCompanion Function({
      required String localId,
      Value<int?> remoteListId,
      Value<String?> globalCollectionId,
      required String name,
      Value<String?> intro,
      Value<String?> artworkUrl,
      Value<int> count,
      Value<int?> listType,
      Value<int?> creatorUserId,
      Value<String?> creatorName,
      Value<bool> isPrivate,
      Value<bool> isMyFavorite,
      Value<bool> isDefaultCollect,
      Value<bool> tracksLoaded,
      Value<String?> tags,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$StoredPlaylistsTableUpdateCompanionBuilder =
    StoredPlaylistsCompanion Function({
      Value<String> localId,
      Value<int?> remoteListId,
      Value<String?> globalCollectionId,
      Value<String> name,
      Value<String?> intro,
      Value<String?> artworkUrl,
      Value<int> count,
      Value<int?> listType,
      Value<int?> creatorUserId,
      Value<String?> creatorName,
      Value<bool> isPrivate,
      Value<bool> isMyFavorite,
      Value<bool> isDefaultCollect,
      Value<bool> tracksLoaded,
      Value<String?> tags,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$StoredPlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $StoredPlaylistsTable> {
  $$StoredPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteListId => $composableBuilder(
    column: $table.remoteListId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get globalCollectionId => $composableBuilder(
    column: $table.globalCollectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intro => $composableBuilder(
    column: $table.intro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listType => $composableBuilder(
    column: $table.listType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creatorUserId => $composableBuilder(
    column: $table.creatorUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMyFavorite => $composableBuilder(
    column: $table.isMyFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefaultCollect => $composableBuilder(
    column: $table.isDefaultCollect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tracksLoaded => $composableBuilder(
    column: $table.tracksLoaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredPlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoredPlaylistsTable> {
  $$StoredPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteListId => $composableBuilder(
    column: $table.remoteListId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get globalCollectionId => $composableBuilder(
    column: $table.globalCollectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intro => $composableBuilder(
    column: $table.intro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listType => $composableBuilder(
    column: $table.listType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creatorUserId => $composableBuilder(
    column: $table.creatorUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMyFavorite => $composableBuilder(
    column: $table.isMyFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefaultCollect => $composableBuilder(
    column: $table.isDefaultCollect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tracksLoaded => $composableBuilder(
    column: $table.tracksLoaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredPlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoredPlaylistsTable> {
  $$StoredPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get remoteListId => $composableBuilder(
    column: $table.remoteListId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get globalCollectionId => $composableBuilder(
    column: $table.globalCollectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get intro =>
      $composableBuilder(column: $table.intro, builder: (column) => column);

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<int> get listType =>
      $composableBuilder(column: $table.listType, builder: (column) => column);

  GeneratedColumn<int> get creatorUserId => $composableBuilder(
    column: $table.creatorUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<bool> get isMyFavorite => $composableBuilder(
    column: $table.isMyFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefaultCollect => $composableBuilder(
    column: $table.isDefaultCollect,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tracksLoaded => $composableBuilder(
    column: $table.tracksLoaded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$StoredPlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoredPlaylistsTable,
          StoredPlaylist,
          $$StoredPlaylistsTableFilterComposer,
          $$StoredPlaylistsTableOrderingComposer,
          $$StoredPlaylistsTableAnnotationComposer,
          $$StoredPlaylistsTableCreateCompanionBuilder,
          $$StoredPlaylistsTableUpdateCompanionBuilder,
          (
            StoredPlaylist,
            BaseReferences<
              _$AppDatabase,
              $StoredPlaylistsTable,
              StoredPlaylist
            >,
          ),
          StoredPlaylist,
          PrefetchHooks Function()
        > {
  $$StoredPlaylistsTableTableManager(
    _$AppDatabase db,
    $StoredPlaylistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<int?> remoteListId = const Value.absent(),
                Value<String?> globalCollectionId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> intro = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int?> listType = const Value.absent(),
                Value<int?> creatorUserId = const Value.absent(),
                Value<String?> creatorName = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<bool> isMyFavorite = const Value.absent(),
                Value<bool> isDefaultCollect = const Value.absent(),
                Value<bool> tracksLoaded = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredPlaylistsCompanion(
                localId: localId,
                remoteListId: remoteListId,
                globalCollectionId: globalCollectionId,
                name: name,
                intro: intro,
                artworkUrl: artworkUrl,
                count: count,
                listType: listType,
                creatorUserId: creatorUserId,
                creatorName: creatorName,
                isPrivate: isPrivate,
                isMyFavorite: isMyFavorite,
                isDefaultCollect: isDefaultCollect,
                tracksLoaded: tracksLoaded,
                tags: tags,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<int?> remoteListId = const Value.absent(),
                Value<String?> globalCollectionId = const Value.absent(),
                required String name,
                Value<String?> intro = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int?> listType = const Value.absent(),
                Value<int?> creatorUserId = const Value.absent(),
                Value<String?> creatorName = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<bool> isMyFavorite = const Value.absent(),
                Value<bool> isDefaultCollect = const Value.absent(),
                Value<bool> tracksLoaded = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredPlaylistsCompanion.insert(
                localId: localId,
                remoteListId: remoteListId,
                globalCollectionId: globalCollectionId,
                name: name,
                intro: intro,
                artworkUrl: artworkUrl,
                count: count,
                listType: listType,
                creatorUserId: creatorUserId,
                creatorName: creatorName,
                isPrivate: isPrivate,
                isMyFavorite: isMyFavorite,
                isDefaultCollect: isDefaultCollect,
                tracksLoaded: tracksLoaded,
                tags: tags,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoredPlaylistsTable,
      StoredPlaylist,
      $$StoredPlaylistsTableFilterComposer,
      $$StoredPlaylistsTableOrderingComposer,
      $$StoredPlaylistsTableAnnotationComposer,
      $$StoredPlaylistsTableCreateCompanionBuilder,
      $$StoredPlaylistsTableUpdateCompanionBuilder,
      (
        StoredPlaylist,
        BaseReferences<_$AppDatabase, $StoredPlaylistsTable, StoredPlaylist>,
      ),
      StoredPlaylist,
      PrefetchHooks Function()
    >;
typedef $$StoredPlaylistTracksTableCreateCompanionBuilder =
    StoredPlaylistTracksCompanion Function({
      required String playlistLocalId,
      required String songId,
      Value<int?> fileId,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$StoredPlaylistTracksTableUpdateCompanionBuilder =
    StoredPlaylistTracksCompanion Function({
      Value<String> playlistLocalId,
      Value<String> songId,
      Value<int?> fileId,
      Value<int> position,
      Value<int> rowid,
    });

class $$StoredPlaylistTracksTableFilterComposer
    extends Composer<_$AppDatabase, $StoredPlaylistTracksTable> {
  $$StoredPlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistLocalId => $composableBuilder(
    column: $table.playlistLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredPlaylistTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $StoredPlaylistTracksTable> {
  $$StoredPlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistLocalId => $composableBuilder(
    column: $table.playlistLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredPlaylistTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoredPlaylistTracksTable> {
  $$StoredPlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistLocalId => $composableBuilder(
    column: $table.playlistLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<int> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$StoredPlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoredPlaylistTracksTable,
          StoredPlaylistTrack,
          $$StoredPlaylistTracksTableFilterComposer,
          $$StoredPlaylistTracksTableOrderingComposer,
          $$StoredPlaylistTracksTableAnnotationComposer,
          $$StoredPlaylistTracksTableCreateCompanionBuilder,
          $$StoredPlaylistTracksTableUpdateCompanionBuilder,
          (
            StoredPlaylistTrack,
            BaseReferences<
              _$AppDatabase,
              $StoredPlaylistTracksTable,
              StoredPlaylistTrack
            >,
          ),
          StoredPlaylistTrack,
          PrefetchHooks Function()
        > {
  $$StoredPlaylistTracksTableTableManager(
    _$AppDatabase db,
    $StoredPlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredPlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredPlaylistTracksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StoredPlaylistTracksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> playlistLocalId = const Value.absent(),
                Value<String> songId = const Value.absent(),
                Value<int?> fileId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredPlaylistTracksCompanion(
                playlistLocalId: playlistLocalId,
                songId: songId,
                fileId: fileId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistLocalId,
                required String songId,
                Value<int?> fileId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredPlaylistTracksCompanion.insert(
                playlistLocalId: playlistLocalId,
                songId: songId,
                fileId: fileId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredPlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoredPlaylistTracksTable,
      StoredPlaylistTrack,
      $$StoredPlaylistTracksTableFilterComposer,
      $$StoredPlaylistTracksTableOrderingComposer,
      $$StoredPlaylistTracksTableAnnotationComposer,
      $$StoredPlaylistTracksTableCreateCompanionBuilder,
      $$StoredPlaylistTracksTableUpdateCompanionBuilder,
      (
        StoredPlaylistTrack,
        BaseReferences<
          _$AppDatabase,
          $StoredPlaylistTracksTable,
          StoredPlaylistTrack
        >,
      ),
      StoredPlaylistTrack,
      PrefetchHooks Function()
    >;
typedef $$LibrarySyncStatesTableCreateCompanionBuilder =
    LibrarySyncStatesCompanion Function({
      Value<int> singletonId,
      required int userId,
      Value<bool> baselineComplete,
      Value<DateTime?> lastSyncedAt,
      Value<String?> lastError,
    });
typedef $$LibrarySyncStatesTableUpdateCompanionBuilder =
    LibrarySyncStatesCompanion Function({
      Value<int> singletonId,
      Value<int> userId,
      Value<bool> baselineComplete,
      Value<DateTime?> lastSyncedAt,
      Value<String?> lastError,
    });

class $$LibrarySyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $LibrarySyncStatesTable> {
  $$LibrarySyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get baselineComplete => $composableBuilder(
    column: $table.baselineComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibrarySyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $LibrarySyncStatesTable> {
  $$LibrarySyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get baselineComplete => $composableBuilder(
    column: $table.baselineComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibrarySyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibrarySyncStatesTable> {
  $$LibrarySyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get baselineComplete => $composableBuilder(
    column: $table.baselineComplete,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$LibrarySyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibrarySyncStatesTable,
          LibrarySyncState,
          $$LibrarySyncStatesTableFilterComposer,
          $$LibrarySyncStatesTableOrderingComposer,
          $$LibrarySyncStatesTableAnnotationComposer,
          $$LibrarySyncStatesTableCreateCompanionBuilder,
          $$LibrarySyncStatesTableUpdateCompanionBuilder,
          (
            LibrarySyncState,
            BaseReferences<
              _$AppDatabase,
              $LibrarySyncStatesTable,
              LibrarySyncState
            >,
          ),
          LibrarySyncState,
          PrefetchHooks Function()
        > {
  $$LibrarySyncStatesTableTableManager(
    _$AppDatabase db,
    $LibrarySyncStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibrarySyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibrarySyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibrarySyncStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<bool> baselineComplete = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => LibrarySyncStatesCompanion(
                singletonId: singletonId,
                userId: userId,
                baselineComplete: baselineComplete,
                lastSyncedAt: lastSyncedAt,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                required int userId,
                Value<bool> baselineComplete = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => LibrarySyncStatesCompanion.insert(
                singletonId: singletonId,
                userId: userId,
                baselineComplete: baselineComplete,
                lastSyncedAt: lastSyncedAt,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibrarySyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibrarySyncStatesTable,
      LibrarySyncState,
      $$LibrarySyncStatesTableFilterComposer,
      $$LibrarySyncStatesTableOrderingComposer,
      $$LibrarySyncStatesTableAnnotationComposer,
      $$LibrarySyncStatesTableCreateCompanionBuilder,
      $$LibrarySyncStatesTableUpdateCompanionBuilder,
      (
        LibrarySyncState,
        BaseReferences<
          _$AppDatabase,
          $LibrarySyncStatesTable,
          LibrarySyncState
        >,
      ),
      LibrarySyncState,
      PrefetchHooks Function()
    >;
typedef $$CachedResponsesTableCreateCompanionBuilder =
    CachedResponsesCompanion Function({
      required String cacheKey,
      Value<int?> accountUserId,
      required int codecVersion,
      required String payload,
      required DateTime updatedAt,
      required DateTime lastAccessedAt,
      Value<int> rowid,
    });
typedef $$CachedResponsesTableUpdateCompanionBuilder =
    CachedResponsesCompanion Function({
      Value<String> cacheKey,
      Value<int?> accountUserId,
      Value<int> codecVersion,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<DateTime> lastAccessedAt,
      Value<int> rowid,
    });

class $$CachedResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedResponsesTable> {
  $$CachedResponsesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountUserId => $composableBuilder(
    column: $table.accountUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get codecVersion => $composableBuilder(
    column: $table.codecVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedResponsesTable> {
  $$CachedResponsesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountUserId => $composableBuilder(
    column: $table.accountUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get codecVersion => $composableBuilder(
    column: $table.codecVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedResponsesTable> {
  $$CachedResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<int> get accountUserId => $composableBuilder(
    column: $table.accountUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get codecVersion => $composableBuilder(
    column: $table.codecVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );
}

class $$CachedResponsesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedResponsesTable,
          CachedResponse,
          $$CachedResponsesTableFilterComposer,
          $$CachedResponsesTableOrderingComposer,
          $$CachedResponsesTableAnnotationComposer,
          $$CachedResponsesTableCreateCompanionBuilder,
          $$CachedResponsesTableUpdateCompanionBuilder,
          (
            CachedResponse,
            BaseReferences<
              _$AppDatabase,
              $CachedResponsesTable,
              CachedResponse
            >,
          ),
          CachedResponse,
          PrefetchHooks Function()
        > {
  $$CachedResponsesTableTableManager(
    _$AppDatabase db,
    $CachedResponsesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedResponsesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedResponsesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedResponsesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<int?> accountUserId = const Value.absent(),
                Value<int> codecVersion = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedResponsesCompanion(
                cacheKey: cacheKey,
                accountUserId: accountUserId,
                codecVersion: codecVersion,
                payload: payload,
                updatedAt: updatedAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                Value<int?> accountUserId = const Value.absent(),
                required int codecVersion,
                required String payload,
                required DateTime updatedAt,
                required DateTime lastAccessedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedResponsesCompanion.insert(
                cacheKey: cacheKey,
                accountUserId: accountUserId,
                codecVersion: codecVersion,
                payload: payload,
                updatedAt: updatedAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedResponsesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedResponsesTable,
      CachedResponse,
      $$CachedResponsesTableFilterComposer,
      $$CachedResponsesTableOrderingComposer,
      $$CachedResponsesTableAnnotationComposer,
      $$CachedResponsesTableCreateCompanionBuilder,
      $$CachedResponsesTableUpdateCompanionBuilder,
      (
        CachedResponse,
        BaseReferences<_$AppDatabase, $CachedResponsesTable, CachedResponse>,
      ),
      CachedResponse,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StoredSongsTableTableManager get storedSongs =>
      $$StoredSongsTableTableManager(_db, _db.storedSongs);
  $$StoredPlaylistsTableTableManager get storedPlaylists =>
      $$StoredPlaylistsTableTableManager(_db, _db.storedPlaylists);
  $$StoredPlaylistTracksTableTableManager get storedPlaylistTracks =>
      $$StoredPlaylistTracksTableTableManager(_db, _db.storedPlaylistTracks);
  $$LibrarySyncStatesTableTableManager get librarySyncStates =>
      $$LibrarySyncStatesTableTableManager(_db, _db.librarySyncStates);
  $$CachedResponsesTableTableManager get cachedResponses =>
      $$CachedResponsesTableTableManager(_db, _db.cachedResponses);
}
