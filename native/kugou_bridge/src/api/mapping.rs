use kugou_sdk::{
    AudioQuality, ClientPlaylistItem, KugouClient, LyricDocument, LyricFormat, ResourceHashes,
    SearchPlaylist, Session, SongRef, UserPlaylist, client_playlist_week_bucket,
};
use serde_json::Value;
use std::collections::{BTreeMap, HashMap, HashSet};

use super::dto::*;

pub(super) fn song_to_dto(song: &SongRef) -> SongDto {
    song_to_dto_with_detail(song, None)
}

pub(super) fn song_to_dto_with_detail(song: &SongRef, detail: Option<&SongRef>) -> SongDto {
    let primary_hash = song.primary_hash().map(str::to_ascii_lowercase);
    let detail_hashes = detail.map(|value| &value.resources);
    SongDto {
        id: stable_song_id(song.mix_song_id, primary_hash.as_deref()),
        title: song.display_name().to_owned(),
        artist: song.singer.clone(),
        album: song.album.clone(),
        duration_secs: song.duration_secs,
        artwork_url: detail
            .and_then(|value| value.artwork_url.clone())
            .or_else(|| song.artwork_url.clone()),
        privilege: song.privilege,
        album_id: song.album_id,
        mix_song_id: song.mix_song_id,
        file_id: song.file_id,
        collect_time_secs: song.collect_time,
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
                .or_else(|| detail_hashes.and_then(|hashes| hashes.hires.clone())),
            super_hash: song
                .resources
                .super_hash
                .clone()
                .or_else(|| detail_hashes.and_then(|hashes| hashes.super_hash.clone())),
        },
    }
}

pub(super) fn song_dto_to_lyric_ref(song: &SongDto) -> SongRef {
    let mut result = song_dto_to_song_ref(song);
    result.resources.high = None;
    result.resources.flac = None;
    result.resources.hires = None;
    result.resources.super_hash = None;
    result
}

pub(super) fn song_dto_to_song_ref(song: &SongDto) -> SongRef {
    let mut resources = ResourceHashes::default();
    resources.standard = song.hashes.standard.clone();
    resources.high = song.hashes.high.clone();
    resources.flac = song.hashes.flac.clone();
    resources.hires = song.hashes.hi_res.clone();
    resources.super_hash = song.hashes.super_hash.clone();
    let mut result = SongRef::default();
    result.name = Some(song.title.clone());
    result.album = song.album.clone();
    result.singer = song.artist.clone();
    result.resources = resources;
    result.mix_song_id = song.mix_song_id;
    result.album_id = song.album_id;
    result.duration_secs = song.duration_secs;
    result.artwork_url = song.artwork_url.clone();
    result.privilege = song.privilege;
    result.file_id = song.file_id;
    result.collect_time = song.collect_time_secs;
    result
}

pub(super) fn recommendation_profile_item_to_sdk(
    item: &RecommendationProfileItemDto,
) -> ClientPlaylistItem {
    ClientPlaylistItem {
        action: match item.action {
            RecommendationProfileActionDto::Collect => ClientPlaylistItem::ACTION_COLLECT,
            RecommendationProfileActionDto::PlayComplete => ClientPlaylistItem::ACTION_PLAY,
            RecommendationProfileActionDto::PlayShort => ClientPlaylistItem::ACTION_PLAY_SHORT,
            RecommendationProfileActionDto::Trash => ClientPlaylistItem::ACTION_TRASH,
        },
        hash: item.standard_hash.clone(),
        mix_song_id: item.mix_song_id,
        time: Some(client_playlist_week_bucket(item.event_time_ms)),
        count: Some(item.count.min(i32::MAX as u32) as i32),
        flag: (item.flag_bits != 0).then_some(item.flag_bits.min(i32::MAX as u32) as i32),
        source: (item.source_bits != 0).then_some(item.source_bits.min(i32::MAX as u32) as i32),
    }
}

pub(super) fn recommendation_report_ack_to_dto(
    result: &kugou_sdk::RecommendReportResult,
) -> RecommendationReportAckDto {
    RecommendationReportAckDto {
        sync_point: result.sync_point,
        is_clean: result.is_clean,
    }
}

pub(super) fn lyric_document_to_dto(document: LyricDocument) -> LyricDocumentDto {
    LyricDocumentDto {
        format: match document.format {
            LyricFormat::Krc => LyricFormatDto::Krc,
            LyricFormat::Lrc => LyricFormatDto::Lrc,
            LyricFormat::Plain => LyricFormatDto::Plain,
            _ => LyricFormatDto::Plain,
        },
        offset_ms: document.offset_ms,
        lines: document
            .lines
            .into_iter()
            .map(|line| LyricLineDto {
                start_ms: line.start_ms,
                duration_ms: line.duration_ms,
                text: line.text,
                words: line
                    .words
                    .into_iter()
                    .map(|word| LyricWordDto {
                        start_ms: word.start_ms,
                        duration_ms: word.duration_ms,
                        text: word.text,
                    })
                    .collect(),
                translation: line.translation,
                transliteration: line.transliteration,
            })
            .collect(),
    }
}

pub(super) async fn songs_to_dtos_with_details(
    client: &KugouClient,
    session: &mut Session,
    songs: &[SongRef],
) -> Vec<SongDto> {
    let mut details_by_mix_id = HashMap::new();
    let mut seen_mix_ids = HashSet::new();
    let mut mix_ids = Vec::new();
    for song in songs.iter().filter(|song| needs_song_detail(song)) {
        let Some(mix_id) = song.mix_song_id else {
            continue;
        };
        if seen_mix_ids.insert(mix_id) {
            mix_ids.push(mix_id);
        }
    }
    for chunk in mix_ids.chunks(40) {
        if let Ok(response) = client.songs().details_by_mix_ids(session, chunk).await {
            for detail in response.data.items {
                if let Some(mix_id) = detail.mix_song_id {
                    details_by_mix_id.insert(mix_id, detail);
                }
            }
        }
    }
    songs
        .iter()
        .map(|song| {
            let detail = song.mix_song_id.and_then(|id| details_by_mix_id.get(&id));
            song_to_dto_with_detail(song, detail)
        })
        .collect()
}

fn needs_song_detail(song: &SongRef) -> bool {
    song.artwork_url.is_none()
        || song.resources.standard.is_none()
        || (song.resources.high.is_none()
            && song.resources.flac.is_none()
            && song.resources.hires.is_none()
            && song.resources.super_hash.is_none())
}

pub(super) fn artwork_from_extra(extra: &BTreeMap<String, Value>) -> Option<String> {
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

    for key in ARTWORK_KEYS.iter().chain(CONTAINER_KEYS) {
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

fn object_value_for_key<'a>(
    object: &'a serde_json::Map<String, Value>,
    key: &str,
) -> Option<&'a Value> {
    object
        .iter()
        .find_map(|(name, value)| artwork_key_matches(name, key).then_some(value))
}

pub(super) fn scalar_string_for_keys(value: &Value, keys: &[&str]) -> Option<String> {
    let object = value.as_object()?;
    keys.iter().find_map(|key| {
        let value = object_value_for_key(object, key)?;
        match value {
            Value::String(value) => nonempty_artwork(value),
            Value::Number(value) => Some(value.to_string()),
            _ => None,
        }
    })
}

fn bool_for_keys(value: &Value, keys: &[&str]) -> bool {
    let Some(object) = value.as_object() else {
        return false;
    };
    keys.iter().any(|key| {
        let Some(value) = object_value_for_key(object, key) else {
            return false;
        };
        match value {
            Value::Bool(value) => *value,
            Value::Number(value) => value.as_i64().is_some_and(|value| value != 0),
            Value::String(value) => matches!(
                value.trim().to_ascii_lowercase().as_str(),
                "1" | "true" | "yes"
            ),
            _ => false,
        }
    })
}

pub(super) fn vip_product_to_dto(value: &Value) -> VipProductDto {
    VipProductDto {
        product_type: scalar_string_for_keys(value, &["product_type", "productType"]),
        business_type: scalar_string_for_keys(value, &["busi_type", "busiType"]),
        active: bool_for_keys(value, &["is_vip", "isVip"]),
        paid: bool_for_keys(value, &["is_paid_vip", "isPaidVip"]),
        yearly: bool_for_keys(value, &["y_type", "yType"]),
        vip_end_time: scalar_string_for_keys(value, &["vip_end_time", "vipEndTime", "vip_endtime"]),
        paid_expire_time: scalar_string_for_keys(
            value,
            &[
                "paid_vip_expire_time",
                "paidVipExpireTime",
                "paid_vip_end_time",
            ],
        ),
    }
}

pub(super) fn search_playlist_to_dto(value: &SearchPlaylist) -> PlaylistSearchHitDto {
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

pub(super) fn cloud_playlist_to_dto(value: &UserPlaylist) -> CloudPlaylistDto {
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
        create_time: value.create_time,
        update_time: value.update_time,
        sort: value.sort,
    }
}

pub(super) fn stable_song_id(mix_song_id: Option<u64>, primary_hash: Option<&str>) -> String {
    if let Some(id) = mix_song_id {
        format!("mix:{id}")
    } else if let Some(hash) = primary_hash.filter(|value| !value.is_empty()) {
        format!("hash:{}", hash.to_ascii_lowercase())
    } else {
        "unknown".to_owned()
    }
}

pub(super) fn audio_quality_from_dto(quality: AudioQualityDto) -> AudioQuality {
    match quality {
        AudioQualityDto::Standard => AudioQuality::Standard,
        AudioQualityDto::High => AudioQuality::High,
        AudioQualityDto::Flac => AudioQuality::Flac,
        AudioQualityDto::HiRes => AudioQuality::HiRes,
        AudioQualityDto::Super => AudioQuality::Super,
    }
}

pub(super) fn audio_quality_to_dto(quality: AudioQuality) -> AudioQualityDto {
    match quality {
        AudioQuality::Standard => AudioQualityDto::Standard,
        AudioQuality::High => AudioQualityDto::High,
        AudioQuality::Flac => AudioQualityDto::Flac,
        AudioQuality::HiRes => AudioQualityDto::HiRes,
        AudioQuality::Super => AudioQualityDto::Super,
        _ => AudioQualityDto::Standard,
    }
}
