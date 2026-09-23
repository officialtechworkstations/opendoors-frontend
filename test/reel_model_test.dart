import 'package:flutter_test/flutter_test.dart';
import 'package:opendoors/model/reel.dart';

void main() {
  test('parses reel and nested property data', () {
    final reel = Reel.fromJson({
      'reel_id': 15,
      'prop_id': '42',
      'reel_status': 1,
      'video_url': 'https://example.com/reel.mp4',
      'thumbnail_url': 'https://example.com/thumb.jpg',
      'property': {
        'title': 'Cozy Apartment',
        'price': 1200,
        'beds': '2',
        'description': 'A bright apartment near the city center.',
        'owner_name': 'Grace Morgan',
        'owner_image': 'images/users/grace.jpg',
      },
    });

    expect(reel.id, '15');
    expect(reel.propertyId, '42');
    expect(reel.isReady, isTrue);
    expect(reel.property?.title, 'Cozy Apartment');
    expect(reel.property?.price, '1200');
    expect(
        reel.property?.description, 'A bright apartment near the city center.');
    expect(reel.property?.ownerName, 'Grace Morgan');
    expect(reel.property?.ownerImage, 'images/users/grace.jpg');
  });

  test('recognizes processing and failed reels', () {
    final processing = Reel.fromJson({
      'reel_id': '1',
      'prop_id': '2',
      'reel_status': '0',
    });
    final failed = Reel.fromJson({
      'reel_id': '1',
      'prop_id': '2',
      'reel_status': 2,
      'processing_error': 'Transcoding failed',
    });

    expect(processing.isProcessing, isTrue);
    expect(failed.hasFailed, isTrue);
    expect(failed.processingError, 'Transcoding failed');
  });

  test('parses property coordinates for nearby reels', () {
    final reel = Reel.fromJson({
      'reel_id': '8',
      'prop_id': '3',
      'reel_status': '1',
      'property': {'latitude': '6.5244', 'longtitude': '3.3792'},
    });
    expect(reel.property?.latitude, 6.5244);
    expect(reel.property?.longitude, 3.3792);
  });

  test('parses reel owner details from nested property data', () {
    final reel = Reel.fromJson({
      'reel_id': '9',
      'prop_id': '4',
      'reel_status': 1,
      'property': {
        'title': 'Owner listing',
        'owner_name': 'Amina Yusuf',
        'owner_image': 'images/users/amina.jpg',
      },
    });

    expect(reel.ownerName, 'Amina Yusuf');
    expect(reel.ownerImage, 'images/users/amina.jpg');
  });

  test('extracts a property image path from image records', () {
    final reel = Reel.fromJson({
      'reel_id': '10',
      'prop_id': '5',
      'reel_status': 1,
      'property': {
        'image': [
          {'image': 'images/property/6aa9097acba53.png', 'is_panorama': 0},
        ],
      },
    });

    expect(reel.property?.imageUrl, 'images/property/6aa9097acba53.png');
    expect(reel.ownerImage, isNull);
  });

  test('detects an unpublished property in reel data', () {
    final nested = Reel.fromJson({
      'reel_id': '11',
      'prop_id': '6',
      'reel_status': 1,
      'property': {'status': 0},
    });
    final topLevel = Reel.fromJson({
      'reel_id': '12',
      'prop_id': '7',
      'reel_status': 1,
      'property_status': '0',
    });

    expect(nested.isPropertyUnpublished, isTrue);
    expect(topLevel.isPropertyUnpublished, isTrue);
  });
}
