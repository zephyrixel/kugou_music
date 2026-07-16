#[derive(Debug, Clone)]
pub struct AuthStateDto {
    pub authenticated: bool,
    pub user_id: Option<u64>,
    pub vip_type: Option<u32>,
    pub fingerprint_registered: bool,
}

#[derive(Debug, Clone)]
pub struct SmsLoginResultDto {
    pub auth: AuthStateDto,
    pub fingerprint_warning: Option<String>,
}

#[derive(Debug, Clone)]
pub struct SearchRequestDto {
    pub keyword: String,
    pub page: u32,
    pub page_size: u32,
}

#[derive(Debug, Clone)]
pub struct SongPageDto {
    pub items: Vec<SongDto>,
    pub page: u32,
    pub page_size: u32,
    pub total: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct HistorySongDto {
    pub song: SongDto,
    pub played_at_secs: Option<u64>,
    pub play_count: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct HistoryPageDto {
    pub items: Vec<HistorySongDto>,
    pub cursor: Option<String>,
    pub has_more: bool,
    pub total: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct HistoryUploadItemDto {
    pub mix_song_id: u64,
    pub played_at_secs: u64,
    pub play_count: u64,
}

#[derive(Debug, Clone)]
pub struct PlaylistSearchPageDto {
    pub items: Vec<PlaylistSearchHitDto>,
    pub page: u32,
    pub page_size: u32,
    pub total: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct PlaylistSearchHitDto {
    pub special_id: Option<u64>,
    pub global_collection_id: Option<String>,
    pub name: String,
    pub intro: Option<String>,
    pub artwork_url: Option<String>,
    pub song_count: Option<u64>,
    pub play_count: Option<u64>,
    pub collect_count: Option<u64>,
    pub creator_name: Option<String>,
    pub creator_user_id: Option<u64>,
    pub tags: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PersonalFmActionDto {
    Play,
    Skip,
    Garbage,
}

#[derive(Debug, Clone)]
pub struct PersonalFmRequestDto {
    pub action: PersonalFmActionDto,
    pub current_song: Option<SongDto>,
    pub remain_song_count: u32,
    pub playtime_secs: Option<u64>,
    pub mark_list: Option<String>,
    pub current_mark: Option<String>,
}

#[derive(Debug, Clone)]
pub struct HeartRadioRequestDto {
    pub current_mix_song_ids: Vec<u64>,
}

#[derive(Debug, Clone)]
pub struct RecommendationBatchDto {
    pub title: String,
    pub subtitle: Option<String>,
    pub mark_list: Option<String>,
    pub mark: Option<String>,
    pub songs: Vec<SongDto>,
}

#[derive(Debug, Clone)]
pub struct RecommendationReportAckDto {
    pub sync_point: Option<i64>,
    pub is_clean: Option<bool>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RecommendationHistoryActionDto {
    Play,
    Collect,
    Trash,
}

#[derive(Debug, Clone)]
pub struct RecommendationHistoryItemDto {
    pub action: RecommendationHistoryActionDto,
    pub song: SongDto,
}

#[derive(Debug, Clone)]
pub struct SongDto {
    pub id: String,
    pub title: String,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub duration_secs: Option<u64>,
    pub artwork_url: Option<String>,
    pub privilege: Option<i64>,
    pub album_id: Option<u64>,
    pub mix_song_id: Option<u64>,
    pub file_id: Option<u64>,
    pub hashes: AudioHashesDto,
}

#[derive(Debug, Clone, Default)]
pub struct AudioHashesDto {
    pub standard: Option<String>,
    pub high: Option<String>,
    pub flac: Option<String>,
    pub hi_res: Option<String>,
    pub super_hash: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AudioQualityDto {
    Standard,
    High,
    Flac,
    HiRes,
    Super,
}

#[derive(Debug, Clone)]
pub struct ResolvePlaybackRequestDto {
    pub song: SongDto,
    pub quality: AudioQualityDto,
    pub free_preview: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LyricFormatDto {
    Krc,
    Lrc,
    Plain,
}

#[derive(Debug, Clone)]
pub struct LyricWordDto {
    pub start_ms: u64,
    pub duration_ms: u64,
    pub text: String,
}

#[derive(Debug, Clone)]
pub struct LyricLineDto {
    pub start_ms: u64,
    pub duration_ms: u64,
    pub text: String,
    pub words: Vec<LyricWordDto>,
    pub translation: Option<String>,
    pub transliteration: Option<String>,
}

#[derive(Debug, Clone)]
pub struct LyricDocumentDto {
    pub format: LyricFormatDto,
    pub offset_ms: i64,
    pub lines: Vec<LyricLineDto>,
}

#[derive(Debug, Clone)]
pub enum LyricFetchDto {
    Found { document: LyricDocumentDto },
    NotFound,
}

#[derive(Debug, Clone)]
pub enum PlaybackResolutionDto {
    Playable {
        url: String,
        artwork_url: Option<String>,
        quality: AudioQualityDto,
        bit_rate: Option<u64>,
        duration_secs: Option<u64>,
    },
    Preview {
        url: String,
        artwork_url: Option<String>,
        quality: AudioQualityDto,
        end_ms: Option<u64>,
        bit_rate: Option<u64>,
        duration_secs: Option<u64>,
    },
    Denied,
    Unavailable,
}

#[derive(Debug, Clone)]
pub struct UserProfileDto {
    pub user_id: Option<u64>,
    pub display_name: String,
    pub username: Option<String>,
    pub avatar_url: Option<String>,
    pub gender: Option<i64>,
    pub birthday: Option<String>,
    pub city: Option<String>,
    pub province: Option<String>,
    pub signature: Option<String>,
    pub following_count: Option<u64>,
    pub fan_count: Option<u64>,
    pub visitor_count: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct UserVipDto {
    pub vip_type: Option<i64>,
    pub music_package_type: Option<i64>,
    pub yearly_type: Option<i64>,
    pub vip_end_time: Option<String>,
    pub music_end_time: Option<String>,
    pub yearly_end_time: Option<String>,
    pub product_type: Option<String>,
    pub business_type: Option<String>,
    pub products: Vec<VipProductDto>,
}

#[derive(Debug, Clone)]
pub struct VipProductDto {
    pub product_type: Option<String>,
    pub business_type: Option<String>,
    pub active: bool,
    pub paid: bool,
    pub yearly: bool,
    pub vip_end_time: Option<String>,
    pub paid_expire_time: Option<String>,
}

#[derive(Debug, Clone)]
pub struct VipClaimResultDto {
    pub granted_units: Option<i64>,
    pub end_time: Option<String>,
    pub server_time_secs: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct VipUpgradeResultDto {
    pub status_code: Option<i64>,
    pub message: Option<String>,
    pub end_time: Option<String>,
}

#[derive(Debug, Clone)]
pub struct VipMonthRecordDto {
    pub claimed_days: Option<u64>,
    pub claim_dates: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct CloudPlaylistDto {
    pub list_id: Option<u64>,
    pub global_collection_id: Option<String>,
    pub name: String,
    pub intro: Option<String>,
    pub artwork_url: Option<String>,
    pub count: Option<u64>,
    pub list_type: Option<u32>,
    pub creator_user_id: Option<u64>,
    pub creator_name: Option<String>,
    pub is_private: bool,
    pub is_my_favorite: bool,
    pub is_default_collect: bool,
    pub tags: Option<String>,
}

#[derive(Debug, Clone)]
pub struct CloudPlaylistPageDto {
    pub items: Vec<CloudPlaylistDto>,
    pub page: u32,
    pub page_size: u32,
    pub total: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct PlaylistEditInputDto {
    pub list_id: u64,
    pub name: Option<String>,
    pub private: Option<bool>,
    pub intro: Option<String>,
    pub tags: Option<String>,
}

#[derive(Debug, Clone)]
pub struct PlaylistMutationDto {
    pub list_id: u64,
    pub global_collection_id: Option<String>,
}

#[derive(Debug, Clone)]
pub struct PlaylistTracksMutationDto {
    pub file_ids: Vec<u64>,
}

#[derive(Debug, Clone)]
pub enum BridgeErrorKind {
    InvalidArgument,
    Transport,
    Upstream,
    AuthenticationRequired,
    AuthenticationExpired,
    SecurityChallenge,
    Unsupported,
    Internal,
}

#[derive(Debug, Clone, thiserror::Error)]
#[error("{message}")]
pub struct BridgeError {
    pub kind: BridgeErrorKind,
    pub message: String,
    pub code: Option<i64>,
    pub retryable: bool,
}
