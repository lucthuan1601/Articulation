import 'package:flutter_test/flutter_test.dart';
import 'package:articulation/features/quality_assurance/domain/models/qa_diagnostics.dart';

void main() {
  group('Kiểm thử Quản lý chất lượng (Checklist 7 Alignment)', () {
    test('có đầy đủ 7 checklists theo bảng phân công README.md', () {
      final checklists = ChecklistStatus.getAllChecklists();
      expect(checklists.length, 7);

      final numbers = checklists.map((c) => c.number).toList();
      expect(numbers, [1, 2, 3, 4, 5, 6, 7]);
    });

    test('mỗi checklist đều có đầy đủ thông tin thành viên và trạng thái', () {
      final checklists = ChecklistStatus.getAllChecklists();

      for (final item in checklists) {
        expect(item.title.isNotEmpty, isTrue);
        expect(item.assignee.isNotEmpty, isTrue);
        expect(item.role.isNotEmpty, isTrue);
        expect(item.isCompleted, isTrue);
        expect(item.details.isNotEmpty, isTrue);
      }

      // Checklist 1: Lục Văn Thuận - CSDL
      expect(checklists[0].assignee, contains('Lục Văn Thuận'));
      expect(checklists[0].title, contains('cơ sở dữ liệu'));

      // Checklist 2: Nguyễn Khắc Minh Hiếu - Streak
      expect(checklists[1].assignee, contains('Minh Hiếu'));

      // Checklist 3: Hoàng Tùng - Thu âm Speech
      expect(checklists[2].assignee, contains('Hoàng Tùng'));

      // Checklist 4: Hoàng Tùng - Logic AI / Phonemes
      expect(checklists[3].assignee, contains('Hoàng Tùng'));

      // Checklist 5: Trần Văn Hồng Quân - UI/UX feedback
      expect(checklists[4].assignee, contains('Hồng Quân'));

      // Checklist 6: Nguyễn Khắc Minh Hiếu - Notification & Dashboard
      expect(checklists[5].assignee, contains('Minh Hiếu'));

      // Checklist 7: Lục Văn Thuận - QA & Multi-Device & Voice
      expect(checklists[6].assignee, contains('Lục Văn Thuận'));
      expect(checklists[6].title, contains('Quản lý chất lượng'));
    });
  });
}
