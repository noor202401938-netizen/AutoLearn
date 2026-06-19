// lib/backend/xml_course_parser.dart
import 'dart:io';
import 'package:xml/xml.dart';
import '../model/course_model.dart';

class XmlCourseParser {
  // Parse XML file and return list of modules
  static List<ModuleModel> parseModulesFromXml(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final rootElement = document.rootElement;

      if (rootElement.name.local != 'course') {
        throw Exception('Invalid XML format: root element must be <course>');
      }

      final modules = <ModuleModel>[];
      final moduleElements = rootElement.findElements('module');

      for (var moduleElement in moduleElements) {
        final moduleId = moduleElement.getAttribute('id') ?? 
                        'module_${DateTime.now().millisecondsSinceEpoch}';
        final moduleTitle = moduleElement.getAttribute('title') ?? 
                           moduleElement.findElements('title').firstOrNull?.innerText ?? 
                           'Untitled Module';

        final lessons = <LessonModel>[];
        final lessonElements = moduleElement.findElements('lesson');

        for (var lessonElement in lessonElements) {
          final lessonId = lessonElement.getAttribute('id') ?? 
                          'lesson_${DateTime.now().millisecondsSinceEpoch}';
          final lessonTitle = lessonElement.getAttribute('title') ?? 
                            lessonElement.findElements('title').firstOrNull?.innerText ?? 
                            'Untitled Lesson';
          final lessonType = lessonElement.getAttribute('type') ?? 'video';
          final durationStr = lessonElement.getAttribute('duration') ?? 
                             lessonElement.findElements('duration').firstOrNull?.innerText ?? 
                             '0';
          final duration = int.tryParse(durationStr) ?? 0;
          
          String? videoURL;
          String? content;

          if (lessonType == 'video') {
            videoURL = lessonElement.getAttribute('videoURL') ?? 
                      lessonElement.findElements('videoURL').firstOrNull?.innerText;
          } else if (lessonType == 'reading') {
            content = lessonElement.findElements('content').firstOrNull?.innerText;
          }

          lessons.add(LessonModel(
            lessonId: lessonId,
            title: lessonTitle,
            duration: duration,
            type: lessonType,
            videoURL: videoURL,
            content: content,
          ));
        }

        modules.add(ModuleModel(
          moduleId: moduleId,
          title: moduleTitle,
          lessons: lessons,
        ));
      }

      return modules;
    } catch (e) {
      throw Exception('Failed to parse XML: $e');
    }
  }

  // Convert modules to XML string
  static String modulesToXml(List<ModuleModel> modules) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('course', nest: () {
      for (var module in modules) {
        builder.element('module', attributes: {
          'id': module.moduleId,
          'title': module.title,
        }, nest: () {
          for (var lesson in module.lessons) {
            final attributes = {
              'id': lesson.lessonId,
              'title': lesson.title,
              'type': lesson.type,
              'duration': lesson.duration.toString(),
            };

            if (lesson.videoURL != null) {
              attributes['videoURL'] = lesson.videoURL!;
            }

            builder.element('lesson', attributes: attributes, nest: () {
              if (lesson.content != null && lesson.type == 'reading') {
                builder.element('content', nest: lesson.content);
              }
            });
          }
        });
      }
    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: true);
  }

  // Read XML from file
  static Future<String> readXmlFromFile(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read XML file: $e');
    }
  }

  // Write XML to file
  static Future<void> writeXmlToFile(String xmlContent, File file) async {
    try {
      await file.writeAsString(xmlContent);
    } catch (e) {
      throw Exception('Failed to write XML file: $e');
    }
  }

  // Validate XML structure
  static bool validateXml(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final rootElement = document.rootElement;
      
      if (rootElement.name.local != 'course') {
        return false;
      }

      // Check if at least one module exists
      final modules = rootElement.findElements('module');
      if (modules.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

