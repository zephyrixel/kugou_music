use kugou_sdk::{
    AudioQuality, CollectRequest, KugouClient, KugouError, Pagination, PlatformProfile,
    PlaybackOutcome, PlaybackRequest, PlaylistEditRequest, PlaylistKind, PlaylistTrackInput,
    SearchPlaylist, SearchRequest, Session, SongRef, UserPlaylist,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::{
    collections::{BTreeMap, HashMap},
    sync::OnceLock,
};
use tokio::sync::Mutex;

const SESSION_SCHEMA_VERSION: u32 = 1;
const SESSION_PLATFORM: &str = "lite";

struct KugouRuntime {
    client: KugouClient,
    session: Mutex<Session>,
}

static RUNTIME: OnceLock<KugouRuntime> = OnceLock::new();

#[derive(Debug, Clone)]
pub struct SdkCapabilitiesDto {
    pub platform: String,
    pub song_search: bool,
    pub playlist_search: bool,
    pub daily_recommendation: bool,
    pub sms_auth: bool,
    pub cloud_library: bool,
    pub playlist_mutations: bool,
}

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

#[derive(Debug, Clone)]
pub struct RecommendationDto {
    pub title: String,
    pub subtitle: Option<String>,
    pub artwork_url: Option<String>,
    pub creation_date: Option<String>,
    pub songs: Vec<SongDto>,
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
    Denied {
        status: Option<i64>,
        fail_process: Option<i64>,
    },
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
    pub total_version: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct PlaylistTracksRequestDto {
    pub list_id: Option<u64>,
    pub global_collection_id: Option<String>,
    pub owned: bool,
    pub page: u32,
    pub page_size: u32,
}

#[derive(Debug, Clone)]
pub struct PlaylistEditInputDto {
    pub list_id: u64,
    pub name: Option<String>,
    pub private: Option<bool>,
    pub intro: Option<String>,
    pub tags: Option<String>,
    pub total_version: Option<u64>,
}

#[derive(Debug, Clone)]
pub struct PlaylistMutationDto {
    pub list_id: Option<u64>,
    pub global_collection_id: Option<String>,
    pub name: Option<String>,
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

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct PersistedSession {
    schema_version: u32,
    platform: String,
    session_json: String,
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn initialize_sdk() -> Result<SdkCapabilitiesDto, BridgeError> {
    runtime()?;
    Ok(get_sdk_capabilities())
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_sdk_capabilities() -> SdkCapabilitiesDto {
    SdkCapabilitiesDto {
        platform: SESSION_PLATFORM.to_owned(),
        song_search: true,
        playlist_search: true,
        daily_recommendation: true,
        sms_auth: true,
        cloud_library: true,
        playlist_mutations: true,
    }
}

pub async fn get_auth_state() -> Result<AuthStateDto, BridgeError> {
    let runtime = runtime()?;
    let session = runtime.session.lock().await;
    Ok(auth_state(&session))
}

pub async fn send_sms_code(mobile: String) -> Result<(), BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .auth()
        .send_sms_code(&mut session, &mobile)
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(())
}

pub async fn login_by_sms(mobile: String, code: String) -> Result<SmsLoginResultDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .auth()
        .login_by_sms(&mut session, &mobile, &code)
        .await
        .map_err(BridgeError::from_sdk)?;
    if !session.is_authenticated() {
        return Err(BridgeError::internal(
            "SMS login returned without an authenticated session",
        ));
    }
    let fingerprint_warning = runtime
        .client
        .auth()
        .register_dev(&mut session, None)
        .await
        .err()
        .map(|error| error.to_string());
    Ok(SmsLoginResultDto {
        auth: auth_state(&session),
        fingerprint_warning,
    })
}

pub async fn refresh_login() -> Result<AuthStateDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .auth()
        .refresh_token(&mut session)
        .await
        .map_err(BridgeError::from_sdk)?;
    if session.device.device_fingerprint_id.is_none() {
        let _ = runtime.client.auth().register_dev(&mut session, None).await;
    }
    Ok(auth_state(&session))
}

pub async fn register_device() -> Result<AuthStateDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .auth()
        .register_dev(&mut session, None)
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(auth_state(&session))
}

pub async fn logout() -> Result<AuthStateDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let device = session.device.clone();
    *session = Session::new(device);
    Ok(auth_state(&session))
}

pub async fn search_songs(request: SearchRequestDto) -> Result<SongPageDto, BridgeError> {
    let (keyword, page, page_size) = validated_search(&request)?;
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let response = runtime
        .client
        .search()
        .songs(
            &mut session,
            SearchRequest::new(keyword).pagination(Pagination::new(page, page_size)),
        )
        .await
        .map_err(BridgeError::from_sdk)?;
    let items =
        songs_to_dtos_with_artwork(&runtime.client, &mut session, &response.data.items).await;
    Ok(SongPageDto {
        items,
        page,
        page_size,
        total: response.data.total,
    })
}

pub async fn search_playlists(
    request: SearchRequestDto,
) -> Result<PlaylistSearchPageDto, BridgeError> {
    let (keyword, page, page_size) = validated_search(&request)?;
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let response = runtime
        .client
        .search()
        .playlists(
            &mut session,
            SearchRequest::new(keyword).pagination(Pagination::new(page, page_size)),
        )
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(PlaylistSearchPageDto {
        items: response
            .data
            .items
            .iter()
            .map(search_playlist_to_dto)
            .collect(),
        page,
        page_size,
        total: response.data.total,
    })
}

pub async fn get_everyday_recommendations() -> Result<RecommendationDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let response = runtime
        .client
        .recommend()
        .everyday(&mut session)
        .await
        .map_err(BridgeError::from_sdk)?;
    let songs =
        songs_to_dtos_with_artwork(&runtime.client, &mut session, &response.data.items).await;
    Ok(RecommendationDto {
        title: "每日推荐".to_owned(),
        subtitle: response.data.sub_title,
        artwork_url: response.data.cover_img_url,
        creation_date: response.data.creation_date,
        songs,
    })
}

pub async fn resolve_playback(
    request: ResolvePlaybackRequestDto,
) -> Result<PlaybackResolutionDto, BridgeError> {
    let runtime = runtime()?;
    let (hash, actual_quality) = select_hash(&request.song.hashes, request.quality)
        .ok_or_else(|| BridgeError::invalid_argument("song has no usable resource hash"))?;
    let mut playback = PlaybackRequest::new(hash)
        .quality(actual_quality)
        .free_preview(request.free_preview);
    if let Some(album_id) = request.song.album_id {
        playback = playback.album_id(album_id);
    }
    if let Some(mix_song_id) = request.song.mix_song_id {
        playback = playback.album_audio_id(mix_song_id);
    }
    let mut session = runtime.session.lock().await;
    let response = runtime
        .client
        .songs()
        .playback(&mut session, playback)
        .await
        .map_err(BridgeError::from_sdk)?;
    let bit_rate = response.data.bit_rate;
    let duration_secs = response.data.duration_secs;
    let artwork_url = artwork_from_extra(&response.data.extra);
    let quality = audio_quality_to_dto(actual_quality);
    Ok(match response.data.outcome() {
        PlaybackOutcome::Playable { url } => PlaybackResolutionDto::Playable {
            url,
            artwork_url,
            quality,
            bit_rate,
            duration_secs,
        },
        PlaybackOutcome::Preview { url, end_ms } => PlaybackResolutionDto::Preview {
            url,
            artwork_url,
            quality,
            end_ms,
            bit_rate,
            duration_secs,
        },
        PlaybackOutcome::Denied {
            status,
            fail_process,
        } => PlaybackResolutionDto::Denied {
            status,
            fail_process,
        },
        _ => PlaybackResolutionDto::Unavailable,
    })
}

pub async fn get_user_profile() -> Result<UserProfileDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let user_id = session.user_id;
    let value = runtime
        .client
        .users()
        .detail(&mut session)
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    Ok(UserProfileDto {
        user_id: value.userid.or(user_id),
        display_name: value.display_name().to_owned(),
        username: value.username,
        avatar_url: value.pic,
        gender: value.sex,
        birthday: value.birthday,
        city: value.city,
        province: value.province,
        signature: value.signature,
        following_count: value.fol_num,
        fan_count: value.fan_num,
        visitor_count: value.visit_total,
    })
}

pub async fn get_user_vip() -> Result<UserVipDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = runtime
        .client
        .users()
        .vip(&mut session)
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    Ok(UserVipDto {
        vip_type: value.vip_type,
        music_package_type: value.m_type,
        yearly_type: value.y_type,
        vip_end_time: value.vip_end_time,
        music_end_time: value.m_end_time,
        yearly_end_time: value.y_end_time,
        product_type: value.product_type,
    })
}

pub async fn get_cloud_history() -> Result<SongPageDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = runtime
        .client
        .users()
        .history(&mut session)
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    let items = songs_to_dtos_with_artwork(&runtime.client, &mut session, &value.items).await;
    Ok(SongPageDto {
        items,
        page: 1,
        page_size: value.items.len() as u32,
        total: value.total,
    })
}

pub async fn get_cloud_playlists(
    page: u32,
    page_size: u32,
) -> Result<CloudPlaylistPageDto, BridgeError> {
    let page = page.max(1);
    let page_size = page_size.clamp(1, 100);
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = runtime
        .client
        .users()
        .playlists(&mut session, Pagination::new(page, page_size))
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    Ok(CloudPlaylistPageDto {
        items: value.items.iter().map(cloud_playlist_to_dto).collect(),
        page,
        page_size,
        total: value.list_count,
        total_version: value.total_ver,
    })
}

pub async fn get_playlist_tracks(
    request: PlaylistTracksRequestDto,
) -> Result<SongPageDto, BridgeError> {
    let page = request.page.max(1);
    let page_size = request.page_size.clamp(1, 100);
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = if request.owned {
        let list_id = request
            .list_id
            .filter(|id| *id > 0)
            .ok_or_else(|| BridgeError::invalid_argument("owned playlist requires list_id"))?;
        runtime
            .client
            .playlists()
            .tracks_by_listid(&mut session, list_id, Pagination::new(page, page_size))
            .await
            .map_err(BridgeError::from_sdk)?
            .data
    } else {
        let gid = request
            .global_collection_id
            .as_deref()
            .filter(|value| !value.trim().is_empty())
            .ok_or_else(|| BridgeError::invalid_argument("playlist requires collection id"))?;
        runtime
            .client
            .playlists()
            .tracks(&mut session, gid, Pagination::new(page, page_size))
            .await
            .map_err(BridgeError::from_sdk)?
            .data
    };
    let items = songs_to_dtos_with_artwork(&runtime.client, &mut session, &value.items).await;
    Ok(SongPageDto {
        items,
        page,
        page_size,
        total: value.count,
    })
}

pub async fn create_cloud_playlist(
    name: String,
    private: bool,
) -> Result<PlaylistMutationDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = runtime
        .client
        .playlists()
        .create(&mut session, &name, private)
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    Ok(PlaylistMutationDto {
        list_id: value.list_id,
        global_collection_id: value.global_collection_id,
        name: value.name,
    })
}

pub async fn collect_cloud_playlist(
    global_collection_id: String,
    owner_user_id: Option<u64>,
    name: Option<String>,
) -> Result<PlaylistMutationDto, BridgeError> {
    let mut request = CollectRequest::from_gid(global_collection_id);
    if let Some(owner) = owner_user_id {
        request = request.owner(owner);
    }
    if let Some(name) = name {
        request = request.name(name);
    }
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = runtime
        .client
        .playlists()
        .collect(&mut session, request)
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    Ok(PlaylistMutationDto {
        list_id: value.list_id,
        global_collection_id: value.global_collection_id,
        name: value.name,
    })
}

pub async fn delete_cloud_playlist(list_id: u64, collected: bool) -> Result<(), BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .playlists()
        .delete(
            &mut session,
            list_id,
            if collected {
                PlaylistKind::Collected
            } else {
                PlaylistKind::Created
            },
        )
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(())
}

pub async fn edit_cloud_playlist(input: PlaylistEditInputDto) -> Result<(), BridgeError> {
    let mut request = PlaylistEditRequest::new();
    if let Some(name) = input.name {
        request = request.name(name);
    }
    if let Some(private) = input.private {
        request = request.private(private);
    }
    if let Some(intro) = input.intro {
        request = request.intro(intro);
    }
    if let Some(tags) = input.tags {
        request = request.tags(tags);
    }
    if let Some(version) = input.total_version {
        request = request.total_ver(version);
    }
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .playlists()
        .modify(&mut session, input.list_id, request)
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(())
}

pub async fn add_song_to_playlist(list_id: u64, song: SongDto) -> Result<(), BridgeError> {
    let hash = song
        .hashes
        .standard
        .clone()
        .or(song.hashes.high.clone())
        .or(song.hashes.flac.clone())
        .ok_or_else(|| BridgeError::invalid_argument("song has no hash for playlist write"))?;
    let mut track = PlaylistTrackInput::new(song.title, hash);
    if let Some(value) = song.album_id {
        track = track.album_id(value);
    }
    if let Some(value) = song.mix_song_id {
        track = track.mix_song_id(value);
    }
    if let Some(value) = song.duration_secs {
        track = track.duration_secs(value);
    }
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .playlists()
        .add_tracks(&mut session, list_id, [track])
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(())
}

pub async fn remove_song_from_playlist(list_id: u64, file_id: u64) -> Result<(), BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .playlists()
        .remove_tracks(&mut session, list_id, [file_id])
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(())
}

pub async fn export_session() -> Result<String, BridgeError> {
    let runtime = runtime()?;
    let session = runtime.session.lock().await;
    let session_json = session.export().map_err(BridgeError::from_sdk)?;
    serde_json::to_string(&PersistedSession {
        schema_version: SESSION_SCHEMA_VERSION,
        platform: SESSION_PLATFORM.to_owned(),
        session_json,
    })
    .map_err(|error| BridgeError::internal(error.to_string()))
}

pub async fn import_session(value: String) -> Result<(), BridgeError> {
    let persisted: PersistedSession = serde_json::from_str(&value)
        .map_err(|error| BridgeError::invalid_argument(error.to_string()))?;
    if persisted.schema_version != SESSION_SCHEMA_VERSION || persisted.platform != SESSION_PLATFORM
    {
        return Err(BridgeError::invalid_argument(
            "only schema v1 Lite sessions can be imported",
        ));
    }
    let restored = Session::import(&persisted.session_json).map_err(BridgeError::from_sdk)?;
    let runtime = runtime()?;
    *runtime.session.lock().await = restored;
    Ok(())
}

fn runtime() -> Result<&'static KugouRuntime, BridgeError> {
    if let Some(runtime) = RUNTIME.get() {
        return Ok(runtime);
    }
    let client = KugouClient::builder()
        .platform(PlatformProfile::Lite)
        .build()
        .map_err(BridgeError::from_sdk)?;
    let _ = RUNTIME.set(KugouRuntime {
        client,
        session: Mutex::new(Session::random()),
    });
    RUNTIME
        .get()
        .ok_or_else(|| BridgeError::internal("failed to initialize Lite SDK runtime"))
}

fn auth_state(session: &Session) -> AuthStateDto {
    AuthStateDto {
        authenticated: session.is_authenticated(),
        user_id: session.user_id,
        vip_type: session.vip_type,
        fingerprint_registered: session
            .device
            .device_fingerprint_id
            .as_deref()
            .is_some_and(|value| !value.is_empty() && value != "-"),
    }
}

fn validated_search(request: &SearchRequestDto) -> Result<(&str, u32, u32), BridgeError> {
    let keyword = request.keyword.trim();
    if keyword.is_empty() {
        return Err(BridgeError::invalid_argument(
            "search keyword cannot be empty",
        ));
    }
    Ok((
        keyword,
        request.page.max(1),
        request.page_size.clamp(1, 100),
    ))
}

#[derive(Debug, Clone, Default)]
#[flutter_rust_bridge::frb(ignore)]
struct SongDetailEnrichment {
    artwork_url: Option<String>,
    hashes: AudioHashesDto,
}

fn song_to_dto_with_enrichment(
    song: &SongRef,
    enrichment: Option<&SongDetailEnrichment>,
) -> SongDto {
    let primary_hash = song.primary_hash().map(str::to_ascii_lowercase);
    let detail_hashes = enrichment.map(|value| &value.hashes);
    SongDto {
        id: stable_song_id(song.mix_song_id, primary_hash.as_deref()),
        title: song.display_name().to_owned(),
        artist: song.singer.clone(),
        album: song.album.clone(),
        duration_secs: song.duration_secs,
        artwork_url: artwork_from_extra(&song.extra)
            .or_else(|| enrichment.and_then(|value| value.artwork_url.clone())),
        privilege: song.privilege,
        album_id: song.album_id,
        mix_song_id: song.mix_song_id,
        file_id: song.file_id,
        hashes: AudioHashesDto {
            standard: song
                .resources
                .standard
                .clone()
                .or_else(|| detail_hashes.and_then(|hashes| hashes.standard.clone())),
            high: song
                .resources
                .high
                .clone()
                .or_else(|| detail_hashes.and_then(|hashes| hashes.high.clone())),
            flac: song
                .resources
                .flac
                .clone()
                .or_else(|| detail_hashes.and_then(|hashes| hashes.flac.clone())),
            hi_res: song
                .resources
                .hires
                .clone()
                .or_else(|| detail_hashes.and_then(|hashes| hashes.hi_res.clone())),
            super_hash: song
                .resources
                .super_hash
                .clone()
                .or_else(|| detail_hashes.and_then(|hashes| hashes.super_hash.clone())),
        },
    }
}

async fn songs_to_dtos_with_artwork(
    client: &KugouClient,
    session: &mut Session,
    songs: &[SongRef],
) -> Vec<SongDto> {
    let mut enrichment_by_mix_id = HashMap::new();
    let mut mix_ids = Vec::new();

    for song in songs {
        let Some(mix_id) = song.mix_song_id else {
            continue;
        };
        if !mix_ids.contains(&mix_id) {
            mix_ids.push(mix_id);
        }
    }

    // Cover art and higher-quality hashes are optional metadata. Enrich in
    // bounded batches, but never make the base song list fail with details.
    for chunk in mix_ids.chunks(40) {
        if let Ok(response) = client.songs().details_by_mix_ids_raw(session, chunk).await {
            collect_detail_enrichment(&response.data, &mut enrichment_by_mix_id);
        }
    }

    songs
        .iter()
        .map(|song| {
            let enrichment = song
                .mix_song_id
                .and_then(|id| enrichment_by_mix_id.get(&id));
            song_to_dto_with_enrichment(song, enrichment)
        })
        .collect()
}

fn artwork_from_extra(extra: &BTreeMap<String, Value>) -> Option<String> {
    artwork_from_object(extra.iter().map(|(key, value)| (key.as_str(), value)))
}

fn artwork_from_value(value: &Value) -> Option<String> {
    match value {
        Value::String(value) => nonempty_artwork(value),
        Value::Array(values) => values.iter().find_map(artwork_from_value),
        Value::Object(values) => {
            artwork_from_object(values.iter().map(|(key, value)| (key.as_str(), value)))
        }
        _ => None,
    }
}

fn artwork_from_object<'a>(
    entries: impl Iterator<Item = (&'a str, &'a Value)> + Clone,
) -> Option<String> {
    const ARTWORK_KEYS: &[&str] = &[
        "sizable_cover",
        "union_cover",
        "cover_url",
        "album_cover",
        "album_img",
        "album_image",
        "imgurl",
        "img_url",
        "Image",
        "image",
        "cover",
        "pic_url",
        "pic",
        "img",
    ];
    const CONTAINER_KEYS: &[&str] = &["album_info", "albuminfo", "base", "trans_param", "extra"];

    for key in ARTWORK_KEYS {
        if let Some(value) = entries
            .clone()
            .find_map(|(name, value)| artwork_key_matches(name, key).then_some(value))
            && let Some(artwork) = artwork_from_value(value)
        {
            return Some(artwork);
        }
    }
    for key in CONTAINER_KEYS {
        if let Some(value) = entries
            .clone()
            .find_map(|(name, value)| artwork_key_matches(name, key).then_some(value))
            && let Some(artwork) = artwork_from_value(value)
        {
            return Some(artwork);
        }
    }
    None
}

fn artwork_key_matches(left: &str, right: &str) -> bool {
    left.bytes()
        .filter(|byte| byte.is_ascii_alphanumeric())
        .map(|byte| byte.to_ascii_lowercase())
        .eq(right
            .bytes()
            .filter(|byte| byte.is_ascii_alphanumeric())
            .map(|byte| byte.to_ascii_lowercase()))
}

fn nonempty_artwork(value: &str) -> Option<String> {
    let value = value.trim();
    (!value.is_empty() && value != "-").then(|| value.to_owned())
}

fn collect_detail_enrichment(value: &Value, output: &mut HashMap<u64, SongDetailEnrichment>) {
    match value {
        Value::Array(items) => {
            for item in items {
                collect_detail_enrichment(item, output);
            }
        }
        Value::Object(object) => {
            let mix_id = value_u64_for_keys(value, &["album_audio_id", "MixSongID", "mixsongid"])
                .or_else(|| {
                    object.get("base").and_then(|base| {
                        value_u64_for_keys(
                            base,
                            &["album_audio_id", "MixSongID", "mixsongid", "ID"],
                        )
                    })
                });
            if let Some(mix_id) = mix_id {
                output.insert(
                    mix_id,
                    SongDetailEnrichment {
                        artwork_url: artwork_from_value(value),
                        hashes: audio_hashes_from_detail(value),
                    },
                );
            }
            for key in ["data", "items", "info", "list", "lists"] {
                if let Some(nested) = object.get(key) {
                    collect_detail_enrichment(nested, output);
                }
            }
        }
        _ => {}
    }
}

fn audio_hashes_from_detail(value: &Value) -> AudioHashesDto {
    let audio_info = value
        .as_object()
        .and_then(|object| object_value_for_key(object, "audio_info"));
    let find = |keys: &[&str]| {
        string_for_keys(value, keys)
            .or_else(|| audio_info.and_then(|audio_info| string_for_keys(audio_info, keys)))
    };
    AudioHashesDto {
        standard: find(&["FileHash", "filehash", "hash", "hash_128"]),
        high: find(&["HQFileHash", "hq_hash", "hash_320", "320hash"]),
        flac: find(&["SQFileHash", "sq_hash", "hash_flac", "sqhash"]),
        hi_res: find(&["ResFileHash", "hash_high", "hash_hires"]),
        super_hash: find(&["SuperFileHash", "super_hash", "hash_super"]),
    }
}

fn object_value_for_key<'a>(
    object: &'a serde_json::Map<String, Value>,
    key: &str,
) -> Option<&'a Value> {
    object
        .iter()
        .find_map(|(name, value)| artwork_key_matches(name, key).then_some(value))
}

fn string_for_keys(value: &Value, keys: &[&str]) -> Option<String> {
    let object = value.as_object()?;
    keys.iter().find_map(|key| {
        object.iter().find_map(|(name, value)| {
            if !artwork_key_matches(name, key) {
                return None;
            }
            value
                .as_str()
                .map(str::trim)
                .filter(|value| !value.is_empty() && *value != "-")
                .map(str::to_owned)
        })
    })
}

fn value_u64_for_keys(value: &Value, keys: &[&str]) -> Option<u64> {
    let object = value.as_object()?;
    keys.iter().find_map(|key| {
        let value = object.get(*key)?;
        value
            .as_u64()
            .or_else(|| value.as_str()?.trim().parse().ok())
            .filter(|value| *value > 0)
    })
}

fn search_playlist_to_dto(value: &SearchPlaylist) -> PlaylistSearchHitDto {
    PlaylistSearchHitDto {
        special_id: value.special_id,
        global_collection_id: value.global_collection_id.clone(),
        name: value.display_name().to_owned(),
        intro: value.intro.clone(),
        artwork_url: value.img.clone(),
        song_count: value.song_count,
        play_count: value.play_count,
        collect_count: value.collect_count,
        creator_name: value.nickname.clone(),
        creator_user_id: value.user_id,
        tags: value.tags.clone(),
    }
}

fn cloud_playlist_to_dto(value: &UserPlaylist) -> CloudPlaylistDto {
    CloudPlaylistDto {
        list_id: value.list_id,
        global_collection_id: value.global_collection_id.clone(),
        name: value
            .name
            .clone()
            .unwrap_or_else(|| "未命名歌单".to_owned()),
        intro: value.intro.clone(),
        artwork_url: value.pic.clone(),
        count: value.count,
        list_type: value.list_type,
        creator_user_id: value.create_userid,
        creator_name: value.create_username.clone(),
        is_private: value.is_pri == Some(1),
        is_my_favorite: value.is_my_fav(),
        is_default_collect: value.is_default_collect(),
        tags: value.tags.clone(),
    }
}

fn stable_song_id(mix_song_id: Option<u64>, primary_hash: Option<&str>) -> String {
    if let Some(id) = mix_song_id {
        format!("mix:{id}")
    } else if let Some(hash) = primary_hash.filter(|value| !value.is_empty()) {
        format!("hash:{}", hash.to_ascii_lowercase())
    } else {
        "unknown".to_owned()
    }
}

fn select_hash(
    hashes: &AudioHashesDto,
    quality: AudioQualityDto,
) -> Option<(String, AudioQuality)> {
    let candidates: &[(Option<&String>, AudioQuality)] = match quality {
        AudioQualityDto::Standard => &[(hashes.standard.as_ref(), AudioQuality::Standard)],
        AudioQualityDto::High => &[
            (hashes.high.as_ref(), AudioQuality::High),
            (hashes.standard.as_ref(), AudioQuality::Standard),
        ],
        AudioQualityDto::Flac => &[
            (hashes.flac.as_ref(), AudioQuality::Flac),
            (hashes.high.as_ref(), AudioQuality::High),
            (hashes.standard.as_ref(), AudioQuality::Standard),
        ],
        AudioQualityDto::HiRes => &[
            (hashes.hi_res.as_ref(), AudioQuality::HiRes),
            (hashes.flac.as_ref(), AudioQuality::Flac),
            (hashes.high.as_ref(), AudioQuality::High),
            (hashes.standard.as_ref(), AudioQuality::Standard),
        ],
        AudioQualityDto::Super => &[
            (hashes.super_hash.as_ref(), AudioQuality::Super),
            (hashes.hi_res.as_ref(), AudioQuality::HiRes),
            (hashes.flac.as_ref(), AudioQuality::Flac),
            (hashes.high.as_ref(), AudioQuality::High),
            (hashes.standard.as_ref(), AudioQuality::Standard),
        ],
    };
    candidates.iter().find_map(|(hash, actual_quality)| {
        hash.filter(|value| !value.trim().is_empty())
            .map(|value| ((*value).clone(), *actual_quality))
    })
}

fn audio_quality_to_dto(quality: AudioQuality) -> AudioQualityDto {
    match quality {
        AudioQuality::Standard => AudioQualityDto::Standard,
        AudioQuality::High => AudioQualityDto::High,
        AudioQuality::Flac => AudioQualityDto::Flac,
        AudioQuality::HiRes => AudioQualityDto::HiRes,
        AudioQuality::Super => AudioQualityDto::Super,
        _ => AudioQualityDto::Standard,
    }
}

impl BridgeError {
    fn invalid_argument(message: impl Into<String>) -> Self {
        Self {
            kind: BridgeErrorKind::InvalidArgument,
            message: message.into(),
            code: None,
            retryable: false,
        }
    }

    fn internal(message: impl Into<String>) -> Self {
        Self {
            kind: BridgeErrorKind::Internal,
            message: message.into(),
            code: None,
            retryable: false,
        }
    }

    fn from_sdk(error: KugouError) -> Self {
        let message = error.to_string();
        match error {
            KugouError::InvalidArgument(_) => Self::invalid_argument(message),
            KugouError::AuthenticationRequired => Self {
                kind: BridgeErrorKind::AuthenticationRequired,
                message,
                code: None,
                retryable: false,
            },
            KugouError::Transport(_) => Self {
                kind: BridgeErrorKind::Transport,
                message,
                code: None,
                retryable: true,
            },
            KugouError::Http { status: 404, .. } => Self {
                kind: BridgeErrorKind::Unsupported,
                message,
                code: Some(404),
                retryable: false,
            },
            KugouError::Http { status, .. } => Self {
                kind: BridgeErrorKind::Upstream,
                message,
                code: Some(i64::from(status)),
                retryable: status >= 500,
            },
            KugouError::Business { code, .. } if code == 20017 || code == 20018 => Self {
                kind: BridgeErrorKind::AuthenticationExpired,
                message,
                code: Some(code),
                retryable: false,
            },
            KugouError::Business { code, .. } => Self {
                kind: BridgeErrorKind::Upstream,
                message,
                code: Some(code),
                retryable: false,
            },
            KugouError::SecurityChallenge(challenge) => Self {
                kind: BridgeErrorKind::SecurityChallenge,
                message,
                code: challenge.code.parse().ok(),
                retryable: true,
            },
            _ => Self::internal(message),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn capabilities_are_lite_and_authenticated_features_are_exposed() {
        let capabilities = get_sdk_capabilities();
        assert_eq!(capabilities.platform, "lite");
        assert!(capabilities.sms_auth);
        assert!(capabilities.playlist_mutations);
    }

    #[test]
    fn stable_id_prefers_mix_id() {
        assert_eq!(stable_song_id(Some(42), Some("ABC")), "mix:42");
        assert_eq!(stable_song_id(None, Some("ABC")), "hash:abc");
    }

    #[test]
    fn quality_falls_back_with_matching_label() {
        let hashes = AudioHashesDto {
            standard: Some("STD".into()),
            high: None,
            flac: None,
            hi_res: None,
            super_hash: None,
        };
        let selected = select_hash(&hashes, AudioQualityDto::Flac).unwrap();
        assert_eq!(selected.0, "STD");
        assert_eq!(selected.1, AudioQuality::Standard);
        assert_eq!(audio_quality_to_dto(selected.1), AudioQualityDto::Standard);
    }

    #[test]
    fn artwork_is_read_from_song_extra() {
        let mut extra = BTreeMap::new();
        extra.insert(
            "sizableCover".to_owned(),
            Value::String("https://img.kugou.com/{size}/cover.jpg".to_owned()),
        );
        assert_eq!(
            artwork_from_extra(&extra).as_deref(),
            Some("https://img.kugou.com/{size}/cover.jpg")
        );
    }

    #[test]
    fn detail_artwork_and_quality_hashes_are_mapped_by_mix_song_id() {
        let detail = serde_json::json!({
            "data": [{
                "base": {"album_audio_id": 32155307},
                "audio_info": {
                    "hash": "STD",
                    "hash_320": "HQ",
                    "hash_flac": "FLAC",
                    "hash_high": "HIRES"
                },
                "album_info": {
                    "sizable_cover": "//imge.kugou.com/stdmusic/{size}/cover.jpg"
                }
            }]
        });
        let mut result = HashMap::new();
        collect_detail_enrichment(&detail, &mut result);
        let enrichment = result.get(&32155307).unwrap();
        assert_eq!(
            enrichment.artwork_url.as_deref(),
            Some("//imge.kugou.com/stdmusic/{size}/cover.jpg")
        );
        assert_eq!(enrichment.hashes.standard.as_deref(), Some("STD"));
        assert_eq!(enrichment.hashes.high.as_deref(), Some("HQ"));
        assert_eq!(enrichment.hashes.flac.as_deref(), Some("FLAC"));
        assert_eq!(enrichment.hashes.hi_res.as_deref(), Some("HIRES"));
    }
}
