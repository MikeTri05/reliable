import 'package:flutter_test/flutter_test.dart';
import 'package:reliable_emergency_donor/core/utils/event_image_storage.dart';

void main() {
  group('EventImageStorage', () {
    test('allows only supported image formats', () {
      expect(EventImageStorage.isAllowedImagePath('poster.JPG'), isTrue);
      expect(EventImageStorage.isAllowedImagePath('poster.jpeg'), isTrue);
      expect(EventImageStorage.isAllowedImagePath('poster.png'), isTrue);
      expect(EventImageStorage.isAllowedImagePath('poster.webp'), isTrue);
      expect(EventImageStorage.isAllowedImagePath('poster.gif'), isFalse);
      expect(EventImageStorage.isAllowedImagePath('poster.pdf'), isFalse);
    });

    test('builds public Google Cloud Storage URL for poster path', () {
      final url = EventImageStorage.publicUrlForPath(
        'poster_acara/poster donor.png',
      );

      expect(
        url,
        'https://storage.googleapis.com/donor-pmi-nias.firebasestorage.app/poster_acara/poster%20donor.png',
      );
    });
  });
}
