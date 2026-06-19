# Quick Start: XML Course Content Management

## 🚀 Quick Overview

You can now manage course modules and lessons using XML files! This makes it easy to:
- Update course content by editing XML files
- Version control your course content
- Bulk import/export course structures
- Work offline and sync later

---

## 📝 Step-by-Step Guide

### **Step 1: Create or Edit a Course**
1. Open the app as **Admin**
2. Go to **Admin Dashboard** → **Courses** tab
3. Create a new course or select an existing one

### **Step 2: Access Content Management**
1. Find your course in the list
2. Click the **📁 folder icon** (Manage Content) button
3. The **Course Content Management** screen opens

### **Step 3: Import XML File**
1. Click **"Import XML"** button
2. Select your XML file from your device
3. The modules and lessons will be loaded
4. Click **"Save"** to save to the course

### **Step 4: Export XML File**
1. Click **"Export XML"** button
2. The XML file will be saved to your device's documents folder
3. Edit the XML file with any text editor
4. Import it back to update the course

---

## 📄 XML File Format

### Minimal Example:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<course>
  <module id="module_1" title="Introduction">
    <lesson id="lesson_1" type="video" duration="15" title="Welcome" videoURL="https://youtube.com/watch?v=VIDEO_ID"/>
  </module>
</course>
```

### Full Example:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<course>
  <module id="module_1" title="Module 1: Introduction">
    <lesson id="lesson_1" type="video" duration="15" title="Welcome Video" videoURL="https://www.youtube.com/watch?v=VIDEO_ID"/>
    <lesson id="lesson_2" type="reading" duration="20" title="Introduction Text">
      <content>Your reading content here...</content>
    </lesson>
    <lesson id="lesson_3" type="quiz" duration="10" title="Quiz 1"/>
    <lesson id="lesson_4" type="assignment" duration="30" title="Assignment 1"/>
  </module>
  
  <module id="module_2" title="Module 2: Advanced Topics">
    <lesson id="lesson_5" type="video" duration="20" title="Advanced Concepts" videoURL="https://www.youtube.com/watch?v=VIDEO_ID2"/>
  </module>
</course>
```

---

## 🎯 Lesson Types

| Type | Description | Required Attributes |
|------|-------------|-------------------|
| `video` | YouTube video lesson | `videoURL` |
| `quiz` | Quiz lesson | None |
| `assignment` | Assignment lesson | None |
| `reading` | Reading material | `<content>` child element |

---

## 💡 Tips

1. **Start with Template**: Copy `assets/course_content_template.xml` as a starting point
2. **Use Meaningful IDs**: Use descriptive IDs like `module_intro`, `lesson_welcome`
3. **Validate XML**: Make sure your XML is well-formed before importing
4. **Backup First**: Always export before making major changes
5. **Version Control**: Keep XML files in Git for easy tracking

---

## 🔄 Typical Workflow

1. **Create Course** → Basic info (title, description, etc.)
2. **Manage Content** → Click folder icon
3. **Export XML** → Get current structure (or use template)
4. **Edit XML** → Add/modify modules and lessons
5. **Import XML** → Load your changes
6. **Save** → Update the course
7. **Publish** → Make it visible to students

---

## 📚 Full Documentation

See `XML_COURSE_GUIDE.md` for complete documentation including:
- Detailed XML structure
- All attributes and elements
- Validation rules
- Troubleshooting
- Best practices

---

## ✅ That's It!

You can now manage all your course content through XML files! 🎉

