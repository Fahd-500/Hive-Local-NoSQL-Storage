import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/post_model.dart';

class FavoritesService {
  static const String boxName = 'favoritesBox';

  Box<Post> get _box => Hive.box<Post>(boxName);

  ValueListenable<Box<Post>> listenable() {
    return _box.listenable();
  }

  bool isFavorite(int id) {
    return _box.containsKey(id);
  }

  Future<void> toggleFavorite(Post post) async {
    if (isFavorite(post.id)) {
      await _box.delete(post.id);
    } else {
      // HiveObjects cannot live in multiple boxes simultaneously.
      // Save an independent copy to favoritesBox.
      final copy = Post(
        id: post.id,
        title: post.title,
        body: post.body,
        userId: post.userId,
      );
      await _box.put(post.id, copy);
    }
  }

  List<Post> getFavorites() {
    return _box.values.toList();
  }
}
