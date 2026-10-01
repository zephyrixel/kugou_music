import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/discovery_card.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk_models.dart';
import 'package:kgmusic/core/models/playback.dart';
import 'package:kgmusic/core/models/search_page.dart';

abstract interface class AuthSdk {
  Future<void> initialize();
  Future<AuthSnapshot> authState();
  Future<void> sendSmsCode(String mobile);
  Future<AuthSnapshot> loginBySms(String mobile, String code);
  Future<AuthSnapshot> refreshLogin();
  Future<AuthSnapshot> ensureDeviceRegistered();
  Future<AuthSnapshot> registerDevice();
  Future<void> logout();
}

abstract interface class BrowseSdk {
  Future<List<Song>> everydayRecommendations();
  Future<DiscoveryCard> discoveryCard(int cardId, {int pageSize = 10});
  Future<SearchPage> search(String keyword, {int page = 1, int pageSize = 30});
  Future<PlaylistSearchPage> searchPlaylists(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  });
  Future<UserProfile> userProfile();
  Future<UserVip> userVip();
  Future<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int page = 1,
    int pageSize = 50,
  });
}

abstract interface class RecommendationSdk {
  Future<RecommendationBatch> personalFm(PersonalFmInput input);
  Future<RecommendationBatch> heartRadio({
    List<int> currentMixSongIds = const [],
  });
  Future<RecommendationReportAck> reportRecommendationHistory(
    List<RecommendationProfileItem> items, {
    required bool complete,
    required int previousSyncPoint,
    required int nextSyncPoint,
    String? lastUploadHash,
  });
  Future<void> reportRecommendationRepeated(
    List<String> hashes, {
    required int remainSongCount,
  });
  Future<void> reportRecommendationFavoriteClick(Song song);
}

abstract interface class PlaybackSdk {
  Future<PlaybackResolution> resolve(
    Song song, {
    AudioQuality quality = AudioQuality.standard,
    bool freePreview = false,
  });
}

abstract interface class PlayerSdk implements AuthSdk, PlaybackSdk {}

abstract interface class MembershipSdk {
  Future<UserVip> userVip();
  Future<VipClaimResult> claimDayVip();
  Future<VipUpgradeResult> upgradeDayVip();
  Future<VipMonthRecord> monthVipRecord();
}

abstract interface class LibrarySdk {
  Future<HistoryPage> cloudHistory({String? cursor});
  Future<void> uploadHistory(List<HistoryUpload> items);
  Future<PlaylistPage> cloudPlaylists({int page = 1, int pageSize = 50});
  Future<SearchPage> playlistTracks(
    Playlist playlist, {
    int page = 1,
    int pageSize = 50,
  });
  Future<SearchPage> playlistTracksByListId(
    int listId, {
    int page = 1,
    int pageSize = 50,
  });
  Future<PlaylistMutation> createPlaylist(String name, {required bool private});
  Future<PlaylistMutation> collectPlaylist(PlaylistSearchHit playlist);
  Future<void> deletePlaylist({required int listId, required bool collected});
  Future<void> editPlaylist(PlaylistEditInput input);
  Future<PlaylistTracksMutation> addSongToPlaylist(int listId, Song song);
  Future<void> removeSongFromPlaylist(int listId, int fileId);
}

abstract interface class MusicSdk
    implements
        PlayerSdk,
        BrowseSdk,
        RecommendationSdk,
        MembershipSdk,
        LibrarySdk {}
