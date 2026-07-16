import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

Future<void> showPlayerQueueSheet(
  BuildContext context,
  MusicAudioHandler handler,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PlayerQueueSheet(handler: handler),
  );
}

class _PlayerQueueSheet extends StatelessWidget {
  const _PlayerQueueSheet({required this.handler});

  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: StreamBuilder<PlaybackQueueState>(
        stream: handler.queueStateStream,
        initialData: handler.queueState,
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state == null) {
            return const Center(child: Text('当前没有播放队列'));
          }
          return Column(
            children: [
              _QueueHeader(handler: handler, state: state),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  itemCount: state.songs.length,
                  onReorderItem: (oldIndex, newIndex) => handler.moveQueueItem(
                    oldIndex,
                    newIndex > oldIndex ? newIndex + 1 : newIndex,
                  ),
                  itemBuilder: (context, index) {
                    final song = state.songs[index];
                    final current = index == state.currentIndex;
                    return ListTile(
                      key: ValueKey('${song.id}:$index'),
                      selected: current,
                      selectedTileColor: KgColors.accentSoft,
                      leading: SongArtwork(
                        url: song.artworkUrl,
                        cacheId: 'song:${song.id}',
                        size: 44,
                        radius: 10,
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        current ? '正在播放' : song.artistLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => handler.skipToQueueItem(index),
                      trailing: current
                          ? const Icon(
                              Icons.graphic_eq_rounded,
                              color: KgColors.accent,
                            )
                          : IconButton(
                              tooltip: '移除',
                              onPressed: () => handler.removeQueueItemAt(index),
                              icon: const Icon(Icons.close_rounded),
                            ),
                    );
                  },
                ),
              ),
              if (state.hasMore || state.loadingMore)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: OutlinedButton.icon(
                    onPressed: state.loadingMore ? null : handler.loadMoreQueue,
                    icon: state.loadingMore
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: Text(state.loadingMore ? '正在加载' : '加载更多歌曲'),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.handler, required this.state});

  final MusicAudioHandler handler;
  final PlaybackQueueState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.origin.displayTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${state.songs.length}${state.origin.totalCount == null ? '' : ' / ${state.origin.totalCount}'} 首 · ${state.order.label}',
                    style: const TextStyle(color: KgColors.textMuted),
                  ),
                ],
              ),
            ),
            PopupMenuButton<PlaybackOrder>(
              tooltip: '播放顺序',
              initialValue: state.order,
              onSelected: handler.setPlaybackOrder,
              itemBuilder: (context) => PlaybackOrder.values
                  .map(
                    (order) => PopupMenuItem(
                      value: order,
                      child: Row(
                        children: [
                          Icon(
                            order == state.order
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: order == state.order
                                ? KgColors.accent
                                : KgColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Text(order.label),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
              child: const Icon(Icons.repeat_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: '队列操作',
              onSelected: (value) {
                if (value == 'clear') handler.clearUpcoming();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'clear', child: Text('清空待播')),
              ],
            ),
          ],
        ),
        if (state.error != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '加载失败：${state.error}',
              style: const TextStyle(color: KgColors.warning, fontSize: 12),
            ),
          ),
      ],
    ),
  );
}
