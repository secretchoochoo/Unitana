import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/data/city_label_utils.dart';

void main() {
  test('cleanCityName removes noisy leading punctuation', () {
    expect(CityLabelUtils.cleanCityName("'Ādamatā"), 'Ādamatā');
    expect(CityLabelUtils.cleanCityName('  ...Chicago'), 'Chicago');
  });

  test('cleanCityName title-cases all-caps labels', () {
    expect(CityLabelUtils.cleanCityName('NEW YORK'), 'New York');
  });
}
