import 'package:cloud_firestore/cloud_firestore.dart';

// Модель для учебного элемента остается такой же, как вы предоставили
class LearningItem {
  final String id;
  final String itemType;
  final String russianText;
  final String targetText;
  final String? targetAudioUrl;
  final String? targetTranscription;
  final String? imageUrl; // Image specific to this item
  final String? notesForAdmin;
  final int orderIndex;

  LearningItem({
    required this.id,
    required this.itemType,
    required this.russianText,
    required this.targetText,
    this.targetAudioUrl,
    this.targetTranscription,
    this.imageUrl,
    this.notesForAdmin,
    required this.orderIndex,
  });

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    return LearningItem(
      id: json['id'] as String,
      itemType: json['item_type'] as String,
      russianText: json['russian_text'] as String,
      targetText: json['target_text'] as String,
      targetAudioUrl: json['target_audio_url'] as String?,
      targetTranscription: json['target_transcription'] as String?,
      imageUrl: json['image_url'] as String?,
      notesForAdmin: json['notes_for_admin'] as String?,
      orderIndex: (json['order_index'] ?? 0) as int,
    );
  }

   Map<String, dynamic> toJson() => {
        'id': id,
        'item_type': itemType,
        'russian_text': russianText,
        'target_text': targetText,
        'target_audio_url': targetAudioUrl,
        'target_transcription': targetTranscription,
        'image_url': imageUrl,
        'notes_for_admin': notesForAdmin,
        'order_index': orderIndex,
      };
}

class LearningModule {
  final String id; // Renamed from moduleId for clarity, represents document ID
  final String titleRu;
  final String targetLanguage;
  final String level;
  final bool isPublished;
  final Timestamp createdAt;
  final Timestamp? updatedAt; // Added for completeness
  final String? authorId;     // Added for completeness

  // Fields from the original "module" structure
  final String? topicIcon;
  final String? descriptionRu;
  final List<LearningItem> learningItems; // Will be empty for new content structure

  // Fields from the new "content" structure
  final String? contentImageUrl;    // Top-level image for the module/content
  final String? textContent;        // Top-level text content
  final String? translationNotes;   // Top-level translation/notes

  LearningModule({
    required this.id,
    required this.titleRu,
    required this.targetLanguage,
    required this.level,
    required this.isPublished,
    required this.createdAt,
    this.updatedAt,
    this.authorId,
    this.topicIcon,
    this.descriptionRu,
    this.learningItems = const [], // Default to empty list
    this.contentImageUrl,
    this.textContent,
    this.translationNotes,
  });

  factory LearningModule.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for LearningModule ${snapshot.id}');
    }

    // Handle learningItems (from old structure)
    final itemsData = data['learning_items'] as List<dynamic>? ?? [];
    final List<LearningItem> parsedLearningItems = itemsData
        .map((itemData) => LearningItem.fromJson(itemData as Map<String, dynamic>))
        .toList();
    parsedLearningItems.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return LearningModule(
      id: snapshot.id, // Use document ID as the unique identifier for the module/content
      
      // Title: prioritize new 'topic_name', then old 'title_ru'
      titleRu: data['topic_name'] as String? ?? data['title_ru'] as String? ?? 'Без названия',
      
      targetLanguage: data['target_language'] as String? ?? 'unknown',
      level: data['level'] as String? ?? 'unknown',
      isPublished: (data['is_published'] ?? false) as bool,
      createdAt: (data['created_at'] ?? Timestamp.now()) as Timestamp,
      updatedAt: data['updated_at'] as Timestamp?,
      authorId: data['author_id'] as String?,

      // Fields primarily from the old structure
      topicIcon: data['topic_icon'] as String?,
      descriptionRu: data['description_ru'] as String?,
      learningItems: parsedLearningItems,

      // Fields primarily from the new "content" structure
      // Note: 'image_url' at the top level of the document corresponds to 'contentImageUrl'
      contentImageUrl: data['image_url'] as String?,
      textContent: data['text_content'] as String?,
      translationNotes: data['translation_notes'] as String?,
    );
  }
}