import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/models/family_task.dart';
import 'package:vie_de_famille/core/models/family_message.dart';
import 'package:vie_de_famille/core/models/family_event.dart';
import 'package:vie_de_famille/core/models/avatars.dart';
import 'package:vie_de_famille/core/services/task_service.dart';
import 'package:vie_de_famille/core/services/points_service.dart';

void main() {
  // === TEST 1 : Création de membres ===
  group('Membres', () {
    test('créer un membre avec tous les champs', () {
      final member = Member.create(
        name: 'Romano',
        status: 'Papa',
        birthday: DateTime(1990, 5, 15),
        avatarIndex: 0,
        colorIndex: 0,
      );

      expect(member.name, 'Romano');
      expect(member.status, 'Papa');
      expect(member.age, greaterThanOrEqualTo(35));
      expect(member.points, 0);
      expect(member.id, isNotEmpty);
    });

    test('copyWith met à jour les points', () {
      final member = Member.create(
        name: 'Marie',
        status: 'Maman',
        birthday: DateTime(1992, 3, 10),
      );
      final updated = member.copyWith(points: 50, totalPointsEarned: 50);

      expect(updated.points, 50);
      expect(updated.totalPointsEarned, 50);
      expect(updated.name, 'Marie'); // inchangé
    });

    test('serialisation JSON aller-retour', () {
      final member = Member.create(
        name: 'Léo',
        status: 'Fils',
        birthday: DateTime(2015, 8, 20),
        avatarIndex: 3,
        colorIndex: 2,
      );
      final json = member.toJson();
      final restored = Member.fromJson(json);

      expect(restored.name, member.name);
      expect(restored.status, member.status);
      expect(restored.avatarIndex, member.avatarIndex);
      expect(restored.colorIndex, member.colorIndex);
      expect(restored.id, member.id);
    });
  });

  // === TEST 2 : Avatars ===
  group('Avatars', () {
    test('16 emojis disponibles', () {
      expect(FamilyAvatars.emojis.length, 16);
    });

    test('get wraps autour de la liste', () {
      expect(FamilyAvatars.get(0), FamilyAvatars.get(16));
      expect(FamilyAvatars.get(1), FamilyAvatars.get(17));
    });
  });

  // === TEST 3 : Tâches ===
  group('Tâches', () {
    test('créer une tâche avec valeurs par défaut', () {
      final task = FamilyTask.create(
        title: 'Sortir les poubelles',
        createdBy: 'member-1',
      );

      expect(task.title, 'Sortir les poubelles');
      expect(task.completed, false);
      expect(task.pointsValue, 10);
      expect(task.priority, TaskPriority.medium);
    });

    test('compléter une tâche', () {
      final task = FamilyTask.create(
        title: 'Faire la vaisselle',
        createdBy: 'member-1',
        assignedTo: 'member-2',
        pointsValue: 20,
      );
      final completed = task.complete();

      expect(completed.completed, true);
      expect(completed.completedAt, isNotNull);
      expect(completed.pointsValue, 20);
    });

    test('décocher une tâche', () {
      final task = FamilyTask.create(
        title: 'Test',
        createdBy: 'member-1',
      ).complete();
      final uncompleted = task.uncomplete();

      expect(uncompleted.completed, false);
      expect(uncompleted.completedAt, isNull);
    });

    test('tâche en retard', () {
      final overdue = FamilyTask.create(
        title: 'En retard',
        createdBy: 'member-1',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(overdue.isOverdue, true);

      final future = FamilyTask.create(
        title: 'Future',
        createdBy: 'member-1',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(future.isOverdue, false);
    });

    test('serialisation JSON aller-retour', () {
      final task = FamilyTask.create(
        title: 'Test JSON',
        createdBy: 'member-1',
        assignedTo: 'member-2',
        priority: TaskPriority.high,
        pointsValue: 30,
      );
      final json = task.toJson();
      final restored = FamilyTask.fromJson(json);

      expect(restored.title, task.title);
      expect(restored.assignedTo, task.assignedTo);
      expect(restored.priority, TaskPriority.high);
      expect(restored.pointsValue, 30);
    });
  });

  // === TEST 4 : TaskService ===
  group('TaskService', () {
    final tasks = [
      FamilyTask.create(
        title: 'Tâche 1',
        createdBy: 'a',
        assignedTo: 'a',
      ),
      FamilyTask.create(
        title: 'Tâche 2',
        createdBy: 'a',
        assignedTo: 'b',
      ),
      FamilyTask.create(
        title: 'Tâche 3',
        createdBy: 'b',
        assignedTo: 'a',
      ).complete(),
    ];

    test('pending retourne les tâches non complétées', () {
      expect(TaskService.pending(tasks).length, 2);
    });

    test('forMember filtre par assigné', () {
      expect(TaskService.forMember(tasks, 'a').length, 2);
      expect(TaskService.forMember(tasks, 'b').length, 1);
    });

    test('completedToday retourne les tâches complétées aujourd\'hui', () {
      final completed = TaskService.completedToday(tasks);
      expect(completed.length, 1);
      expect(completed.first.title, 'Tâche 3');
    });
  });

  // === TEST 5 : Messages ===
  group('Messages', () {
    test('créer un message', () {
      final msg = FamilyMessage.create(
        authorId: 'member-1',
        content: 'Qui fait les courses ?',
        type: MessageType.idea,
      );

      expect(msg.content, 'Qui fait les courses ?');
      expect(msg.type, MessageType.idea);
      expect(msg.pinned, false);
    });

    test('épingler un message', () {
      final msg = FamilyMessage.create(
        authorId: 'member-1',
        content: 'Important !',
        type: MessageType.announcement,
      );
      final pinned = msg.copyWith(pinned: true);

      expect(pinned.pinned, true);
      expect(pinned.content, 'Important !');
    });

    test('serialisation JSON', () {
      final msg = FamilyMessage.create(
        authorId: 'x',
        content: 'Hello',
      );
      final restored = FamilyMessage.fromJson(msg.toJson());
      expect(restored.content, 'Hello');
      expect(restored.id, msg.id);
    });
  });

  // === TEST 6 : Événements ===
  group('Événements', () {
    test('créer un événement', () {
      final event = FamilyEvent.create(
        title: 'Anniversaire Marie',
        dateStart: DateTime(2026, 6, 15, 14, 0),
        allDay: false,
        createdBy: 'member-1',
        participantIds: ['member-1', 'member-2'],
      );

      expect(event.title, 'Anniversaire Marie');
      expect(event.participantIds.length, 2);
      expect(event.allDay, false);
    });

    test('isOnDay vérifie correctement le jour', () {
      final event = FamilyEvent.create(
        title: 'Test',
        dateStart: DateTime(2026, 3, 23, 10, 0),
        createdBy: 'a',
      );

      expect(event.isOnDay(DateTime(2026, 3, 23)), true);
      expect(event.isOnDay(DateTime(2026, 3, 24)), false);
      expect(event.isOnDay(DateTime(2026, 3, 22)), false);
    });

    test('événement multi-jours', () {
      final event = FamilyEvent.create(
        title: 'Vacances',
        dateStart: DateTime(2026, 7, 1),
        createdBy: 'a',
      );
      final multi = event.copyWith(
        dateEnd: DateTime(2026, 7, 5),
      );

      expect(multi.isOnDay(DateTime(2026, 7, 1)), true);
      expect(multi.isOnDay(DateTime(2026, 7, 3)), true);
      expect(multi.isOnDay(DateTime(2026, 7, 5)), true);
      expect(multi.isOnDay(DateTime(2026, 7, 6)), false);
    });

    test('serialisation JSON', () {
      final event = FamilyEvent.create(
        title: 'Test JSON',
        dateStart: DateTime(2026, 1, 1),
        createdBy: 'a',
        participantIds: ['a', 'b'],
      );
      final restored = FamilyEvent.fromJson(event.toJson());
      expect(restored.title, 'Test JSON');
      expect(restored.participantIds.length, 2);
    });
  });

  // === TEST 7 : Gamification / Points ===
  group('PointsService', () {
    test('titres selon les points', () {
      expect(PointsService.title(0), contains('Nouveau'));
      expect(PointsService.title(10), contains('Débutant'));
      expect(PointsService.title(50), contains('En forme'));
      expect(PointsService.title(100), contains('Motivé'));
      expect(PointsService.title(200), contains('Pro'));
      expect(PointsService.title(500), contains('Champion'));
      expect(PointsService.title(1000), contains('Super Star'));
    });

    test('ranking trie par points décroissants', () {
      final members = [
        Member.create(name: 'A', status: '', birthday: DateTime(2000, 1, 1))
            .copyWith(totalPointsEarned: 10),
        Member.create(name: 'B', status: '', birthday: DateTime(2000, 1, 1))
            .copyWith(totalPointsEarned: 100),
        Member.create(name: 'C', status: '', birthday: DateTime(2000, 1, 1))
            .copyWith(totalPointsEarned: 50),
      ];
      final ranked = PointsService.ranking(members);

      expect(ranked[0].name, 'B');
      expect(ranked[1].name, 'C');
      expect(ranked[2].name, 'A');
    });

    test('progression entre paliers', () {
      expect(PointsService.progress(0), 0.0);
      expect(PointsService.progress(5), 0.5);
      expect(PointsService.progress(1000), 1.0);
      expect(PointsService.progress(250), greaterThan(0.0));
    });
  });
}
