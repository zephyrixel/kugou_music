use kugou_sdk::{
    AudioQuality, KugouClient, KugouError, Pagination, PlatformProfile, PlaybackOutcome,
    PlaybackRequest, SearchRequest, Session, SongRef,
};
use serde::{Deserialize, Serialize};
use std::sync::OnceLock;
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
    pub daily_recommendation: bool,
    pub rank: bool,
    pub trending_playlists: bool,
    pub lyrics: bool,
    pub qr_auth: bool,
    pub cloud_library: bool,
}

#[derive(Debug, Clone)]
pub struct SearchSongsRequestDto {
    pub keyword: String,
    pub page: u32,
    pub page_size: u32,
}

#[derive(Debug, Clone)]
pub struct SearchPageDto {
    pub items: Vec<SongDto>,
    pub page: u32,
    pub page_size: u32,
    pub total: Option<u64>,
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
    pub hashes: AudioHashesDto,
}

#[derive(Debug, Clone)]
pub struct AudioHashesDto {
    pub standard: Option<String>,
    pub high: Option<String>,
    pub flac: Option<String>,
    pub hi_res: Option<String>,
    pub super_hash: Option<String>,
}

#[derive(Debug, Clone, Copy)]
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
        bit_rate: Option<u64>,
        duration_secs: Option<u64>,
    },
    Preview {
        url: String,
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
pub enum BridgeErrorKind {
    InvalidArgument,
    Transport,
    Upstream,
    AuthenticationRequired,
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
        daily_recommendation: true,
        rank: true,
        trending_playlists: false,
        lyrics: true,
        qr_auth: true,
        cloud_library: true,
    }
}

pub async fn search_songs(request: SearchSongsRequestDto) -> Result<SearchPageDto, BridgeError> {
    let keyword = request.keyword.trim();
    if keyword.is_empty() {
        return Err(BridgeError::invalid_argument(
            "search keyword cannot be empty",
        ));
    }

    let page = request.page.max(1);
    let page_size = request.page_size.clamp(1, 100);
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

    Ok(SearchPageDto {
        items: response.data.items.iter().map(song_to_dto).collect(),
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

    Ok(RecommendationDto {
        title: "每日推荐".to_owned(),
        subtitle: response.data.sub_title,
        artwork_url: response.data.cover_img_url,
        creation_date: response.data.creation_date,
        songs: response.data.items.iter().map(song_to_dto).collect(),
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

    Ok(match response.data.outcome() {
        PlaybackOutcome::Playable { url } => PlaybackResolutionDto::Playable {
            url,
            bit_rate,
            duration_secs,
        },
        PlaybackOutcome::Preview { url, end_ms } => PlaybackResolutionDto::Preview {
            url,
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
        PlaybackOutcome::Unavailable => PlaybackResolutionDto::Unavailable,
        _ => PlaybackResolutionDto::Unavailable,
    })
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
    if persisted.schema_version != SESSION_SCHEMA_VERSION {
        return Err(BridgeError::invalid_argument(format!(
            "unsupported session schema version {}",
            persisted.schema_version
        )));
    }
    if persisted.platform != SESSION_PLATFORM {
        return Err(BridgeError::invalid_argument(
            "only Lite profile sessions can be imported",
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

fn song_to_dto(song: &SongRef) -> SongDto {
    let primary_hash = song.primary_hash().map(str::to_ascii_lowercase);
    SongDto {
        id: stable_song_id(song.mix_song_id, primary_hash.as_deref()),
        title: song.display_name().to_owned(),
        artist: song.singer.clone(),
        album: song.album.clone(),
        duration_secs: song.duration_secs,
        artwork_url: None,
        privilege: song.privilege,
        album_id: song.album_id,
        mix_song_id: song.mix_song_id,
        hashes: AudioHashesDto {
            standard: song.resources.standard.clone(),
            high: song.resources.high.clone(),
            flac: song.resources.flac.clone(),
            hi_res: song.resources.hires.clone(),
            super_hash: song.resources.super_hash.clone(),
        },
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
            KugouError::Business { code, .. } => Self {
                kind: BridgeErrorKind::Upstream,
                message,
                code: Some(code),
                retryable: false,
            },
            KugouError::SecurityChallenge(_) => Self {
                kind: BridgeErrorKind::SecurityChallenge,
                message,
                code: None,
                retryable: false,
            },
            _ => Self::internal(message),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn capabilities_are_lite_only() {
        let capabilities = get_sdk_capabilities();
        assert_eq!(capabilities.platform, "lite");
        assert!(capabilities.song_search);
        assert!(!capabilities.trending_playlists);
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
    }
}
