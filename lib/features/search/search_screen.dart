import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Song> _songs = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _songs = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String keyword) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(musicSdkProvider).search(keyword.trim());
      if (!mounted || keyword != _controller.text) return;
      setState(() => _songs = result.songs);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('搜索', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: false,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: const InputDecoration(
                  hintText: '歌曲、歌手或专辑',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        Expanded(
          child: _songs.isEmpty
              ? Center(
                  child: Text(
                    _controller.text.isEmpty ? '输入关键词，探索 Lite 曲库' : '没有找到结果',
                    style: const TextStyle(color: KgColors.textMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) => SongTile(
                    song: _songs[index],
                    onTap: () => _play(_songs[index]),
                  ),
                ),
        ),
      ],
    ),
  );

  Future<void> _play(Song song) async {
    try {
      await ref.read(audioHandlerProvider).playSong(song, queueSongs: _songs);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
