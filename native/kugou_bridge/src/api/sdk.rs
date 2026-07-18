use kugou_sdk::user::{YOUTH_DAY_VIP_SOURCE_MINE, YouthDayVipClaimRequest};
use kugou_sdk::{
    CollectRequest, DiscoveryCardRequest, FreshSongAction, FreshSongsRequest, HeartRadioRequest,
    HistoryFetchRequest, HistorySongOp, HistoryUploadRequest, LyricSearchRequest, Pagination,
    PersonalFmRequest, PlaybackOutcome, PlaylistEditRequest, PlaylistKind, PlaylistTrackInput,
    ReportHistoryRequest, ReportRepeatedRequest, SearchRequest, SongRef,
};

pub use super::dto::*;
use super::mapping::*;
use super::{auth, logging, runtime};

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // FRB's default helper installs android_logger first, which would prevent
    // the app and kugou_sdk from sharing our file logger.
    let _ = logging::install();
    flutter_rust_bridge::setup_backtrace();
}

pub fn initialize_native_logging(
    directory: String,
    level: AppLogLevelDto,
) -> Result<(), BridgeError> {
    logging::initialize(directory, level)
}

pub fn set_native_log_level(level: AppLogLevelDto) -> Result<(), BridgeError> {
    logging::set_level(level)
}

pub fn clear_native_logs() -> Result<(), BridgeError> {
    logging::clear()
}

pub fn flush_native_logs() -> Result<(), BridgeError> {
    logging::flush()
}

pub fn initialize_sdk(
    device_profile: DeviceProfileDto,
    persisted_session: Option<String>,
) -> Result<(), BridgeError> {
    runtime::initialize(device_profile, persisted_session)
}

pub async fn get_auth_state() -> Result<AuthStateDto, BridgeError> {
    auth::auth_state().await
}

pub async fn ensure_device_registered() -> Result<AuthStateDto, BridgeError> {
    auth::ensure_device_registered().await
}

pub async fn send_sms_code(mobile: String) -> Result<(), BridgeError> {
    auth::send_sms_code(mobile).await
}

pub async fn login_by_sms(mobile: String, code: String) -> Result<AuthStateDto, BridgeError> {
    auth::login_by_sms(mobile, code).await
}

pub async fn refresh_login() -> Result<AuthStateDto, BridgeError> {
    auth::refresh_login().await
}

pub async fn register_device() -> Result<AuthStateDto, BridgeError> {
    auth::register_device().await
}

pub async fn logout() -> Result<AuthStateDto, BridgeError> {
    auth::logout().await
}

pub async fn search_songs(request: SearchRequestDto) -> Result<SongPageDto, BridgeError> {
    let (keyword, page, page_size) = validated_search(&request)?;
    let runtime = runtime::get()?;
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

pub async fn get_everyday_recommendations() -> Result<Vec<SongDto>, BridgeError> {
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
    Ok(songs)
}

pub async fn get_discovery_card(
    card_id: u32,
    page_size: u32,
) -> Result<DiscoveryCardDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let card = runtime
        .client
        .discovery()
        .card(
            &mut session,
            DiscoveryCardRequest::new(card_id).page_size(page_size.clamp(1, 30)),
        )
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    let songs = songs_to_dtos_with_artwork(&runtime.client, &mut session, &card.items).await;
    Ok(DiscoveryCardDto {
        card_id: card.card_id.unwrap_or(card_id),
        title: card.title,
        subtitle: card.desc.or(card.label_desc),
        songs,
    })
}

pub async fn get_personal_fm(
    request: PersonalFmRequestDto,
) -> Result<RecommendationBatchDto, BridgeError> {
    let runtime = runtime()?;
    let current_song = request.current_song.as_ref().map(song_dto_to_song_ref);
    let mut fm_request = match request.action {
        PersonalFmActionDto::Play => current_song
            .as_ref()
            .map(|song| PersonalFmRequest::next(request.remain_song_count, song))
            .unwrap_or_else(|| {
                PersonalFmRequest::start().remain_songcnt(request.remain_song_count)
            }),
        PersonalFmActionDto::Skip => PersonalFmRequest::skip(
            current_song
                .as_ref()
                .ok_or_else(|| BridgeError::invalid_argument("skip requires current song"))?,
        )
        .remain_songcnt(request.remain_song_count),
        PersonalFmActionDto::Garbage => PersonalFmRequest::garbage(
            current_song
                .as_ref()
                .ok_or_else(|| BridgeError::invalid_argument("garbage requires current song"))?,
        )
        .remain_songcnt(request.remain_song_count),
    };
    if let Some(playtime) = request.playtime_secs {
        fm_request = fm_request.playtime(playtime);
    }
    if let Some(mark_list) = request.mark_list.filter(|value| !value.trim().is_empty()) {
        fm_request = fm_request.mark_list(mark_list);
    }
    if let Some(current_mark) = request
        .current_mark
        .filter(|value| !value.trim().is_empty())
    {
        fm_request = fm_request.cur_mark(current_mark);
    }

    let mut session = runtime.session.lock().await;
    let response = runtime
        .client
        .recommend()
        .personal_fm(&mut session, fm_request)
        .await
        .map_err(BridgeError::from_sdk)?;
    let songs =
        songs_to_dtos_with_artwork(&runtime.client, &mut session, &response.data.items).await;
    Ok(RecommendationBatchDto {
        title: "猜你喜欢".to_owned(),
        subtitle: response.data.mark.clone(),
        mark_list: response.data.mark_list,
        mark: response.data.mark,
        songs,
    })
}

pub async fn get_heart_radio(
    request: HeartRadioRequestDto,
) -> Result<RecommendationBatchDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let response = runtime
        .client
        .recommend()
        .heart_radio(
            &mut session,
            HeartRadioRequest::new().curr_mixids(request.current_mix_song_ids),
        )
        .await
        .map_err(BridgeError::from_sdk)?;
    let songs =
        songs_to_dtos_with_artwork(&runtime.client, &mut session, &response.data.items).await;
    Ok(RecommendationBatchDto {
        title: "红心电台".to_owned(),
        subtitle: response.data.intro,
        mark_list: None,
        mark: None,
        songs,
    })
}

pub async fn report_recommendation_history(
    items: Vec<RecommendationHistoryItemDto>,
    previous_sync_point: Option<i64>,
) -> Result<RecommendationReportAckDto, BridgeError> {
    if items.is_empty() {
        return Err(BridgeError::invalid_argument(
            "recommendation history report requires items",
        ));
    }
    let rows = items
        .iter()
        .map(recommendation_history_item_to_sdk)
        .collect();
    let mut request = ReportHistoryRequest::new(rows).map_err(BridgeError::from_sdk)?;
    if let Some(sync_point) = previous_sync_point {
        request = request.prev_sync_point(sync_point);
    }
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let response = runtime
        .client
        .recommend()
        .report_history(&mut session, request)
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(recommendation_report_ack_to_dto(&response.data))
}

pub async fn report_recommendation_repeated(
    hashes: Vec<String>,
    remain_song_count: u32,
) -> Result<(), BridgeError> {
    let request = ReportRepeatedRequest::from_hashes(hashes)
        .map_err(BridgeError::from_sdk)?
        .remain(remain_song_count);
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .recommend()
        .report_repeated(&mut session, request)
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(())
}

pub async fn report_recommendation_favorite_click(song: SongDto) -> Result<(), BridgeError> {
    let song = song_dto_to_song_ref(&song);
    let request = FreshSongsRequest::new(vec![FreshSongAction::from_song("click_red", &song)])
        .map_err(BridgeError::from_sdk)?;
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .recommend()
        .fresh_songs(&mut session, request)
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(())
}

pub async fn resolve_playback(
    request: ResolvePlaybackRequestDto,
) -> Result<PlaybackResolutionDto, BridgeError> {
    let runtime = runtime()?;
    let song = song_dto_to_song_ref(&request.song);
    let requested_quality = audio_quality_from_dto(request.quality);
    let (_, actual_quality) = song
        .resources
        .select_for(requested_quality)
        .ok_or_else(|| BridgeError::invalid_argument("song has no usable resource hash"))?;
    let playback = song
        .playback_request(requested_quality)
        .ok_or_else(|| BridgeError::invalid_argument("song has no usable resource hash"))?
        .free_preview(request.free_preview);
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
        PlaybackOutcome::Denied { .. } => PlaybackResolutionDto::Denied,
        _ => PlaybackResolutionDto::Unavailable,
    })
}

/// Fetch and parse the best timed lyric for a song.
///
/// Lyrics deliberately use the standard FileHash carried by `SongRef`; playback
/// quality hashes are not substituted. The candidate adjustment is applied to
/// the parsed document so Dart receives the final player timeline.
pub async fn get_song_lyrics(song: SongDto) -> Result<LyricFetchDto, BridgeError> {
    let runtime = runtime()?;
    let song = song_dto_to_lyric_ref(&song);
    let request = LyricSearchRequest::from_song(&song).map_err(BridgeError::from_sdk)?;
    let mut session = runtime.session.lock().await;
    let candidates = runtime
        .client
        .lyrics()
        .search(&mut session, request)
        .await
        .map_err(BridgeError::from_sdk)?;
    let Some(best) = candidates.data.best() else {
        return Ok(LyricFetchDto::NotFound);
    };
    if !best.is_downloadable() {
        return Ok(LyricFetchDto::NotFound);
    }
    let id = best.id.as_deref().unwrap_or_default().to_owned();
    let access_key = best.access_key.as_deref().unwrap_or_default().to_owned();
    let format = best.suggested_fmt().to_owned();
    let adjust = best.adjust.unwrap_or(0);
    let content = runtime
        .client
        .lyrics()
        .download(&mut session, id, access_key, format)
        .await
        .map_err(BridgeError::from_sdk)?;
    let document = content
        .data
        .parse()
        .map_err(BridgeError::from_sdk)?
        .with_adjust(adjust);
    if document.lines.is_empty() {
        return Ok(LyricFetchDto::NotFound);
    }
    Ok(LyricFetchDto::Found {
        document: lyric_document_to_dto(document),
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
        business_type: value.busi_type,
        products: value.products.iter().map(vip_product_to_dto).collect(),
    })
}

pub async fn claim_day_vip() -> Result<VipClaimResultDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = runtime
        .client
        .users()
        .claim_day_vip(
            &mut session,
            YouthDayVipClaimRequest::new().source_id(YOUTH_DAY_VIP_SOURCE_MINE),
        )
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    Ok(VipClaimResultDto {
        granted_units: value.ad_vip_num,
        end_time: value.ad_vip_end_time,
        server_time_secs: value.server_time,
    })
}

pub async fn upgrade_day_vip() -> Result<VipUpgradeResultDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = runtime
        .client
        .users()
        .upgrade_day_vip(&mut session)
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    Ok(VipUpgradeResultDto {
        status_code: value.status_code,
        message: value.message,
        end_time: value.end_time,
    })
}

pub async fn get_month_vip_record() -> Result<VipMonthRecordDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = runtime
        .client
        .users()
        .month_vip_record(&mut session)
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    let claim_dates = value
        .items
        .iter()
        .filter_map(|item| scalar_string_for_keys(item, &["day", "receive_day", "date"]))
        .collect();
    Ok(VipMonthRecordDto {
        claimed_days: value.claimed_days,
        claim_dates,
    })
}

pub async fn get_cloud_history(cursor: Option<String>) -> Result<HistoryPageDto, BridgeError> {
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let request = cursor
        .filter(|value| !value.trim().is_empty())
        .map_or_else(HistoryFetchRequest::new, |value| {
            HistoryFetchRequest::new().bp(value)
        });
    let value = runtime
        .client
        .users()
        .history_page(&mut session, request)
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    let history_items: Vec<_> = value
        .items
        .into_iter()
        .filter(|item| item.op != Some(0))
        .collect();
    let songs: Vec<SongRef> = history_items.iter().map(|item| item.song.clone()).collect();
    let song_dtos = songs_to_dtos_with_artwork(&runtime.client, &mut session, &songs).await;
    let items = history_items
        .into_iter()
        .zip(song_dtos)
        .map(|(item, song)| HistorySongDto {
            song,
            played_at_secs: item.ot,
            play_count: item.pc,
        })
        .collect();
    let has_more = value
        .has_more
        .unwrap_or_else(|| value.bp.as_deref().is_some_and(|bp| !bp.is_empty()));
    Ok(HistoryPageDto {
        items,
        cursor: value.bp,
        has_more,
        total: value.total,
    })
}

pub async fn upload_cloud_history(items: Vec<HistoryUploadItemDto>) -> Result<(), BridgeError> {
    let songs = items
        .into_iter()
        .map(|item| HistorySongOp::add(item.mix_song_id, item.played_at_secs, item.play_count))
        .collect();
    let request = HistoryUploadRequest::new(songs)
        .map_err(BridgeError::from_sdk)?
        .device_type(1);
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .users()
        .history_upload(&mut session, request)
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(())
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
    })
}

#[derive(Debug, PartialEq, Eq)]
enum PlaylistTracksRoute {
    Gid(String),
    ListId(u64),
}

pub async fn get_playlist_tracks_by_gid(
    global_collection_id: String,
    page: u32,
    page_size: u32,
) -> Result<SongPageDto, BridgeError> {
    let gid = global_collection_id.trim();
    if gid.is_empty() {
        return Err(BridgeError::invalid_argument(
            "playlist requires collection id",
        ));
    }
    get_playlist_tracks(PlaylistTracksRoute::Gid(gid.to_owned()), page, page_size).await
}

pub async fn get_playlist_tracks_by_list_id(
    list_id: u64,
    page: u32,
    page_size: u32,
) -> Result<SongPageDto, BridgeError> {
    if list_id == 0 {
        return Err(BridgeError::invalid_argument(
            "owned playlist requires list_id",
        ));
    }
    get_playlist_tracks(PlaylistTracksRoute::ListId(list_id), page, page_size).await
}

async fn get_playlist_tracks(
    route: PlaylistTracksRoute,
    page: u32,
    page_size: u32,
) -> Result<SongPageDto, BridgeError> {
    let page = page.max(1);
    let page_size = page_size.clamp(1, 100);
    let runtime = runtime()?;
    let mut session = runtime.session.lock().await;
    let value = match route {
        PlaylistTracksRoute::Gid(gid) => {
            runtime
                .client
                .playlists()
                .tracks(&mut session, &gid, Pagination::new(page, page_size))
                .await
                .map_err(BridgeError::from_sdk)?
                .data
        }
        PlaylistTracksRoute::ListId(list_id) => {
            runtime
                .client
                .playlists()
                .tracks_by_listid(&mut session, list_id, Pagination::new(page, page_size))
                .await
                .map_err(BridgeError::from_sdk)?
                .data
        }
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
    let list_id = value
        .list_id
        .filter(|id| *id > 0)
        .ok_or_else(|| BridgeError::internal("cloud create returned no playlist id"))?;
    Ok(PlaylistMutationDto {
        list_id,
        global_collection_id: value.global_collection_id,
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
    let list_id = value
        .list_id
        .filter(|id| *id > 0)
        .ok_or_else(|| BridgeError::internal("cloud collect returned no playlist id"))?;
    Ok(PlaylistMutationDto {
        list_id,
        global_collection_id: value.global_collection_id,
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

pub async fn add_song_to_playlist(
    list_id: u64,
    song: SongDto,
) -> Result<PlaylistTracksMutationDto, BridgeError> {
    let hash = song
        .hashes
        .standard
        .clone()
        .or(song.hashes.high.clone())
        .or(song.hashes.flac.clone())
        .or(song.hashes.hi_res.clone())
        .or(song.hashes.super_hash.clone())
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
    let value = runtime
        .client
        .playlists()
        .add_tracks(&mut session, list_id, [track])
        .await
        .map_err(BridgeError::from_sdk)?
        .data;
    Ok(PlaylistTracksMutationDto {
        file_ids: value.file_ids,
    })
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
    runtime::export().await
}

fn runtime() -> Result<&'static runtime::KugouRuntime, BridgeError> {
    runtime::get()
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

#[cfg(test)]
mod tests {
    use super::*;
    use kugou_sdk::{AudioQuality, ClientPlaylistItem, LyricDocument, LyricFormat, ResourceHashes};
    use serde_json::Value;
    use std::collections::{BTreeMap, HashMap};

    #[test]
    fn stable_id_prefers_mix_id() {
        assert_eq!(stable_song_id(Some(42), Some("ABC")), "mix:42");
        assert_eq!(stable_song_id(None, Some("ABC")), "hash:abc");
    }

    #[test]
    fn lyric_request_uses_standard_hash_and_joint_identity_fields() {
        let song = SongDto {
            id: "mix:42".into(),
            title: "海阔天空".into(),
            artist: Some("BEYOND".into()),
            album: None,
            duration_secs: Some(326),
            artwork_url: None,
            privilege: None,
            album_id: None,
            mix_song_id: Some(42),
            file_id: None,
            hashes: AudioHashesDto {
                standard: Some("STANDARD".into()),
                high: Some("HIGH".into()),
                flac: Some("FLAC".into()),
                hi_res: None,
                super_hash: None,
            },
        };
        let song_ref = song_dto_to_lyric_ref(&song);
        assert_eq!(song_ref.primary_hash(), Some("STANDARD"));
        assert!(song_ref.resources.high.is_none());
        assert!(song_ref.resources.flac.is_none());

        let request = LyricSearchRequest::from_song(&song_ref).unwrap();
        let json = serde_json::to_value(request).unwrap();
        assert_eq!(json["hash"], "STANDARD");
        assert_eq!(json["keyword"], "BEYOND - 海阔天空");
        assert_eq!(json["duration_ms"], 326_000);
        assert_eq!(json["album_audio_id"], 42);
    }

    #[test]
    fn recommendation_report_mapping_preserves_song_identity_and_action() {
        let song = SongDto {
            id: "mix:42".into(),
            title: "测试歌曲".into(),
            artist: Some("测试歌手".into()),
            album: None,
            duration_secs: Some(180),
            artwork_url: None,
            privilege: None,
            album_id: None,
            mix_song_id: Some(42),
            file_id: None,
            hashes: AudioHashesDto {
                standard: Some("STANDARD".into()),
                high: Some("HIGH".into()),
                flac: None,
                hi_res: None,
                super_hash: None,
            },
        };
        let row = recommendation_history_item_to_sdk(&RecommendationHistoryItemDto {
            action: RecommendationHistoryActionDto::Collect,
            song,
        });
        assert_eq!(row.action, ClientPlaylistItem::ACTION_COLLECT);
        assert_eq!(row.hash.as_deref(), Some("STANDARD"));
        assert_eq!(row.mix_song_id, Some(42));
    }

    #[test]
    fn lyric_document_mapping_preserves_adjusted_timeline_and_words() {
        let mut word = kugou_sdk::LyricWord::default();
        word.start_ms = 0;
        word.duration_ms = 250;
        word.text = "你".into();
        let mut line = kugou_sdk::LyricLine::default();
        line.start_ms = 1_000;
        line.duration_ms = 500;
        line.text = "你好".into();
        line.words = vec![word];
        line.translation = Some("hello".into());
        let mut document = LyricDocument::default();
        document.format = LyricFormat::Krc;
        document.offset_ms = -120;
        document.lines = vec![line];
        let document = document.with_adjust(20);

        let dto = lyric_document_to_dto(document);
        assert_eq!(dto.format, LyricFormatDto::Krc);
        assert_eq!(dto.offset_ms, -100);
        assert_eq!(dto.lines[0].words[0].text, "你");
        assert_eq!(dto.lines[0].translation.as_deref(), Some("hello"));
    }

    #[test]
    fn quality_falls_back_with_matching_label() {
        let mut hashes = ResourceHashes::default();
        hashes.standard = Some("STD".into());
        let selected = hashes
            .select_for(audio_quality_from_dto(AudioQualityDto::Flac))
            .unwrap();
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

    #[test]
    fn vip_product_mapping_accepts_soft_scalar_aliases() {
        let product = serde_json::json!({
            "productType": "tvip",
            "busi_type": "concept",
            "is_vip": "1",
            "isPaidVip": true,
            "y_type": 1,
            "vip_end_time": 1_700_000_000_i64,
            "paidVipExpireTime": "2026-08-01"
        });
        let dto = vip_product_to_dto(&product);
        assert_eq!(dto.product_type.as_deref(), Some("tvip"));
        assert_eq!(dto.business_type.as_deref(), Some("concept"));
        assert!(dto.active);
        assert!(dto.paid);
        assert!(dto.yearly);
        assert_eq!(dto.vip_end_time.as_deref(), Some("1700000000"));
        assert_eq!(dto.paid_expire_time.as_deref(), Some("2026-08-01"));
    }

    #[test]
    fn month_record_dates_accept_known_aliases() {
        let rows = [
            serde_json::json!({"day": "2026-07-14"}),
            serde_json::json!({"receive_day": 20260715}),
            serde_json::json!({"date": "2026-07-16"}),
        ];
        let dates: Vec<_> = rows
            .iter()
            .filter_map(|value| scalar_string_for_keys(value, &["day", "receive_day", "date"]))
            .collect();
        assert_eq!(dates, ["2026-07-14", "20260715", "2026-07-16"]);
    }
}
