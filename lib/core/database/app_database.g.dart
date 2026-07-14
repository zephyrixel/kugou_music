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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LibraryTracksTable libraryTracks = $LibraryTracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [libraryTracks];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LibraryTracksTableTableManager get libraryTracks =>
      $$LibraryTracksTableTableManager(_db, _db.libraryTracks);
}
