import '../backend/api_client.dart';

DateTime _date(dynamic v) => DateTime.tryParse('$v') ?? DateTime.now();

class Bookmark {
  final String id;
  final String courseId;
  final String courseTitle;
  final String category;
  final String? lessonId;
  final String title;
  final String? note;
  final int? positionSeconds;
  final DateTime createdAt;

  Bookmark.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        courseId = j['courseId'] as String,
        courseTitle = j['courseTitle'] as String? ?? '',
        category = j['category'] as String? ?? '',
        lessonId = j['lessonId'] as String?,
        title = j['title'] as String? ?? '',
        note = j['note'] as String?,
        positionSeconds = (j['positionSeconds'] as num?)?.toInt(),
        createdAt = _date(j['createdAt']);
}

class PathStep {
  final String courseId;
  final String title;
  final String level;
  final bool enrolled;
  final double completion;

  PathStep.fromJson(Map<String, dynamic> j)
      : courseId = j['courseId'] as String,
        title = j['title'] as String? ?? '',
        level = j['level'] as String? ?? '',
        enrolled = j['enrolled'] as bool? ?? false,
        completion = (j['completion'] as num?)?.toDouble() ?? 0;
}

class LearningPath {
  final String id;
  final String title;
  final String description;
  final String level;
  final List<String> skills;
  final List<PathStep> courses;
  final double progress;

  LearningPath.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String? ?? '',
        description = j['description'] as String? ?? '',
        level = j['level'] as String? ?? '',
        skills = (j['skills'] as List? ?? const []).cast<String>(),
        courses = (j['courses'] as List? ?? const []).map((c) => PathStep.fromJson(c as Map<String, dynamic>)).toList(),
        progress = (j['progress'] as num?)?.toDouble() ?? 0;
}

class ForumAuthor {
  final String id;
  final String name;
  final String role;
  ForumAuthor.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String? ?? '',
        role = j['role'] as String? ?? 'student';
  bool get isStaff => role == 'admin' || role == 'teacher';
}

class ForumReply {
  final String id;
  final ForumAuthor author;
  final String body;
  final DateTime createdAt;
  int upvotes;
  bool upvotedByMe;
  bool accepted;

  ForumReply.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        author = ForumAuthor.fromJson(j['author'] as Map<String, dynamic>),
        body = j['body'] as String? ?? '',
        createdAt = _date(j['createdAt']),
        upvotes = (j['upvotes'] as num?)?.toInt() ?? 0,
        upvotedByMe = j['upvotedByMe'] as bool? ?? false,
        accepted = j['accepted'] as bool? ?? false;
}

class ForumThread {
  final String id;
  final ForumAuthor author;
  final String category;
  final String title;
  final String body;
  final List<String> tags;
  final int replyCount;
  final String? acceptedReplyId;
  final DateTime createdAt;
  final List<ForumReply> replies;
  /// True for admins, and for the teacher of the course the thread belongs to.
  final bool canModerate;
  int upvotes;
  bool upvotedByMe;

  ForumThread.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        author = ForumAuthor.fromJson(j['author'] as Map<String, dynamic>),
        category = j['category'] as String? ?? 'general',
        title = j['title'] as String? ?? '',
        body = j['body'] as String? ?? '',
        tags = (j['tags'] as List? ?? const []).cast<String>(),
        replyCount = (j['replyCount'] as num?)?.toInt() ?? 0,
        acceptedReplyId = j['acceptedReplyId'] as String?,
        createdAt = _date(j['createdAt']),
        replies = (j['replies'] as List? ?? const []).map((r) => ForumReply.fromJson(r as Map<String, dynamic>)).toList(),
        canModerate = j['canModerate'] as bool? ?? false,
        upvotes = (j['upvotes'] as num?)?.toInt() ?? 0,
        upvotedByMe = j['upvotedByMe'] as bool? ?? false;
}

/// Bookmarks, learning paths and the forum. Errors surface as [ApiException].
class CommunityRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<Bookmark>> bookmarks() async =>
      ((await _api.json('GET', '/user/bookmarks')) as List).map((j) => Bookmark.fromJson(j as Map<String, dynamic>)).toList();

  Future<Bookmark> addBookmark({required String courseId, required String title, String? lessonId, String? note, int? positionSeconds}) async =>
      Bookmark.fromJson(await _api.json('POST', '/user/bookmarks', body: {
        'courseId': courseId,
        'title': title,
        'lessonId': lessonId,
        'note': note,
        'positionSeconds': positionSeconds,
      }));

  Future<void> deleteBookmark(String id) => _api.json('DELETE', '/user/bookmarks/$id');

  Future<List<LearningPath>> learningPaths() async =>
      ((await _api.json('GET', '/learning-paths')) as List).map((j) => LearningPath.fromJson(j as Map<String, dynamic>)).toList();

  Future<List<ForumThread>> threads({String? category, String? query, String sort = 'new'}) async {
    final q = Uri(queryParameters: {
      if (category != null && category != 'all') 'category': category,
      if (query != null && query.isNotEmpty) 'q': query,
      'sort': sort,
    }).query;
    return ((await _api.json('GET', '/forum/threads?$q')) as List)
        .map((j) => ForumThread.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ForumThread> thread(String id) async => ForumThread.fromJson(await _api.json('GET', '/forum/threads/$id'));

  Future<ForumThread> createThread({
    required String title,
    required String body,
    required String category,
    String? courseId,
    List<String> tags = const [],
  }) async =>
      ForumThread.fromJson(await _api.json('POST', '/forum/threads', body: {
        'title': title,
        'body': body,
        'category': category,
        'tags': tags,
        if (courseId != null) 'courseId': courseId,
      }));

  Future<ForumReply> reply(String threadId, String body) async =>
      ForumReply.fromJson(await _api.json('POST', '/forum/threads/$threadId/replies', body: {'body': body}));

  /// Returns (upvotes, upvotedByMe) after toggling.
  Future<(int, bool)> toggleThreadVote(String id) async {
    final r = await _api.json('POST', '/forum/threads/$id/upvote', body: {});
    return ((r['upvotes'] as num).toInt(), r['upvotedByMe'] as bool);
  }

  Future<(int, bool)> toggleReplyVote(String id) async {
    final r = await _api.json('POST', '/forum/replies/$id/upvote', body: {});
    return ((r['upvotes'] as num).toInt(), r['upvotedByMe'] as bool);
  }

  Future<String?> acceptReply(String threadId, String replyId) async =>
      (await _api.json('POST', '/forum/threads/$threadId/accept', body: {'replyId': replyId}))['acceptedReplyId'] as String?;

  Future<void> deleteThread(String id) => _api.json('DELETE', '/forum/threads/$id');
}
