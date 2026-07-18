import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/discovery_card.dart';

const homeDiscoveryCardIds = <int>[3001, 3014, 3102, 3004, 3005, 3101];
const homeDiscoveryPageSize = 30;

final homeDiscoveryCardProvider = StreamProvider.family<DiscoveryCard, int>((
  ref,
  cardId,
) {
  final auth = ref.watch(authControllerProvider);
  return ref
      .watch(musicRepositoryProvider)
      .discoveryCard(
        cardId,
        userId: auth.snapshot.userId,
        pageSize: homeDiscoveryPageSize,
      );
});
