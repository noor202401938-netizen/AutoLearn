# XML Course Content Management Guide

## Overview

This app supports managing course modules and lessons through XML files. You can create, update, and import course content by editing XML files instead of using the UI.

---

## XML File Structure

### Basic Format

```xml
<?xml version="1.0" encoding="UTF-8"?>
<course>
  <module id="module_1" title="Module Title">
    <lesson id="lesson_1" type="video" duration="15" title="Lesson Title" videoURL="https://youtube.com/..."/>
    <lesson id="lesson_2" type="quiz" duration="10" title="Quiz Title"/>
  </module>
</course>
```

---

## XML Elements

### `<course>` (Root Element)
- **Required:** Yes
- **Attributes:** None
- **Children:** One or more `<module>` elements

### `<module>` (Module Element)
- **Required:** Yes (at least one)
- **Attributes:**
  - `id` (optional): Unique module identifier. If not provided, auto-generated.
  - `title` (required): Module title
- **Children:** Zero or more `<lesson>` elements

### `<lesson>` (Lesson Element)
- **Required:** No
- **Attributes:**
  - `id` (optional): Unique lesson identifier. If not provided, auto-generated.
  - `type` (required): Lesson type - `video`, `quiz`, `assignment`, or `reading`
  - `duration` (required): Duration in minutes (integer)
  - `title` (required): Lesson title
  - `videoURL` (optional): YouTube URL (required for `type="video"`)
- **Children:**
  - `<content>` (optional): Text content for `type="reading"` lessons

---

## Lesson Types

### 1. Video Lesson
```xml
<lesson id="lesson_1" type="video" duration="15" title="Introduction Video" videoURL="https://www.youtube.com/watch?v=VIDEO_ID"/>
```

### 2. Quiz Lesson
```xml
<lesson id="lesson_2" type="quiz" duration="10" title="Chapter 1 Quiz"/>
```

### 3. Assignment Lesson
```xml
<lesson id="lesson_3" type="assignment" duration="30" title="Assignment 1"/>
```

### 4. Reading Lesson
```xml
<lesson id="lesson_4" type="reading" duration="20" title="Reading Material">
  <content>
    Your reading content goes here. This can be multiple paragraphs.
  </content>
</lesson>
```

---

## Complete Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<course>
  <!-- Module 1: Introduction -->
  <module id="module_1" title="Introduction to Economics">
    <lesson id="lesson_1" type="video" duration="15" title="Welcome to Economics" videoURL="https://www.youtube.com/watch?v=3ez10ADR_gM"/>
    <lesson id="lesson_2" type="reading" duration="20" title="What is Economics?">
      <content>
        Economics is the social science that studies how people make choices about allocating limited resources to satisfy unlimited wants.
      </content>
    </lesson>
    <lesson id="lesson_3" type="quiz" duration="10" title="Introduction Quiz"/>
  </module>

  <!-- Module 2: Supply and Demand -->
  <module id="module_2" title="Supply and Demand">
    <lesson id="lesson_4" type="video" duration="20" title="Understanding Supply and Demand" videoURL="https://www.youtube.com/watch?v=RP0j3Lnlazs"/>
    <lesson id="lesson_5" type="assignment" duration="30" title="Supply and Demand Analysis"/>
    <lesson id="lesson_6" type="quiz" duration="15" title="Supply and Demand Quiz"/>
  </module>
</course>
```

---

## How to Use

### Method 1: Import XML File

1. **Create your XML file** following the structure above
2. **Open the app** as Admin
3. **Go to Course Management**
4. **Click the folder icon** (Manage Content) on any course
5. **Click "Import XML"** button
6. **Select your XML file**
7. **Click "Save"** to save to the course

### Method 2: Export and Edit

1. **Open Course Management** in the app
2. **Click "Manage Content"** on a course
3. **Click "Export XML"** to download the current content
4. **Edit the XML file** with your changes
5. **Click "Import XML"** and select your edited file
6. **Click "Save"** to update the course

---

## Best Practices

1. **Use meaningful IDs**: Use descriptive IDs like `module_intro`, `lesson_welcome` for easier tracking
2. **Keep IDs unique**: Each module and lesson should have a unique ID
3. **Validate before import**: Make sure your XML is well-formed
4. **Backup before changes**: Export existing content before making major changes
5. **Use comments**: Add XML comments to organize your content:
   ```xml
   <!-- Module 1: Introduction -->
   ```

---

## XML Validation Rules

- Root element must be `<course>`
- At least one `<module>` must exist
- Each `<lesson>` must have:
  - `type` attribute (video, quiz, assignment, or reading)
  - `duration` attribute (positive integer)
  - `title` attribute
- Video lessons must have `videoURL` attribute
- Reading lessons should have `<content>` child element

---

## Template File

A template XML file is available at:
```
assets/course_content_template.xml
```

You can copy this file and modify it for your courses.

---

## Troubleshooting

### "Invalid XML format" Error
- Check that your XML is well-formed (properly closed tags)
- Ensure root element is `<course>`
- Verify all required attributes are present

### "Failed to parse XML" Error
- Check for special characters that need escaping (`<`, `>`, `&`)
- Ensure all lesson types are valid: `video`, `quiz`, `assignment`, `reading`
- Verify duration is a valid integer

### Imported but not showing
- Make sure you clicked "Save" after importing
- Check that modules have at least one lesson
- Verify the course was updated in Firestore

---

## Tips

- **Version Control**: Keep your XML files in version control (Git) for easy tracking
- **Bulk Updates**: Edit multiple courses by exporting all, editing XML files, and re-importing
- **Templates**: Create template XML files for common course structures
- **Backup**: Always export before making changes to keep backups

---

## Example Workflow

1. Create a new course in the app
2. Export the empty course content (or use template)
3. Edit the XML file with your modules and lessons
4. Import the XML file back into the course
5. Save the course
6. Publish when ready

This workflow allows you to manage course content outside the app and update it easily!

