import 'package:flutter_test/flutter_test.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/services/points_service.dart';

void main() {
  group('PointsService', () {
    /// Helper to create a member with given points
    Member makeMember({
      required String id,
      required String name,
      int points = 0,
      int totalPointsEarned = 0,
    }) {
      return Member(
        id: id,
        name: name,
        avatarIndex: 0,
        status: 'Test',
        birthday: DateTime(2000, 1, 1),
        colorIndex: 0,
        points: points,
        totalPointsEarned: totalPointsEarned,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    group('ranking', () {
      test('should sort members by totalPointsEarned descending', () {
        final members = [
          makeMember(id: 'a', name: 'Alice', totalPointsEarned: 100),
          makeMember(id: 'b', name: 'Bob', totalPointsEarned: 500),
          makeMember(id: 'c', name: 'Charlie', totalPointsEarned: 250),
        ];

        final result = PointsService.ranking(members);

        expect(result[0].name, equals('Bob'));
        expect(result[1].name, equals('Charlie'));
        expect(result[2].name, equals('Alice'));
      });

      test('should not mutate the original list', () {
        final members = [
          makeMember(id: 'a', name: 'Alice', totalPointsEarned: 100),
          makeMember(id: 'b', name: 'Bob', totalPointsEarned: 500),
        ];

        PointsService.ranking(members);

        // Original list order preserved
        expect(members[0].name, equals('Alice'));
        expect(members[1].name, equals('Bob'));
      });

      test('should handle empty list', () {
        final result = PointsService.ranking([]);
        expect(result, isEmpty);
      });

      test('should handle single member', () {
        final members = [
          makeMember(id: 'a', name: 'Alice', totalPointsEarned: 50),
        ];

        final result = PointsService.ranking(members);
        expect(result.length, equals(1));
      });
    });

    group('title', () {
      test('should return correct title for each threshold', () {
        expect(PointsService.title(0), contains('Nouveau'));
        expect(PointsService.title(5), contains('Nouveau'));
        expect(PointsService.title(10), contains('butant'));
        expect(PointsService.title(49), contains('butant'));
        expect(PointsService.title(50), contains('forme'));
        expect(PointsService.title(99), contains('forme'));
        expect(PointsService.title(100), contains('Motiv'));
        expect(PointsService.title(199), contains('Motiv'));
        expect(PointsService.title(200), contains('Pro'));
        expect(PointsService.title(499), contains('Pro'));
        expect(PointsService.title(500), contains('Champion'));
        expect(PointsService.title(999), contains('Champion'));
        expect(PointsService.title(1000), contains('Super Star'));
        expect(PointsService.title(5000), contains('Super Star'));
      });
    });

    group('nextMilestone', () {
      test('should return correct next milestone for each tier', () {
        expect(PointsService.nextMilestone(0), equals(10));
        expect(PointsService.nextMilestone(5), equals(10));
        expect(PointsService.nextMilestone(10), equals(50));
        expect(PointsService.nextMilestone(49), equals(50));
        expect(PointsService.nextMilestone(50), equals(100));
        expect(PointsService.nextMilestone(99), equals(100));
        expect(PointsService.nextMilestone(100), equals(200));
        expect(PointsService.nextMilestone(200), equals(500));
        expect(PointsService.nextMilestone(500), equals(1000));
        expect(PointsService.nextMilestone(1000), equals(1000)); // max
        expect(PointsService.nextMilestone(2000), equals(1000)); // max
      });
    });

    group('progress', () {
      test('should return 0.0 for 0 points', () {
        expect(PointsService.progress(0), equals(0.0));
      });

      test('should return 1.0 at max tier', () {
        expect(PointsService.progress(1000), equals(1.0));
        expect(PointsService.progress(2000), equals(1.0));
      });

      test('should return 0.5 at midpoint of a tier', () {
        // Tier 0-10: midpoint at 5
        expect(PointsService.progress(5), equals(0.5));
      });

      test('should return value between 0 and 1 within a tier', () {
        // Tier 10-50: 30 points = (30-10)/(50-10) = 20/40 = 0.5
        expect(PointsService.progress(30), equals(0.5));
      });

      test('should return 1.0 at the boundary of a tier', () {
        // At 10 points: next milestone is 50, previous is 10
        // But 10 >= 10 so previous = 10... wait, let me trace the logic
        // For 10: next = 50, loop: 0 >= 50? no... 0 < 50 and 10 >= 0 -> prev=0
        // then 10 < 50 and 10 >= 10 -> prev=10. range = 50-10=40, (10-10)/40=0.0
        expect(PointsService.progress(10), equals(0.0));
      });

      test('should increase monotonically within a tier', () {
        final p25 = PointsService.progress(25);
        final p35 = PointsService.progress(35);
        final p45 = PointsService.progress(45);

        expect(p25, lessThan(p35));
        expect(p35, lessThan(p45));
      });
    });
  });
}
