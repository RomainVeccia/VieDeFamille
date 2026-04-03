import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/core/models/member.dart';

void main() {
  group('Member', () {
    late Member member;

    setUp(() {
      member = Member(
        id: 'romain',
        name: 'Romain',
        avatarIndex: 0,
        status: 'Papa',
        birthday: DateTime(1990, 6, 15),
        colorIndex: 0,
        points: 150,
        totalPointsEarned: 300,
        createdAt: DateTime(2026, 1, 1),
      );
    });

    group('age', () {
      test('should calculate age correctly for a past birthday this year', () {
        final now = DateTime.now();
        // Born exactly 30 years ago on Jan 1
        final m = Member(
          id: 'test',
          name: 'Test',
          avatarIndex: 0,
          status: 'Test',
          birthday: DateTime(now.year - 30, 1, 1),
          colorIndex: 0,
          createdAt: now,
        );

        // Age should be 30 since Jan 1 has already passed (or is today)
        expect(m.age, greaterThanOrEqualTo(30));
      });

      test('should subtract one year if birthday has not occurred yet', () {
        final now = DateTime.now();
        // Born on Dec 31 of (now.year - 20) — birthday not yet passed
        // unless today IS Dec 31
        final futureBirthday =
            DateTime(now.year - 20, 12, 31);
        final m = Member(
          id: 'test',
          name: 'Test',
          avatarIndex: 0,
          status: 'Test',
          birthday: futureBirthday,
          colorIndex: 0,
          createdAt: now,
        );

        // If today is before Dec 31, age should be 19; if today is Dec 31, age should be 20
        if (now.month < 12 || (now.month == 12 && now.day < 31)) {
          expect(m.age, equals(19));
        } else {
          expect(m.age, equals(20));
        }
      });

      test('should handle children age correctly', () {
        final now = DateTime.now();
        final child = Member(
          id: 'child',
          name: 'Child',
          avatarIndex: 0,
          status: 'Fils',
          birthday: DateTime(now.year - 9, now.month, now.day),
          colorIndex: 0,
          createdAt: now,
        );

        expect(child.age, equals(9));
      });
    });

    group('nextBirthday', () {
      test('should return next year if birthday already passed this year', () {
        final now = DateTime.now();
        // Birthday on Jan 1 — already passed (unless today is Jan 1)
        final m = Member(
          id: 'test',
          name: 'Test',
          avatarIndex: 0,
          status: 'Test',
          birthday: DateTime(1990, 1, 1),
          colorIndex: 0,
          createdAt: now,
        );

        final next = m.nextBirthday;
        // Should be Jan 1 of next year (or this year if today is before Jan 1,
        // which can't happen)
        if (now.month == 1 && now.day == 1) {
          // Today IS the birthday — nextBirthday goes to next year
          expect(next.year, equals(now.year + 1));
        } else {
          expect(next.year, equals(now.year + 1));
        }
        expect(next.month, equals(1));
        expect(next.day, equals(1));
      });

      test('should return this year if birthday has not occurred yet', () {
        final now = DateTime.now();
        // Birthday on Dec 31 — hasn't passed yet (unless today is Dec 31)
        final m = Member(
          id: 'test',
          name: 'Test',
          avatarIndex: 0,
          status: 'Test',
          birthday: DateTime(1990, 12, 31),
          colorIndex: 0,
          createdAt: now,
        );

        final next = m.nextBirthday;
        if (now.month == 12 && now.day == 31) {
          expect(next.year, equals(now.year + 1));
        } else {
          expect(next.year, equals(now.year));
        }
        expect(next.month, equals(12));
        expect(next.day, equals(31));
      });

      test('should always return a date in the future', () {
        final next = member.nextBirthday;
        expect(next.isAfter(DateTime.now()), isTrue);
      });
    });

    group('copyWith', () {
      test('should update only specified fields', () {
        final updated = member.copyWith(
          name: 'Romano',
          points: 200,
        );

        expect(updated.name, equals('Romano'));
        expect(updated.points, equals(200));
        expect(updated.id, equals(member.id));
        expect(updated.status, equals(member.status));
        expect(updated.birthday, equals(member.birthday));
        expect(updated.totalPointsEarned, equals(member.totalPointsEarned));
      });
    });

    group('JSON serialization', () {
      test('should roundtrip through toJson and fromJson', () {
        final json = member.toJson();
        final restored = Member.fromJson(json);

        expect(restored.id, equals(member.id));
        expect(restored.name, equals(member.name));
        expect(restored.avatarIndex, equals(member.avatarIndex));
        expect(restored.status, equals(member.status));
        expect(restored.birthday, equals(member.birthday));
        expect(restored.colorIndex, equals(member.colorIndex));
        expect(restored.points, equals(member.points));
        expect(restored.totalPointsEarned, equals(member.totalPointsEarned));
        expect(restored.createdAt, equals(member.createdAt));
      });

      test('should handle null photoPath', () {
        expect(member.photoPath, isNull);
        final json = member.toJson();
        final restored = Member.fromJson(json);
        expect(restored.photoPath, isNull);
      });

      test('should handle default points when missing from JSON', () {
        final json = <String, dynamic>{
          'id': 'test',
          'name': 'Test',
          'avatarIndex': 0,
          'status': 'Test',
          'birthday': '2000-01-01T00:00:00.000',
          'colorIndex': 0,
          'createdAt': '2026-01-01T00:00:00.000',
        };

        final restored = Member.fromJson(json);
        expect(restored.points, equals(0));
        expect(restored.totalPointsEarned, equals(0));
      });
    });

    group('create factory', () {
      test('should generate UUID and set defaults', () {
        final created = Member.create(
          name: 'New Member',
          status: 'Enfant',
          birthday: DateTime(2018, 5, 10),
        );

        expect(created.id, isNotEmpty);
        expect(created.name, equals('New Member'));
        expect(created.status, equals('Enfant'));
        expect(created.points, equals(0));
        expect(created.totalPointsEarned, equals(0));
        expect(created.createdAt.difference(DateTime.now()).inSeconds.abs(),
            lessThan(2));
      });
    });
  });
}
