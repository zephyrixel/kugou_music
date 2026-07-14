// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LibraryTracksTable extends LibraryTracks
    with TableInfo<$LibraryTracksTable, LibraryTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryTracksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    favorite,
    lastPlayedAt,
    playCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryTrack> instance, {
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
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
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
  LibraryTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryTrack(
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
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
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
  $LibraryTracksTable createAlias(String alias) {
    return $LibraryTracksTable(attachedDatabase, alias);
  }
}

class LibraryTrack extends DataClass implements Insertable<LibraryTrack> {
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
  final bool favorite;
  final DateTime? lastPlayedAt;
  final int playCount;
  const LibraryTrack({
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
    required this.favorite,
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
    map['favorite'] = Variable<bool>(favorite);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['play_count'] = Variable<int>(playCount);
    return map;
  }

  LibraryTracksCompanion toCompanion(bool nullToAbsent) {
    return LibraryTracksCompanion(
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
      favorite: Value(favorite),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      playCount: Value(playCount),
    );
  }

  factory LibraryTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryTrack(
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
      favorite: serializer.fromJson<bool>(json['favorite']),
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
      'favorite': serializer.toJson<bool>(favorite),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'playCount': serializer.toJson<int>(playCount),
    };
  }

  LibraryTrack copyWith({
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
    bool? favorite,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    int? playCount,
  }) => LibraryTrack(
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
    favorite: favorite ?? this.favorite,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    playCount: playCount ?? this.playCount,
  );
  LibraryTrack copyWithCompanion(LibraryTracksCompanion data) {
    return LibraryTrack(
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
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryTrack(')
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
          ..write('favorite: $favorite, ')
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
    favorite,
    lastPlayedAt,
    playCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryTrack &&
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
          other.favorite == this.favorite &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.playCount == this.playCount);
}

class LibraryTracksCompanion extends UpdateCompanion<LibraryTrack> {
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
  final Value<bool> favorite;
  final Value<DateTime?> lastPlayedAt;
  final Value<int> playCount;
  final Value<int> rowid;
  const LibraryTracksCompanion({
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
    this.favorite = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryTracksCompanion.insert({
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
    this.favorite = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.playCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<LibraryTrack> custom({
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
    Expression<bool>? favorite,
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
      if (favorite != null) 'favorite': favorite,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (playCount != null) 'play_count': playCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryTracksCompanion copyWith({
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
    Value<bool>? favorite,
    Value<DateTime?>? lastPlayedAt,
    Value<int>? playCount,
    Value<int>? rowid,
  }) {
    return LibraryTracksCompanion(
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
      favorite: favorite ?? this.favorite,
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
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
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
    return (StringBuffer('LibraryTracksCompanion(')
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
          ..write('favorite: $favorite, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('playCount: $playCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCloudPlaylistsTable extends CachedCloudPlaylists
    with TableInfo<$CachedCloudPlaylistsTable, CachedCloudPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCloudPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountUserIdMeta = const VerificationMeta(
    'accountUserId',
  );
  @override
  late final GeneratedColumn<int> accountUserId = GeneratedColumn<int>(
    'account_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _trackCountMeta = const VerificationMeta(
    'trackCount',
  );
  @override
  late final GeneratedColumn<int> trackCount = GeneratedColumn<int>(
    'track_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_private" IN (0, 1))',
    ),
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
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_my_favorite" IN (0, 1))',
    ),
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
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default_collect" IN (0, 1))',
    ),
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountUserId,
    listId,
    globalCollectionId,
    name,
    intro,
    artworkUrl,
    trackCount,
    listType,
    creatorUserId,
    creatorName,
    isPrivate,
    isMyFavorite,
    isDefaultCollect,
    tags,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_cloud_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCloudPlaylist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_user_id')) {
      context.handle(
        _accountUserIdMeta,
        accountUserId.isAcceptableOrUnknown(
          data['account_user_id']!,
          _accountUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountUserIdMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
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
    if (data.containsKey('track_count')) {
      context.handle(
        _trackCountMeta,
        trackCount.isAcceptableOrUnknown(data['track_count']!, _trackCountMeta),
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
    } else if (isInserting) {
      context.missing(_isPrivateMeta);
    }
    if (data.containsKey('is_my_favorite')) {
      context.handle(
        _isMyFavoriteMeta,
        isMyFavorite.isAcceptableOrUnknown(
          data['is_my_favorite']!,
          _isMyFavoriteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isMyFavoriteMeta);
    }
    if (data.containsKey('is_default_collect')) {
      context.handle(
        _isDefaultCollectMeta,
        isDefaultCollect.isAcceptableOrUnknown(
          data['is_default_collect']!,
          _isDefaultCollectMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isDefaultCollectMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountUserId, listId};
  @override
  CachedCloudPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCloudPlaylist(
      accountUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_user_id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_id'],
      )!,
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
      trackCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_count'],
      ),
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
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $CachedCloudPlaylistsTable createAlias(String alias) {
    return $CachedCloudPlaylistsTable(attachedDatabase, alias);
  }
}

class CachedCloudPlaylist extends DataClass
    implements Insertable<CachedCloudPlaylist> {
  final int accountUserId;
  final int listId;
  final String? globalCollectionId;
  final String name;
  final String? intro;
  final String? artworkUrl;
  final int? trackCount;
  final int? listType;
  final int? creatorUserId;
  final String? creatorName;
  final bool isPrivate;
  final bool isMyFavorite;
  final bool isDefaultCollect;
  final String? tags;
  final DateTime syncedAt;
  const CachedCloudPlaylist({
    required this.accountUserId,
    required this.listId,
    this.globalCollectionId,
    required this.name,
    this.intro,
    this.artworkUrl,
    this.trackCount,
    this.listType,
    this.creatorUserId,
    this.creatorName,
    required this.isPrivate,
    required this.isMyFavorite,
    required this.isDefaultCollect,
    this.tags,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_user_id'] = Variable<int>(accountUserId);
    map['list_id'] = Variable<int>(listId);
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
    if (!nullToAbsent || trackCount != null) {
      map['track_count'] = Variable<int>(trackCount);
    }
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
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  CachedCloudPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return CachedCloudPlaylistsCompanion(
      accountUserId: Value(accountUserId),
      listId: Value(listId),
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
      trackCount: trackCount == null && nullToAbsent
          ? const Value.absent()
          : Value(trackCount),
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
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      syncedAt: Value(syncedAt),
    );
  }

  factory CachedCloudPlaylist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCloudPlaylist(
      accountUserId: serializer.fromJson<int>(json['accountUserId']),
      listId: serializer.fromJson<int>(json['listId']),
      globalCollectionId: serializer.fromJson<String?>(
        json['globalCollectionId'],
      ),
      name: serializer.fromJson<String>(json['name']),
      intro: serializer.fromJson<String?>(json['intro']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      trackCount: serializer.fromJson<int?>(json['trackCount']),
      listType: serializer.fromJson<int?>(json['listType']),
      creatorUserId: serializer.fromJson<int?>(json['creatorUserId']),
      creatorName: serializer.fromJson<String?>(json['creatorName']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      isMyFavorite: serializer.fromJson<bool>(json['isMyFavorite']),
      isDefaultCollect: serializer.fromJson<bool>(json['isDefaultCollect']),
      tags: serializer.fromJson<String?>(json['tags']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountUserId': serializer.toJson<int>(accountUserId),
      'listId': serializer.toJson<int>(listId),
      'globalCollectionId': serializer.toJson<String?>(globalCollectionId),
      'name': serializer.toJson<String>(name),
      'intro': serializer.toJson<String?>(intro),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'trackCount': serializer.toJson<int?>(trackCount),
      'listType': serializer.toJson<int?>(listType),
      'creatorUserId': serializer.toJson<int?>(creatorUserId),
      'creatorName': serializer.toJson<String?>(creatorName),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'isMyFavorite': serializer.toJson<bool>(isMyFavorite),
      'isDefaultCollect': serializer.toJson<bool>(isDefaultCollect),
      'tags': serializer.toJson<String?>(tags),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  CachedCloudPlaylist copyWith({
    int? accountUserId,
    int? listId,
    Value<String?> globalCollectionId = const Value.absent(),
    String? name,
    Value<String?> intro = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    Value<int?> trackCount = const Value.absent(),
    Value<int?> listType = const Value.absent(),
    Value<int?> creatorUserId = const Value.absent(),
    Value<String?> creatorName = const Value.absent(),
    bool? isPrivate,
    bool? isMyFavorite,
    bool? isDefaultCollect,
    Value<String?> tags = const Value.absent(),
    DateTime? syncedAt,
  }) => CachedCloudPlaylist(
    accountUserId: accountUserId ?? this.accountUserId,
    listId: listId ?? this.listId,
    globalCollectionId: globalCollectionId.present
        ? globalCollectionId.value
        : this.globalCollectionId,
    name: name ?? this.name,
    intro: intro.present ? intro.value : this.intro,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    trackCount: trackCount.present ? trackCount.value : this.trackCount,
    listType: listType.present ? listType.value : this.listType,
    creatorUserId: creatorUserId.present
        ? creatorUserId.value
        : this.creatorUserId,
    creatorName: creatorName.present ? creatorName.value : this.creatorName,
    isPrivate: isPrivate ?? this.isPrivate,
    isMyFavorite: isMyFavorite ?? this.isMyFavorite,
    isDefaultCollect: isDefaultCollect ?? this.isDefaultCollect,
    tags: tags.present ? tags.value : this.tags,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  CachedCloudPlaylist copyWithCompanion(CachedCloudPlaylistsCompanion data) {
    return CachedCloudPlaylist(
      accountUserId: data.accountUserId.present
          ? data.accountUserId.value
          : this.accountUserId,
      listId: data.listId.present ? data.listId.value : this.listId,
      globalCollectionId: data.globalCollectionId.present
          ? data.globalCollectionId.value
          : this.globalCollectionId,
      name: data.name.present ? data.name.value : this.name,
      intro: data.intro.present ? data.intro.value : this.intro,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      trackCount: data.trackCount.present
          ? data.trackCount.value
          : this.trackCount,
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
      tags: data.tags.present ? data.tags.value : this.tags,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCloudPlaylist(')
          ..write('accountUserId: $accountUserId, ')
          ..write('listId: $listId, ')
          ..write('globalCollectionId: $globalCollectionId, ')
          ..write('name: $name, ')
          ..write('intro: $intro, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('trackCount: $trackCount, ')
          ..write('listType: $listType, ')
          ..write('creatorUserId: $creatorUserId, ')
          ..write('creatorName: $creatorName, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('isMyFavorite: $isMyFavorite, ')
          ..write('isDefaultCollect: $isDefaultCollect, ')
          ..write('tags: $tags, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountUserId,
    listId,
    globalCollectionId,
    name,
    intro,
    artworkUrl,
    trackCount,
    listType,
    creatorUserId,
    creatorName,
    isPrivate,
    isMyFavorite,
    isDefaultCollect,
    tags,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCloudPlaylist &&
          other.accountUserId == this.accountUserId &&
          other.listId == this.listId &&
          other.globalCollectionId == this.globalCollectionId &&
          other.name == this.name &&
          other.intro == this.intro &&
          other.artworkUrl == this.artworkUrl &&
          other.trackCount == this.trackCount &&
          other.listType == this.listType &&
          other.creatorUserId == this.creatorUserId &&
          other.creatorName == this.creatorName &&
          other.isPrivate == this.isPrivate &&
          other.isMyFavorite == this.isMyFavorite &&
          other.isDefaultCollect == this.isDefaultCollect &&
          other.tags == this.tags &&
          other.syncedAt == this.syncedAt);
}

class CachedCloudPlaylistsCompanion
    extends UpdateCompanion<CachedCloudPlaylist> {
  final Value<int> accountUserId;
  final Value<int> listId;
  final Value<String?> globalCollectionId;
  final Value<String> name;
  final Value<String?> intro;
  final Value<String?> artworkUrl;
  final Value<int?> trackCount;
  final Value<int?> listType;
  final Value<int?> creatorUserId;
  final Value<String?> creatorName;
  final Value<bool> isPrivate;
  final Value<bool> isMyFavorite;
  final Value<bool> isDefaultCollect;
  final Value<String?> tags;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const CachedCloudPlaylistsCompanion({
    this.accountUserId = const Value.absent(),
    this.listId = const Value.absent(),
    this.globalCollectionId = const Value.absent(),
    this.name = const Value.absent(),
    this.intro = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.trackCount = const Value.absent(),
    this.listType = const Value.absent(),
    this.creatorUserId = const Value.absent(),
    this.creatorName = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.isMyFavorite = const Value.absent(),
    this.isDefaultCollect = const Value.absent(),
    this.tags = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCloudPlaylistsCompanion.insert({
    required int accountUserId,
    required int listId,
    this.globalCollectionId = const Value.absent(),
    required String name,
    this.intro = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.trackCount = const Value.absent(),
    this.listType = const Value.absent(),
    this.creatorUserId = const Value.absent(),
    this.creatorName = const Value.absent(),
    required bool isPrivate,
    required bool isMyFavorite,
    required bool isDefaultCollect,
    this.tags = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : accountUserId = Value(accountUserId),
       listId = Value(listId),
       name = Value(name),
       isPrivate = Value(isPrivate),
       isMyFavorite = Value(isMyFavorite),
       isDefaultCollect = Value(isDefaultCollect),
       syncedAt = Value(syncedAt);
  static Insertable<CachedCloudPlaylist> custom({
    Expression<int>? accountUserId,
    Expression<int>? listId,
    Expression<String>? globalCollectionId,
    Expression<String>? name,
    Expression<String>? intro,
    Expression<String>? artworkUrl,
    Expression<int>? trackCount,
    Expression<int>? listType,
    Expression<int>? creatorUserId,
    Expression<String>? creatorName,
    Expression<bool>? isPrivate,
    Expression<bool>? isMyFavorite,
    Expression<bool>? isDefaultCollect,
    Expression<String>? tags,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountUserId != null) 'account_user_id': accountUserId,
      if (listId != null) 'list_id': listId,
      if (globalCollectionId != null)
        'global_collection_id': globalCollectionId,
      if (name != null) 'name': name,
      if (intro != null) 'intro': intro,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (trackCount != null) 'track_count': trackCount,
      if (listType != null) 'list_type': listType,
      if (creatorUserId != null) 'creator_user_id': creatorUserId,
      if (creatorName != null) 'creator_name': creatorName,
      if (isPrivate != null) 'is_private': isPrivate,
      if (isMyFavorite != null) 'is_my_favorite': isMyFavorite,
      if (isDefaultCollect != null) 'is_default_collect': isDefaultCollect,
      if (tags != null) 'tags': tags,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCloudPlaylistsCompanion copyWith({
    Value<int>? accountUserId,
    Value<int>? listId,
    Value<String?>? globalCollectionId,
    Value<String>? name,
    Value<String?>? intro,
    Value<String?>? artworkUrl,
    Value<int?>? trackCount,
    Value<int?>? listType,
    Value<int?>? creatorUserId,
    Value<String?>? creatorName,
    Value<bool>? isPrivate,
    Value<bool>? isMyFavorite,
    Value<bool>? isDefaultCollect,
    Value<String?>? tags,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return CachedCloudPlaylistsCompanion(
      accountUserId: accountUserId ?? this.accountUserId,
      listId: listId ?? this.listId,
      globalCollectionId: globalCollectionId ?? this.globalCollectionId,
      name: name ?? this.name,
      intro: intro ?? this.intro,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      trackCount: trackCount ?? this.trackCount,
      listType: listType ?? this.listType,
      creatorUserId: creatorUserId ?? this.creatorUserId,
      creatorName: creatorName ?? this.creatorName,
      isPrivate: isPrivate ?? this.isPrivate,
      isMyFavorite: isMyFavorite ?? this.isMyFavorite,
      isDefaultCollect: isDefaultCollect ?? this.isDefaultCollect,
      tags: tags ?? this.tags,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountUserId.present) {
      map['account_user_id'] = Variable<int>(accountUserId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
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
    if (trackCount.present) {
      map['track_count'] = Variable<int>(trackCount.value);
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
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCloudPlaylistsCompanion(')
          ..write('accountUserId: $accountUserId, ')
          ..write('listId: $listId, ')
          ..write('globalCollectionId: $globalCollectionId, ')
          ..write('name: $name, ')
          ..write('intro: $intro, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('trackCount: $trackCount, ')
          ..write('listType: $listType, ')
          ..write('creatorUserId: $creatorUserId, ')
          ..write('creatorName: $creatorName, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('isMyFavorite: $isMyFavorite, ')
          ..write('isDefaultCollect: $isDefaultCollect, ')
          ..write('tags: $tags, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCloudTracksTable extends CachedCloudTracks
    with TableInfo<$CachedCloudTracksTable, CachedCloudTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCloudTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountUserIdMeta = const VerificationMeta(
    'accountUserId',
  );
  @override
  late final GeneratedColumn<int> accountUserId = GeneratedColumn<int>(
    'account_user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountUserId,
    listId,
    songId,
    fileId,
    position,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_cloud_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCloudTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_user_id')) {
      context.handle(
        _accountUserIdMeta,
        accountUserId.isAcceptableOrUnknown(
          data['account_user_id']!,
          _accountUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountUserIdMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
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
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountUserId, listId, songId};
  @override
  CachedCloudTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCloudTrack(
      accountUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_user_id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_id'],
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
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $CachedCloudTracksTable createAlias(String alias) {
    return $CachedCloudTracksTable(attachedDatabase, alias);
  }
}

class CachedCloudTrack extends DataClass
    implements Insertable<CachedCloudTrack> {
  final int accountUserId;
  final int listId;
  final String songId;
  final int? fileId;
  final int position;
  final DateTime syncedAt;
  const CachedCloudTrack({
    required this.accountUserId,
    required this.listId,
    required this.songId,
    this.fileId,
    required this.position,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_user_id'] = Variable<int>(accountUserId);
    map['list_id'] = Variable<int>(listId);
    map['song_id'] = Variable<String>(songId);
    if (!nullToAbsent || fileId != null) {
      map['file_id'] = Variable<int>(fileId);
    }
    map['position'] = Variable<int>(position);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  CachedCloudTracksCompanion toCompanion(bool nullToAbsent) {
    return CachedCloudTracksCompanion(
      accountUserId: Value(accountUserId),
      listId: Value(listId),
      songId: Value(songId),
      fileId: fileId == null && nullToAbsent
          ? const Value.absent()
          : Value(fileId),
      position: Value(position),
      syncedAt: Value(syncedAt),
    );
  }

  factory CachedCloudTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCloudTrack(
      accountUserId: serializer.fromJson<int>(json['accountUserId']),
      listId: serializer.fromJson<int>(json['listId']),
      songId: serializer.fromJson<String>(json['songId']),
      fileId: serializer.fromJson<int?>(json['fileId']),
      position: serializer.fromJson<int>(json['position']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountUserId': serializer.toJson<int>(accountUserId),
      'listId': serializer.toJson<int>(listId),
      'songId': serializer.toJson<String>(songId),
      'fileId': serializer.toJson<int?>(fileId),
      'position': serializer.toJson<int>(position),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  CachedCloudTrack copyWith({
    int? accountUserId,
    int? listId,
    String? songId,
    Value<int?> fileId = const Value.absent(),
    int? position,
    DateTime? syncedAt,
  }) => CachedCloudTrack(
    accountUserId: accountUserId ?? this.accountUserId,
    listId: listId ?? this.listId,
    songId: songId ?? this.songId,
    fileId: fileId.present ? fileId.value : this.fileId,
    position: position ?? this.position,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  CachedCloudTrack copyWithCompanion(CachedCloudTracksCompanion data) {
    return CachedCloudTrack(
      accountUserId: data.accountUserId.present
          ? data.accountUserId.value
          : this.accountUserId,
      listId: data.listId.present ? data.listId.value : this.listId,
      songId: data.songId.present ? data.songId.value : this.songId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      position: data.position.present ? data.position.value : this.position,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCloudTrack(')
          ..write('accountUserId: $accountUserId, ')
          ..write('listId: $listId, ')
          ..write('songId: $songId, ')
          ..write('fileId: $fileId, ')
          ..write('position: $position, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountUserId, listId, songId, fileId, position, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCloudTrack &&
          other.accountUserId == this.accountUserId &&
          other.listId == this.listId &&
          other.songId == this.songId &&
          other.fileId == this.fileId &&
          other.position == this.position &&
          other.syncedAt == this.syncedAt);
}

class CachedCloudTracksCompanion extends UpdateCompanion<CachedCloudTrack> {
  final Value<int> accountUserId;
  final Value<int> listId;
  final Value<String> songId;
  final Value<int?> fileId;
  final Value<int> position;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const CachedCloudTracksCompanion({
    this.accountUserId = const Value.absent(),
    this.listId = const Value.absent(),
    this.songId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.position = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCloudTracksCompanion.insert({
    required int accountUserId,
    required int listId,
    required String songId,
    this.fileId = const Value.absent(),
    required int position,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : accountUserId = Value(accountUserId),
       listId = Value(listId),
       songId = Value(songId),
       position = Value(position),
       syncedAt = Value(syncedAt);
  static Insertable<CachedCloudTrack> custom({
    Expression<int>? accountUserId,
    Expression<int>? listId,
    Expression<String>? songId,
    Expression<int>? fileId,
    Expression<int>? position,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountUserId != null) 'account_user_id': accountUserId,
      if (listId != null) 'list_id': listId,
      if (songId != null) 'song_id': songId,
      if (fileId != null) 'file_id': fileId,
      if (position != null) 'position': position,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCloudTracksCompanion copyWith({
    Value<int>? accountUserId,
    Value<int>? listId,
    Value<String>? songId,
    Value<int?>? fileId,
    Value<int>? position,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return CachedCloudTracksCompanion(
      accountUserId: accountUserId ?? this.accountUserId,
      listId: listId ?? this.listId,
      songId: songId ?? this.songId,
      fileId: fileId ?? this.fileId,
      position: position ?? this.position,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountUserId.present) {
      map['account_user_id'] = Variable<int>(accountUserId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
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
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCloudTracksCompanion(')
          ..write('accountUserId: $accountUserId, ')
          ..write('listId: $listId, ')
          ..write('songId: $songId, ')
          ..write('fileId: $fileId, ')
          ..write('position: $position, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LibraryTracksTable libraryTracks = $LibraryTracksTable(this);
  late final $CachedCloudPlaylistsTable cachedCloudPlaylists =
      $CachedCloudPlaylistsTable(this);
  late final $CachedCloudTracksTable cachedCloudTracks =
      $CachedCloudTracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    libraryTracks,
    cachedCloudPlaylists,
    cachedCloudTracks,
  ];
}

typedef $$LibraryTracksTableCreateCompanionBuilder =
    LibraryTracksCompanion Function({
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
      Value<bool> favorite,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<int> rowid,
    });
typedef $$LibraryTracksTableUpdateCompanionBuilder =
    LibraryTracksCompanion Function({
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
      Value<bool> favorite,
      Value<DateTime?> lastPlayedAt,
      Value<int> playCount,
      Value<int> rowid,
    });

class $$LibraryTracksTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableFilterComposer({
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

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
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

class $$LibraryTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableOrderingComposer({
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

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
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

class $$LibraryTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryTracksTable> {
  $$LibraryTracksTableAnnotationComposer({
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

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);
}

class $$LibraryTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryTracksTable,
          LibraryTrack,
          $$LibraryTracksTableFilterComposer,
          $$LibraryTracksTableOrderingComposer,
          $$LibraryTracksTableAnnotationComposer,
          $$LibraryTracksTableCreateCompanionBuilder,
          $$LibraryTracksTableUpdateCompanionBuilder,
          (
            LibraryTrack,
            BaseReferences<_$AppDatabase, $LibraryTracksTable, LibraryTrack>,
          ),
          LibraryTrack,
          PrefetchHooks Function()
        > {
  $$LibraryTracksTableTableManager(_$AppDatabase db, $LibraryTracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryTracksTableAnnotationComposer($db: db, $table: table),
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
                Value<bool> favorite = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryTracksCompanion(
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
                favorite: favorite,
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
                Value<bool> favorite = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryTracksCompanion.insert(
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
                favorite: favorite,
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

typedef $$LibraryTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryTracksTable,
      LibraryTrack,
      $$LibraryTracksTableFilterComposer,
      $$LibraryTracksTableOrderingComposer,
      $$LibraryTracksTableAnnotationComposer,
      $$LibraryTracksTableCreateCompanionBuilder,
      $$LibraryTracksTableUpdateCompanionBuilder,
      (
        LibraryTrack,
        BaseReferences<_$AppDatabase, $LibraryTracksTable, LibraryTrack>,
      ),
      LibraryTrack,
      PrefetchHooks Function()
    >;
typedef $$CachedCloudPlaylistsTableCreateCompanionBuilder =
    CachedCloudPlaylistsCompanion Function({
      required int accountUserId,
      required int listId,
      Value<String?> globalCollectionId,
      required String name,
      Value<String?> intro,
      Value<String?> artworkUrl,
      Value<int?> trackCount,
      Value<int?> listType,
      Value<int?> creatorUserId,
      Value<String?> creatorName,
      required bool isPrivate,
      required bool isMyFavorite,
      required bool isDefaultCollect,
      Value<String?> tags,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$CachedCloudPlaylistsTableUpdateCompanionBuilder =
    CachedCloudPlaylistsCompanion Function({
      Value<int> accountUserId,
      Value<int> listId,
      Value<String?> globalCollectionId,
      Value<String> name,
      Value<String?> intro,
      Value<String?> artworkUrl,
      Value<int?> trackCount,
      Value<int?> listType,
      Value<int?> creatorUserId,
      Value<String?> creatorName,
      Value<bool> isPrivate,
      Value<bool> isMyFavorite,
      Value<bool> isDefaultCollect,
      Value<String?> tags,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$CachedCloudPlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCloudPlaylistsTable> {
  $$CachedCloudPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get accountUserId => $composableBuilder(
    column: $table.accountUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listId => $composableBuilder(
    column: $table.listId,
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

  ColumnFilters<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
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

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCloudPlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCloudPlaylistsTable> {
  $$CachedCloudPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get accountUserId => $composableBuilder(
    column: $table.accountUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listId => $composableBuilder(
    column: $table.listId,
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

  ColumnOrderings<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
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

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCloudPlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCloudPlaylistsTable> {
  $$CachedCloudPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get accountUserId => $composableBuilder(
    column: $table.accountUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

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

  GeneratedColumn<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => column,
  );

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

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$CachedCloudPlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCloudPlaylistsTable,
          CachedCloudPlaylist,
          $$CachedCloudPlaylistsTableFilterComposer,
          $$CachedCloudPlaylistsTableOrderingComposer,
          $$CachedCloudPlaylistsTableAnnotationComposer,
          $$CachedCloudPlaylistsTableCreateCompanionBuilder,
          $$CachedCloudPlaylistsTableUpdateCompanionBuilder,
          (
            CachedCloudPlaylist,
            BaseReferences<
              _$AppDatabase,
              $CachedCloudPlaylistsTable,
              CachedCloudPlaylist
            >,
          ),
          CachedCloudPlaylist,
          PrefetchHooks Function()
        > {
  $$CachedCloudPlaylistsTableTableManager(
    _$AppDatabase db,
    $CachedCloudPlaylistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCloudPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCloudPlaylistsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedCloudPlaylistsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> accountUserId = const Value.absent(),
                Value<int> listId = const Value.absent(),
                Value<String?> globalCollectionId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> intro = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> trackCount = const Value.absent(),
                Value<int?> listType = const Value.absent(),
                Value<int?> creatorUserId = const Value.absent(),
                Value<String?> creatorName = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<bool> isMyFavorite = const Value.absent(),
                Value<bool> isDefaultCollect = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCloudPlaylistsCompanion(
                accountUserId: accountUserId,
                listId: listId,
                globalCollectionId: globalCollectionId,
                name: name,
                intro: intro,
                artworkUrl: artworkUrl,
                trackCount: trackCount,
                listType: listType,
                creatorUserId: creatorUserId,
                creatorName: creatorName,
                isPrivate: isPrivate,
                isMyFavorite: isMyFavorite,
                isDefaultCollect: isDefaultCollect,
                tags: tags,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int accountUserId,
                required int listId,
                Value<String?> globalCollectionId = const Value.absent(),
                required String name,
                Value<String?> intro = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> trackCount = const Value.absent(),
                Value<int?> listType = const Value.absent(),
                Value<int?> creatorUserId = const Value.absent(),
                Value<String?> creatorName = const Value.absent(),
                required bool isPrivate,
                required bool isMyFavorite,
                required bool isDefaultCollect,
                Value<String?> tags = const Value.absent(),
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCloudPlaylistsCompanion.insert(
                accountUserId: accountUserId,
                listId: listId,
                globalCollectionId: globalCollectionId,
                name: name,
                intro: intro,
                artworkUrl: artworkUrl,
                trackCount: trackCount,
                listType: listType,
                creatorUserId: creatorUserId,
                creatorName: creatorName,
                isPrivate: isPrivate,
                isMyFavorite: isMyFavorite,
                isDefaultCollect: isDefaultCollect,
                tags: tags,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCloudPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCloudPlaylistsTable,
      CachedCloudPlaylist,
      $$CachedCloudPlaylistsTableFilterComposer,
      $$CachedCloudPlaylistsTableOrderingComposer,
      $$CachedCloudPlaylistsTableAnnotationComposer,
      $$CachedCloudPlaylistsTableCreateCompanionBuilder,
      $$CachedCloudPlaylistsTableUpdateCompanionBuilder,
      (
        CachedCloudPlaylist,
        BaseReferences<
          _$AppDatabase,
          $CachedCloudPlaylistsTable,
          CachedCloudPlaylist
        >,
      ),
      CachedCloudPlaylist,
      PrefetchHooks Function()
    >;
typedef $$CachedCloudTracksTableCreateCompanionBuilder =
    CachedCloudTracksCompanion Function({
      required int accountUserId,
      required int listId,
      required String songId,
      Value<int?> fileId,
      required int position,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$CachedCloudTracksTableUpdateCompanionBuilder =
    CachedCloudTracksCompanion Function({
      Value<int> accountUserId,
      Value<int> listId,
      Value<String> songId,
      Value<int?> fileId,
      Value<int> position,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$CachedCloudTracksTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCloudTracksTable> {
  $$CachedCloudTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get accountUserId => $composableBuilder(
    column: $table.accountUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listId => $composableBuilder(
    column: $table.listId,
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

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCloudTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCloudTracksTable> {
  $$CachedCloudTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get accountUserId => $composableBuilder(
    column: $table.accountUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listId => $composableBuilder(
    column: $table.listId,
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

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCloudTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCloudTracksTable> {
  $$CachedCloudTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get accountUserId => $composableBuilder(
    column: $table.accountUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<int> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$CachedCloudTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCloudTracksTable,
          CachedCloudTrack,
          $$CachedCloudTracksTableFilterComposer,
          $$CachedCloudTracksTableOrderingComposer,
          $$CachedCloudTracksTableAnnotationComposer,
          $$CachedCloudTracksTableCreateCompanionBuilder,
          $$CachedCloudTracksTableUpdateCompanionBuilder,
          (
            CachedCloudTrack,
            BaseReferences<
              _$AppDatabase,
              $CachedCloudTracksTable,
              CachedCloudTrack
            >,
          ),
          CachedCloudTrack,
          PrefetchHooks Function()
        > {
  $$CachedCloudTracksTableTableManager(
    _$AppDatabase db,
    $CachedCloudTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCloudTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCloudTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCloudTracksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> accountUserId = const Value.absent(),
                Value<int> listId = const Value.absent(),
                Value<String> songId = const Value.absent(),
                Value<int?> fileId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCloudTracksCompanion(
                accountUserId: accountUserId,
                listId: listId,
                songId: songId,
                fileId: fileId,
                position: position,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int accountUserId,
                required int listId,
                required String songId,
                Value<int?> fileId = const Value.absent(),
                required int position,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedCloudTracksCompanion.insert(
                accountUserId: accountUserId,
                listId: listId,
                songId: songId,
                fileId: fileId,
                position: position,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCloudTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCloudTracksTable,
      CachedCloudTrack,
      $$CachedCloudTracksTableFilterComposer,
      $$CachedCloudTracksTableOrderingComposer,
      $$CachedCloudTracksTableAnnotationComposer,
      $$CachedCloudTracksTableCreateCompanionBuilder,
      $$CachedCloudTracksTableUpdateCompanionBuilder,
      (
        CachedCloudTrack,
        BaseReferences<
          _$AppDatabase,
          $CachedCloudTracksTable,
          CachedCloudTrack
        >,
      ),
      CachedCloudTrack,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LibraryTracksTableTableManager get libraryTracks =>
      $$LibraryTracksTableTableManager(_db, _db.libraryTracks);
  $$CachedCloudPlaylistsTableTableManager get cachedCloudPlaylists =>
      $$CachedCloudPlaylistsTableTableManager(_db, _db.cachedCloudPlaylists);
  $$CachedCloudTracksTableTableManager get cachedCloudTracks =>
      $$CachedCloudTracksTableTableManager(_db, _db.cachedCloudTracks);
}
