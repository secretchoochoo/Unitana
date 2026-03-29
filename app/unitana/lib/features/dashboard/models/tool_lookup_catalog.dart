import 'package:flutter/foundation.dart';

import 'canonical_tools.dart';

class ToolLookupEntry {
  final String keyId;
  final String label;
  final Map<String, String> valuesBySystem;
  final String? note;
  final bool approximate;

  const ToolLookupEntry({
    required this.keyId,
    required this.label,
    required this.valuesBySystem,
    this.note,
    this.approximate = false,
  });
}

@immutable
class ToolLookupDefaults {
  final String fromSystem;
  final String toSystem;
  final String entryKey;

  const ToolLookupDefaults({
    required this.fromSystem,
    required this.toSystem,
    required this.entryKey,
  });
}

List<String> toolLookupSystemsFor(String canonicalToolId) {
  switch (canonicalToolId) {
    case CanonicalToolId.shoeSizes:
      return const <String>['US Men', 'US Women', 'EU', 'UK', 'AU', 'JP (cm)'];
    case CanonicalToolId.paperSizes:
      return const <String>['ISO', 'US', 'JIS', 'ANSI/ARCH'];
    case CanonicalToolId.clothingSizes:
      return const <String>['US', 'EU', 'UK', 'JP'];
    case CanonicalToolId.mattressSizes:
      return const <String>['US', 'EU', 'UK', 'AU', 'JP'];
    case CanonicalToolId.cupsGramsEstimates:
      return const <String>['Cup', 'Tbsp', 'Tsp', 'Weight'];
    default:
      return const <String>[];
  }
}

ToolLookupDefaults? toolLookupDefaultsFor(String canonicalToolId) {
  switch (canonicalToolId) {
    case CanonicalToolId.shoeSizes:
      return const ToolLookupDefaults(
        fromSystem: 'US Men',
        toSystem: 'EU',
        entryKey: 'shoe_9',
      );
    case CanonicalToolId.paperSizes:
      return const ToolLookupDefaults(
        fromSystem: 'ISO',
        toSystem: 'US',
        entryKey: 'paper_a4',
      );
    case CanonicalToolId.clothingSizes:
      return const ToolLookupDefaults(
        fromSystem: 'US',
        toSystem: 'EU',
        entryKey: 'cloth_w_tops_s',
      );
    case CanonicalToolId.mattressSizes:
      return const ToolLookupDefaults(
        fromSystem: 'US',
        toSystem: 'EU',
        entryKey: 'matt_queen',
      );
    case CanonicalToolId.cupsGramsEstimates:
      return const ToolLookupDefaults(
        fromSystem: 'Cup',
        toSystem: 'Weight',
        entryKey: 'cupsgrams_flour',
      );
    default:
      return null;
  }
}

bool toolLookupShouldPersistMatrixSelection(String canonicalToolId) {
  switch (canonicalToolId) {
    case CanonicalToolId.shoeSizes:
    case CanonicalToolId.clothingSizes:
    case CanonicalToolId.paperSizes:
    case CanonicalToolId.mattressSizes:
      return true;
    default:
      return false;
  }
}

String toolLookupReferenceLabel({
  required String canonicalToolId,
  required ToolLookupEntry row,
}) {
  return switch (canonicalToolId) {
    CanonicalToolId.shoeSizes => row.valuesBySystem['JP (cm)'] ?? row.label,
    CanonicalToolId.clothingSizes => row.label,
    CanonicalToolId.paperSizes => row.label,
    CanonicalToolId.mattressSizes => row.label,
    _ => row.label,
  };
}

String toolLookupReferenceHeader(String canonicalToolId) {
  return switch (canonicalToolId) {
    CanonicalToolId.shoeSizes => 'Foot (cm)',
    CanonicalToolId.clothingSizes => 'Category',
    _ => 'Reference',
  };
}

String toolLookupMatrixHeaderLabel({
  required String canonicalToolId,
  required String system,
}) {
  if (canonicalToolId != CanonicalToolId.shoeSizes) {
    return system;
  }
  return switch (system) {
    'US Men' => 'US M',
    'US Women' => 'US W',
    _ => system,
  };
}

List<String> toolLookupMatrixValueSystems(String canonicalToolId) {
  final systems = toolLookupSystemsFor(canonicalToolId);
  return canonicalToolId == CanonicalToolId.shoeSizes
      ? systems.where((s) => s != 'JP (cm)').toList(growable: false)
      : systems;
}

List<ToolLookupEntry> toolLookupEntriesFor(String canonicalToolId) {
  switch (canonicalToolId) {
    case CanonicalToolId.shoeSizes:
      return const <ToolLookupEntry>[
        ToolLookupEntry(
          keyId: 'shoe_2',
          label: '20.0',
          valuesBySystem: <String, String>{
            'US Men': '2',
            'US Women': '3.5',
            'EU': '34',
            'UK': '1',
            'AU': '1',
            'JP (cm)': '20.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_3',
          label: '21.0',
          valuesBySystem: <String, String>{
            'US Men': '3',
            'US Women': '4.5',
            'EU': '35',
            'UK': '2',
            'AU': '2',
            'JP (cm)': '21.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_4',
          label: '22.0',
          valuesBySystem: <String, String>{
            'US Men': '4',
            'US Women': '5.5',
            'EU': '36',
            'UK': '3.5',
            'AU': '3.5',
            'JP (cm)': '22.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_4_5',
          label: '22.5',
          valuesBySystem: <String, String>{
            'US Men': '4.5',
            'US Women': '6',
            'EU': '36.5',
            'UK': '4',
            'AU': '4',
            'JP (cm)': '22.5 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_5',
          label: '23.0',
          valuesBySystem: <String, String>{
            'US Men': '5',
            'US Women': '6.5',
            'EU': '37',
            'UK': '4.5',
            'AU': '4.5',
            'JP (cm)': '23.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_5_5',
          label: '23.5',
          valuesBySystem: <String, String>{
            'US Men': '5.5',
            'US Women': '7',
            'EU': '37.5',
            'UK': '5',
            'AU': '5',
            'JP (cm)': '23.5 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_6',
          label: '24.0',
          valuesBySystem: <String, String>{
            'US Men': '6',
            'US Women': '7.5',
            'EU': '38',
            'UK': '5.5',
            'AU': '5.5',
            'JP (cm)': '24.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_6_5',
          label: '24.5',
          valuesBySystem: <String, String>{
            'US Men': '6.5',
            'US Women': '8',
            'EU': '39',
            'UK': '5.5',
            'AU': '5.5',
            'JP (cm)': '24.5 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_7',
          label: '25.0',
          valuesBySystem: <String, String>{
            'US Men': '7',
            'US Women': '8.5',
            'EU': '40',
            'UK': '6',
            'AU': '6',
            'JP (cm)': '25.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_8',
          label: '26.0',
          valuesBySystem: <String, String>{
            'US Men': '8',
            'US Women': '9.5',
            'EU': '41',
            'UK': '7',
            'AU': '7',
            'JP (cm)': '26.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_9',
          label: '27.0',
          valuesBySystem: <String, String>{
            'US Men': '9',
            'US Women': '10.5',
            'EU': '42',
            'UK': '8',
            'AU': '8',
            'JP (cm)': '27.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_10',
          label: '28.0',
          valuesBySystem: <String, String>{
            'US Men': '10',
            'US Women': '11.5',
            'EU': '43',
            'UK': '9',
            'AU': '9',
            'JP (cm)': '28.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_11',
          label: '29.0',
          valuesBySystem: <String, String>{
            'US Men': '11',
            'US Women': '12.5',
            'EU': '44.5',
            'UK': '10',
            'AU': '10',
            'JP (cm)': '29.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_12',
          label: '30.0',
          valuesBySystem: <String, String>{
            'US Men': '12',
            'US Women': '13.5',
            'EU': '46',
            'UK': '11',
            'AU': '11',
            'JP (cm)': '30.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_13',
          label: '31.0',
          valuesBySystem: <String, String>{
            'US Men': '13',
            'US Women': '14.5',
            'EU': '47',
            'UK': '12',
            'AU': '12',
            'JP (cm)': '31.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_14',
          label: '32.0',
          valuesBySystem: <String, String>{
            'US Men': '14',
            'US Women': '15.5',
            'EU': '48',
            'UK': '13',
            'AU': '13',
            'JP (cm)': '32.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_14_5',
          label: '32.5',
          valuesBySystem: <String, String>{
            'US Men': '14.5',
            'US Women': '16',
            'EU': '49',
            'UK': '13.5',
            'AU': '13.5',
            'JP (cm)': '32.5 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_15',
          label: '33.0',
          valuesBySystem: <String, String>{
            'US Men': '15',
            'US Women': '16.5',
            'EU': '50',
            'UK': '14',
            'AU': '14',
            'JP (cm)': '33.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_16',
          label: '34.0',
          valuesBySystem: <String, String>{
            'US Men': '16',
            'US Women': '17.5',
            'EU': '51',
            'UK': '15',
            'AU': '15',
            'JP (cm)': '34.0 cm',
          },
        ),
        ToolLookupEntry(
          keyId: 'shoe_17',
          label: '35.0',
          valuesBySystem: <String, String>{
            'US Men': '17',
            'US Women': '18.5',
            'EU': '52',
            'UK': '16',
            'AU': '16',
            'JP (cm)': '35.0 cm',
          },
        ),
      ];
    case CanonicalToolId.clothingSizes:
      return const <ToolLookupEntry>[
        ToolLookupEntry(
          keyId: 'cloth_w_tops_xs',
          label: 'Women Tops • XS',
          valuesBySystem: <String, String>{
            'US': '2',
            'EU': '34',
            'UK': '6',
            'JP': '5',
          },
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cloth_w_tops_s',
          label: 'Women Tops • S',
          valuesBySystem: <String, String>{
            'US': '4-6',
            'EU': '36-38',
            'UK': '8-10',
            'JP': '7-9',
          },
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cloth_w_bottoms_6',
          label: 'Women Bottoms • US 6',
          valuesBySystem: <String, String>{
            'US': '6',
            'EU': '38',
            'UK': '10',
            'JP': '9',
          },
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cloth_w_bottoms_10',
          label: 'Women Bottoms • US 10',
          valuesBySystem: <String, String>{
            'US': '10',
            'EU': '42',
            'UK': '14',
            'JP': '13',
          },
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cloth_m_tops_m',
          label: 'Men Tops • M',
          valuesBySystem: <String, String>{
            'US': 'M',
            'EU': '48',
            'UK': 'M',
            'JP': 'L',
          },
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cloth_m_tops_l',
          label: 'Men Tops • L',
          valuesBySystem: <String, String>{
            'US': 'L',
            'EU': '50',
            'UK': 'L',
            'JP': 'LL',
          },
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cloth_m_bottoms_32',
          label: 'Men Bottoms • Waist 32',
          valuesBySystem: <String, String>{
            'US': '32',
            'EU': '48',
            'UK': '32',
            'JP': '82',
          },
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cloth_m_bottoms_34',
          label: 'Men Bottoms • Waist 34',
          valuesBySystem: <String, String>{
            'US': '34',
            'EU': '50',
            'UK': '34',
            'JP': '86',
          },
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cloth_outer_unisex_m',
          label: 'Outerwear (Unisex) • M',
          valuesBySystem: <String, String>{
            'US': 'M',
            'EU': '48',
            'UK': 'M',
            'JP': 'L',
          },
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cloth_outer_unisex_xl',
          label: 'Outerwear (Unisex) • XL',
          valuesBySystem: <String, String>{'US': 'XL', 'EU': '54', 'UK': 'XL'},
          note:
              'Approximate reference only • Source: public standards + retailer aggregate.',
          approximate: true,
        ),
      ];
    case CanonicalToolId.paperSizes:
      return const <ToolLookupEntry>[
        ToolLookupEntry(
          keyId: 'paper_a5',
          label: 'A5',
          valuesBySystem: <String, String>{
            'ISO': 'A5 (148 x 210 mm)',
            'US': 'Half Letter (5.5 x 8.5 in)',
            'JIS': 'B6 (128 x 182 mm)',
            'ANSI/ARCH': 'ANSI A (8.5 x 11 in)',
          },
          note: 'Closest common equivalents by region.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'paper_a4',
          label: 'A4',
          valuesBySystem: <String, String>{
            'ISO': 'A4 (210 x 297 mm)',
            'US': 'Letter (8.5 x 11 in)',
            'JIS': 'B5 (182 x 257 mm)',
            'ANSI/ARCH': 'ANSI A (8.5 x 11 in)',
          },
          note: 'Closest common equivalents by region.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'paper_a3',
          label: 'A3',
          valuesBySystem: <String, String>{
            'ISO': 'A3 (297 x 420 mm)',
            'US': 'Tabloid (11 x 17 in)',
            'JIS': 'B4 (257 x 364 mm)',
            'ANSI/ARCH': 'ANSI B (11 x 17 in)',
          },
          note: 'Closest common equivalents by region.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'paper_b5',
          label: 'B5',
          valuesBySystem: <String, String>{
            'ISO': 'B5 (176 x 250 mm)',
            'US': 'Statement (5.5 x 8.5 in)',
            'JIS': 'B5 (182 x 257 mm)',
            'ANSI/ARCH': 'ANSI A (8.5 x 11 in)',
          },
          note: 'ISO B-series and JIS B-series are different dimensions.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'paper_b4',
          label: 'B4',
          valuesBySystem: <String, String>{
            'ISO': 'B4 (250 x 353 mm)',
            'US': 'Legal (8.5 x 14 in)',
            'JIS': 'B4 (257 x 364 mm)',
            'ANSI/ARCH': 'ANSI B (11 x 17 in)',
          },
          note: 'ISO B-series and JIS B-series are different dimensions.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'paper_letter',
          label: 'Letter',
          valuesBySystem: <String, String>{
            'ISO': 'A4 (210 x 297 mm)',
            'US': '216 x 279 mm (8.5 x 11 in)',
            'JIS': 'B5 (182 x 257 mm)',
            'ANSI/ARCH': 'ANSI A (8.5 x 11 in)',
          },
          note: 'Closest common equivalents by region.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'paper_legal',
          label: 'Legal',
          valuesBySystem: <String, String>{
            'ISO': 'B4 (250 x 353 mm)',
            'US': '216 x 356 mm (8.5 x 14 in)',
            'JIS': 'B4 (257 x 364 mm)',
            'ANSI/ARCH': 'ANSI B (11 x 17 in)',
          },
          note: 'Closest common equivalents by region.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'paper_arch_d',
          label: 'ARCH D',
          valuesBySystem: <String, String>{
            'ISO': 'A1 (594 x 841 mm)',
            'US': 'ARCH D (24 x 36 in)',
            'JIS': 'B2 (515 x 728 mm)',
            'ANSI/ARCH': 'ARCH D (24 x 36 in)',
          },
          note: 'Architecture/engineering sheet equivalents.',
          approximate: true,
        ),
      ];
    case CanonicalToolId.mattressSizes:
      return const <ToolLookupEntry>[
        ToolLookupEntry(
          keyId: 'matt_twin',
          label: 'Twin',
          valuesBySystem: <String, String>{
            'US': 'Twin (38 x 75 in)',
            'EU': 'Single (90 x 200 cm)',
            'UK': 'Single (90 x 190 cm)',
            'AU': 'Single (92 x 188 cm)',
            'JP': 'Single (97 x 195 cm)',
          },
          note: 'Regional naming varies by vendor.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'matt_single_xl',
          label: 'Twin XL / Long Single',
          valuesBySystem: <String, String>{
            'US': 'Twin XL (38 x 80 in)',
            'EU': 'Single XL (90 x 210 cm)',
            'UK': 'Long Single (90 x 200 cm)',
            'AU': 'Long Single (92 x 203 cm)',
            'JP': 'Semi-double (120 x 195 cm)',
          },
          note: 'Useful for dorm and split-king setups.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'matt_full',
          label: 'Full / Double',
          valuesBySystem: <String, String>{
            'US': 'Full (54 x 75 in)',
            'EU': 'Double (140 x 200 cm)',
            'UK': 'Double (135 x 190 cm)',
            'AU': 'Double (138 x 188 cm)',
            'JP': 'Double (140 x 195 cm)',
          },
          note: 'Regional naming varies by vendor.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'matt_queen',
          label: 'Queen',
          valuesBySystem: <String, String>{
            'US': 'Queen (60 x 80 in)',
            'EU': 'King (160 x 200 cm)',
            'UK': 'King (150 x 200 cm)',
            'AU': 'Queen (153 x 203 cm)',
            'JP': 'Queen (160 x 195 cm)',
          },
          note: 'Approximate cross-region equivalent.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'matt_king',
          label: 'King',
          valuesBySystem: <String, String>{
            'US': 'King (76 x 80 in)',
            'EU': 'Super King (180 x 200 cm)',
            'UK': 'Super King (180 x 200 cm)',
            'AU': 'King (183 x 203 cm)',
            'JP': 'King (180 x 195 cm)',
          },
          note: 'Approximate cross-region equivalent.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'matt_super_king_us',
          label: 'California King',
          valuesBySystem: <String, String>{
            'US': 'California King (72 x 84 in)',
            'EU': 'Super King (180 x 210 cm)',
            'UK': 'Super King (180 x 200 cm)',
            'AU': 'Super King (203 x 203 cm)',
            'JP': 'Wide King (200 x 200 cm)',
          },
          note: 'Cross-region equivalence is approximate by shape and area.',
          approximate: true,
        ),
      ];
    case CanonicalToolId.cupsGramsEstimates:
      return const <ToolLookupEntry>[
        ToolLookupEntry(
          keyId: 'cupsgrams_flour',
          label: 'Flour (all-purpose)',
          valuesBySystem: <String, String>{
            'Cup': '1 cup',
            'Tbsp': '16 tbsp',
            'Tsp': '48 tsp',
            'Weight': '120 g',
          },
          note: 'Approximate scoop-and-level reference.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cupsgrams_sugar',
          label: 'Sugar (granulated)',
          valuesBySystem: <String, String>{
            'Cup': '1 cup',
            'Tbsp': '16 tbsp',
            'Tsp': '48 tsp',
            'Weight': '200 g',
          },
          note: 'Pack density varies by crystal size and humidity.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cupsgrams_brown_sugar',
          label: 'Brown sugar (packed)',
          valuesBySystem: <String, String>{
            'Cup': '1 cup packed',
            'Tbsp': '16 tbsp packed',
            'Tsp': '48 tsp packed',
            'Weight': '220 g',
          },
          note: 'Assumes packed cup measurement.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cupsgrams_butter',
          label: 'Butter',
          valuesBySystem: <String, String>{
            'Cup': '1 cup / 2 sticks',
            'Tbsp': '16 tbsp',
            'Tsp': '48 tsp',
            'Weight': '227 g',
          },
          note: 'Equivalent to 2 US sticks.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cupsgrams_rice',
          label: 'Rice (uncooked white)',
          valuesBySystem: <String, String>{
            'Cup': '1 cup',
            'Tbsp': '16 tbsp',
            'Tsp': '48 tsp',
            'Weight': '185 g',
          },
          note: 'Estimate before cooking.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cupsgrams_oats',
          label: 'Oats (rolled)',
          valuesBySystem: <String, String>{
            'Cup': '1 cup',
            'Tbsp': '16 tbsp',
            'Tsp': '48 tsp',
            'Weight': '90 g',
          },
          note: 'Rolled oats are lighter by volume than flour.',
          approximate: true,
        ),
        ToolLookupEntry(
          keyId: 'cupsgrams_honey',
          label: 'Honey',
          valuesBySystem: <String, String>{
            'Cup': '1 cup',
            'Tbsp': '16 tbsp',
            'Tsp': '48 tsp',
            'Weight': '340 g',
          },
          note: 'Dense liquid; weight is significantly higher per cup.',
          approximate: true,
        ),
      ];
    default:
      return const <ToolLookupEntry>[];
  }
}
