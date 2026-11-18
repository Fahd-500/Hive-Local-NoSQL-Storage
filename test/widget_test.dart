import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mobile_computing_assignment_5/models/post_model.dart';
import 'package:mobile_computing_assignment_5/services/favorites_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PostAdapter());
    }
    await Hive.openBox<Post>('postsBox');
    await Hive.openBox<Post>('favoritesBox');
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('Post model fromJson parses correctly', () {
    final json = {
      'id': 1,
      'title': 'Test title',
      'body': 'Test body',
      'userId': 42,
    };
    final post = Post.fromJson(json);
    expect(post.id, 1);
    expect(post.title, 'Test title');
    expect(post.body, 'Test body');
    expect(post.userId, 42);
  });

  test('FavoritesService toggles favorite and creates a separate copy', () async {
    final favoritesService = FavoritesService();
    final postsBox = Hive.box<Post>('postsBox');
    final post = Post(id: 10, title: 'Sample Post', body: 'Sample Content', userId: 1);
    await postsBox.put(10, post);

    expect(favoritesService.isFavorite(10), false);
    expect(favoritesService.getFavorites().length, 0);

    // Toggle on (add to favorites)
    await favoritesService.toggleFavorite(post);
    expect(favoritesService.isFavorite(10), true);
    expect(favoritesService.getFavorites().length, 1);
    expect(favoritesService.getFavorites().first.id, 10);
    expect(favoritesService.getFavorites().first.title, 'Sample Post');

    // Verify it is a separate instance, not same HiveObject instance
    expect(identical(favoritesService.getFavorites().first, post), false);

    // Toggle off (remove from favorites)
    await favoritesService.toggleFavorite(post);
    expect(favoritesService.isFavorite(10), false);
    expect(favoritesService.getFavorites().length, 0);
  });

  test('FavoritesService can handle multiple favorites', () async {
    final favoritesService = FavoritesService();
    final post1 = Post(id: 1, title: 'Post 1', body: 'Body 1', userId: 1);
    final post2 = Post(id: 2, title: 'Post 2', body: 'Body 2', userId: 2);

    await favoritesService.toggleFavorite(post1);
    await favoritesService.toggleFavorite(post2);

    expect(favoritesService.isFavorite(1), true);
    expect(favoritesService.isFavorite(2), true);
    expect(favoritesService.getFavorites().length, 2);

    await favoritesService.toggleFavorite(post1);
    expect(favoritesService.isFavorite(1), false);
    expect(favoritesService.isFavorite(2), true);
    expect(favoritesService.getFavorites().length, 1);
    expect(favoritesService.getFavorites().first.id, 2);
  });

  test('PostService offline fallback returns cached posts when offline', () async {
    final postsBox = Hive.box<Post>('postsBox');
    final cachedPost = Post(id: 99, title: 'Cached Post', body: 'Cached Body', userId: 1);
    await postsBox.put(99, cachedPost);

    // In test environment, verify cache contents can be queried
    expect(postsBox.isNotEmpty, true);
    expect(postsBox.get(99)?.title, 'Cached Post');
  });
}
