// lib/business_logic/search_filter_engine.dart
import '../model/course_model.dart';
import '../repository/course_repository.dart';

class SearchFilterEngine {
  final CourseRepository _courseRepository = CourseRepository();

  // Advanced search with filters
  Future<List<CourseModel>> searchCourses({
    String? query,
    String? category,
    String? level,
    double? minRating,
    int? maxPrice,
    String? sortBy, // 'rating', 'price', 'newest', 'popular'
  }) async {
    try {
      List<CourseModel> courses;

      // Get courses based on filters
      if (category != null) {
        courses = await _courseRepository.getCoursesByCategory(category);
      } else if (level != null) {
        courses = await _courseRepository.getCoursesByLevel(level);
      } else {
        courses = await _courseRepository.getAllPublishedCourses();
      }

      // Apply text search
      if (query != null && query.isNotEmpty) {
        courses = courses.where((course) {
          final searchQuery = query.toLowerCase();
          return course.title.toLowerCase().contains(searchQuery) ||
              course.description.toLowerCase().contains(searchQuery) ||
              course.tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
              course.instructor.toLowerCase().contains(searchQuery);
        }).toList();
      }

      // Apply rating filter
      if (minRating != null) {
        courses = courses.where((course) => course.rating >= minRating).toList();
      }

      // Apply price filter
      if (maxPrice != null) {
        courses = courses.where((course) => course.price <= maxPrice).toList();
      }

      // Sort
      if (sortBy != null) {
        switch (sortBy) {
          case 'rating':
            courses.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'price':
            courses.sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'newest':
            courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case 'popular':
            courses.sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
            break;
        }
      }

      return courses;
    } catch (e) {
      return [];
    }
  }

  // Get all categories
  Future<List<String>> getCategories() async {
    try {
      final courses = await _courseRepository.getAllPublishedCourses();
      final categories = courses.map((c) => c.category).toSet().toList();
      return categories;
    } catch (e) {
      return [];
    }
  }

  // Get all levels
  List<String> getLevels() {
    return ['beginner', 'intermediate', 'advanced'];
  }
}

