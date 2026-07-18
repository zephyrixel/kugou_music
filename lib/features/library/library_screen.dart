import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/playlist_tile.dart';
import 'package:kgmusic/features/library/library_overview_sections.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(libraryPlaylistsProvider);
    final historyCount = ref.watch(historyEntriesProvider).value?.length ?? 0;
    final sync = ref.watch(librarySyncStatusProvider).value;
    final favorite = playlists.value
        ?.where((playlist) => playlist.isMyFavorite)
        .firstOrNull;
    return SafeArea(
      bottom: false,
      child: KgContentWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.read(libraryRepositoryProvider).syncNow(),
          child: CustomScrollView(
            key: const PageStorageKey('library-overview-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  KgSpacing.lg,
                  KgSpacing.xl,
                  KgSpacing.lg,
                  KgSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LibraryHeader(sync: sync),
                      const SizedBox(height: KgSpacing.xl),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stacked = constraints.maxWidth < 430;
                          final favorites = LibraryCollectionCard(
                            icon: Icons.favorite_rounded,
                            title: '我喜欢',
                            subtitle:
                                '${favorite?.availableTrackCount ?? 0} 首歌曲',
                            colors: const [
                              Color(0xFF7C5CFF),
                              Color(0xFFB574FF),
                            ],
                            onTap: () => context.go('/library/favorites'),
                          );
                          final history = LibraryCollectionCard(
                            icon: Icons.history_rounded,
                            title: '最近播放',
                            subtitle: '$historyCount 条记录',
                            colors: const [
                              Color(0xFF167F9E),
                              Color(0xFF45BBD0),
                            ],
                            onTap: () => context.go('/library/history'),
                          );
                          if (stacked) {
                            return Column(
                              children: [
                                favorites,
                                const SizedBox(height: KgSpacing.sm),
                                history,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: favorites),
                              const SizedBox(width: KgSpacing.sm),
                              Expanded(child: history),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: KgSpacing.section),
                      KgSectionHeader(
                        title: '我的歌单',
                        subtitle: '收藏和创建的歌单都在这里',
                        action: IconButton.filledTonal(
                          tooltip: '创建歌单',
                          onPressed: () => _createPlaylist(context, ref),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _playlistSliver(context, ref, playlists),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + KgSpacing.xxl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playlistSliver(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Playlist>> playlists,
  ) => playlists.when(
    skipLoadingOnRefresh: true,
    loading: () => const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(KgSpacing.xl),
        child: KgLoadingView(label: '正在读取音乐库'),
      ),
    ),
    error: (error, _) => SliverToBoxAdapter(
      child: KgErrorView(
        message: '音乐库暂时无法加载，请稍后重试',
        onRetry: () async => ref.invalidate(libraryPlaylistsProvider),
      ),
    ),
    data: (items) {
      final visible = items
          .where((playlist) => !playlist.isMyFavorite)
          .toList(growable: false);
      if (visible.isEmpty) {
        return SliverToBoxAdapter(
          child: KgEmptyView(
            '还没有自建或收藏的歌单',
            icon: Icons.queue_music_rounded,
            action: FilledButton.icon(
              onPressed: () => _createPlaylist(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('创建歌单'),
            ),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: KgSpacing.sm),
        sliver: SliverList.builder(
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final playlist = visible[index];
            return PlaylistTile(
              title: playlist.name,
              subtitle: _playlistSubtitle(playlist),
              artworkUrl: playlist.artworkUrl,
              cacheId: 'playlist:${playlist.localId}',
              badge: playlist.isCollected
                  ? '已收藏'
                  : playlist.isPrivate
                  ? '私密'
                  : null,
              onTap: () => context.push('/playlist', extra: playlist),
            );
          },
        ),
      );
    },
  );

  String _playlistSubtitle(Playlist playlist) {
    final creator = playlist.creatorName?.trim();
    if (creator == null || creator.isEmpty) {
      return '${playlist.availableTrackCount} 首歌曲';
    }
    return '$creator · ${playlist.availableTrackCount} 首歌曲';
  }
}

Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
  final result = await promptPlaylistName(
    context,
    title: '创建歌单',
    confirmLabel: '创建',
  );
  if (result == null) return;
  try {
    await ref
        .read(libraryRepositoryProvider)
        .createPlaylist(result.name, private: result.private);
  } catch (_) {
    if (context.mounted) showAppError(context, '歌单创建失败，请稍后重试');
  }
}
