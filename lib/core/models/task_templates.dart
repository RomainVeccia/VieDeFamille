import 'package:vie_de_famille/core/models/family_task.dart';

/// Template de tâche pré-remplie (pas encore créée en BDD)
class TaskTemplate {
  final String title;
  final String emoji;
  final TaskCategory category;
  final TaskRecurrence recurrence;
  final int pointsValue;

  const TaskTemplate({
    required this.title,
    required this.emoji,
    required this.category,
    required this.recurrence,
    required this.pointsValue,
  });
}

/// Toutes les tâches pré-remplies, organisées par catégorie et fréquence
class TaskTemplates {
  TaskTemplates._();

  // ===== POULES 🐔 =====
  static const poulesDaily = [
    TaskTemplate(
      title: 'Donner à manger aux poules (matin)',
      emoji: '🐔',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Vérifier/remplir l\'eau des poules',
      emoji: '💧',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Ramasser les œufs',
      emoji: '🥚',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Fermer le poulailler (soir)',
      emoji: '🔒',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
  ];

  static const poulesWeekly = [
    TaskTemplate(
      title: 'Nettoyer les mangeoires et abreuvoirs',
      emoji: '🧹',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 15,
    ),
    TaskTemplate(
      title: 'Ajouter de la paille propre',
      emoji: '🌾',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 15,
    ),
    TaskTemplate(
      title: 'Vérifier l\'enclos (rien de cassé)',
      emoji: '🔍',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
  ];

  static const poulesMonthly = [
    TaskTemplate(
      title: 'Grand nettoyage du poulailler',
      emoji: '🧽',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 30,
    ),
    TaskTemplate(
      title: 'Vérifier les stocks de grains',
      emoji: '📦',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Inspecter le grillage de l\'enclos',
      emoji: '🔧',
      category: TaskCategory.poules,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 15,
    ),
  ];

  // ===== CHAT 🐱 =====
  static const chatDaily = [
    TaskTemplate(
      title: 'Donner à manger au chat (matin)',
      emoji: '🐱',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Donner à manger au chat (soir)',
      emoji: '🐱',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Vérifier/remplir l\'eau du chat',
      emoji: '💧',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Nettoyer la litière',
      emoji: '🪣',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
  ];

  static const chatWeekly = [
    TaskTemplate(
      title: 'Changer toute la litière',
      emoji: '♻️',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 15,
    ),
    TaskTemplate(
      title: 'Brosser le chat',
      emoji: '✨',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Vérifier stocks croquettes',
      emoji: '📦',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 5,
    ),
  ];

  static const chatMonthly = [
    TaskTemplate(
      title: 'Laver les gamelles en profondeur',
      emoji: '🧼',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 15,
    ),
    TaskTemplate(
      title: 'Vérifier vermifuge / anti-puces',
      emoji: '💊',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Nettoyer le bac à litière en profondeur',
      emoji: '🧽',
      category: TaskCategory.chat,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 20,
    ),
  ];

  // ===== CHAMBRE 🛏️ =====
  static const chambreDaily = [
    TaskTemplate(
      title: 'Faire son lit',
      emoji: '🛏️',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Ranger les vêtements',
      emoji: '👕',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Ranger le bureau / affaires d\'école',
      emoji: '📚',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
  ];

  static const chambreWeekly = [
    TaskTemplate(
      title: 'Passer l\'aspirateur dans sa chambre',
      emoji: '🧹',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 15,
    ),
    TaskTemplate(
      title: 'Changer les draps',
      emoji: '🛏️',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 15,
    ),
    TaskTemplate(
      title: 'Ranger et trier le bureau',
      emoji: '🗂️',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Ranger le linge propre',
      emoji: '👔',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
  ];

  static const chambreMonthly = [
    TaskTemplate(
      title: 'Tri des affaires (donner / jeter)',
      emoji: '📦',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 30,
    ),
    TaskTemplate(
      title: 'Nettoyer les vitres de sa chambre',
      emoji: '🪟',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 20,
    ),
    TaskTemplate(
      title: 'Ranger sous le lit et dans les placards',
      emoji: '🔦',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 20,
    ),
    TaskTemplate(
      title: 'Dépoussiérer les étagères',
      emoji: '✨',
      category: TaskCategory.chambre,
      recurrence: TaskRecurrence.monthly,
      pointsValue: 15,
    ),
  ];

  // ===== MAISON 🏠 =====
  static const maisonDaily = [
    TaskTemplate(
      title: 'Débarrasser la table après le repas',
      emoji: '🍽️',
      category: TaskCategory.maison,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Mettre le linge sale dans le panier',
      emoji: '🧺',
      category: TaskCategory.maison,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
  ];

  static const maisonWeekly = [
    TaskTemplate(
      title: 'Aider à passer l\'aspirateur (salon)',
      emoji: '🧹',
      category: TaskCategory.maison,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 15,
    ),
    TaskTemplate(
      title: 'Sortir les poubelles / tri sélectif',
      emoji: '🗑️',
      category: TaskCategory.maison,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Aider à ranger les courses',
      emoji: '🛒',
      category: TaskCategory.maison,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
  ];

  // ===== TÂCHES ENFANTS ⭐ =====
  static const enfantsDaily = [
    TaskTemplate(
      title: 'Ranger sa chambre',
      emoji: '🛏️',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.daily,
      pointsValue: 20,
    ),
    TaskTemplate(
      title: 'Mettre la table',
      emoji: '🍽️',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
    TaskTemplate(
      title: 'Vider le lave-vaisselle',
      emoji: '🫧',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.daily,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Débarrasser la table, tout rincer, mettre dans le lave-vaisselle, ranger au frigo, passer l\'éponge',
      emoji: '✨',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.daily,
      pointsValue: 30,
    ),
    TaskTemplate(
      title: 'Sortir la poubelle',
      emoji: '🗑️',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.daily,
      pointsValue: 5,
    ),
  ];

  static const enfantsWeekly = [
    TaskTemplate(
      title: 'Étendre le linge parfaitement',
      emoji: '👕',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 15,
    ),
    TaskTemplate(
      title: 'Plier le linge parfaitement et le ranger dans les placards',
      emoji: '👔',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 30,
    ),
    TaskTemplate(
      title: 'Nettoyer la salle de bain (en surface)',
      emoji: '🚿',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 25,
    ),
    TaskTemplate(
      title: 'Nettoyer la salle de bain (à fond)',
      emoji: '🧽',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 50,
    ),
    TaskTemplate(
      title: 'Passer l\'aspirateur (1 étage)',
      emoji: '🧹',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Faire les poussières',
      emoji: '✨',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Ranger le salon',
      emoji: '🛋️',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Une tâche de jardinage',
      emoji: '🌿',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
    TaskTemplate(
      title: 'Nettoyer la voiture',
      emoji: '🚗',
      category: TaskCategory.enfants,
      recurrence: TaskRecurrence.weekly,
      pointsValue: 10,
    ),
  ];

  /// Toutes les catégories avec leur label et icône
  static const categories = {
    TaskCategory.enfants: ('Tâches Enfants', '⭐'),
    TaskCategory.poules: ('Les Poules', '🐔'),
    TaskCategory.chat: ('Le Chat', '🐱'),
    TaskCategory.chambre: ('Ma Chambre', '🛏️'),
    TaskCategory.maison: ('La Maison', '🏠'),
  };

  /// Retourne tous les templates d'une catégorie
  static List<TaskTemplate> forCategory(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.poules:
        return [...poulesDaily, ...poulesWeekly, ...poulesMonthly];
      case TaskCategory.chat:
        return [...chatDaily, ...chatWeekly, ...chatMonthly];
      case TaskCategory.chambre:
        return [...chambreDaily, ...chambreWeekly, ...chambreMonthly];
      case TaskCategory.maison:
        return [...maisonDaily, ...maisonWeekly];
      case TaskCategory.enfants:
        return [...enfantsDaily, ...enfantsWeekly];
      case TaskCategory.general:
        return [];
    }
  }

  /// Label pour la récurrence
  static String recurrenceLabel(TaskRecurrence r) {
    switch (r) {
      case TaskRecurrence.daily:
        return 'Tous les jours';
      case TaskRecurrence.weekly:
        return 'Chaque semaine';
      case TaskRecurrence.monthly:
        return 'Chaque mois';
      case TaskRecurrence.none:
        return 'Une fois';
    }
  }
}
