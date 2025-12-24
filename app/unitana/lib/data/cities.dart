class City {
  final String name;
  final String country;
  final String timeZone; // IANA
  const City({required this.name, required this.country, required this.timeZone});

  String get label => '$name, $country';
}

// Curated MVP list (expand anytime). Keep it small and high-signal.
const List<City> kCities = [
  City(name: 'Denver', country: 'US', timeZone: 'America/Denver'),
  City(name: 'New York', country: 'US', timeZone: 'America/New_York'),
  City(name: 'Los Angeles', country: 'US', timeZone: 'America/Los_Angeles'),
  City(name: 'Chicago', country: 'US', timeZone: 'America/Chicago'),
  City(name: 'London', country: 'GB', timeZone: 'Europe/London'),
  City(name: 'Lisbon', country: 'PT', timeZone: 'Europe/Lisbon'),
  City(name: 'Porto', country: 'PT', timeZone: 'Europe/Lisbon'),
  City(name: 'Paris', country: 'FR', timeZone: 'Europe/Paris'),
  City(name: 'Berlin', country: 'DE', timeZone: 'Europe/Berlin'),
  City(name: 'Rome', country: 'IT', timeZone: 'Europe/Rome'),
  City(name: 'Madrid', country: 'ES', timeZone: 'Europe/Madrid'),
  City(name: 'Barcelona', country: 'ES', timeZone: 'Europe/Madrid'),
  City(name: 'Dublin', country: 'IE', timeZone: 'Europe/Dublin'),
  City(name: 'Amsterdam', country: 'NL', timeZone: 'Europe/Amsterdam'),
  City(name: 'Zurich', country: 'CH', timeZone: 'Europe/Zurich'),
  City(name: 'Vienna', country: 'AT', timeZone: 'Europe/Vienna'),
  City(name: 'Prague', country: 'CZ', timeZone: 'Europe/Prague'),
  City(name: 'Stockholm', country: 'SE', timeZone: 'Europe/Stockholm'),
  City(name: 'Oslo', country: 'NO', timeZone: 'Europe/Oslo'),
  City(name: 'Copenhagen', country: 'DK', timeZone: 'Europe/Copenhagen'),
  City(name: 'Athens', country: 'GR', timeZone: 'Europe/Athens'),
  City(name: 'Istanbul', country: 'TR', timeZone: 'Europe/Istanbul'),
  City(name: 'Tokyo', country: 'JP', timeZone: 'Asia/Tokyo'),
  City(name: 'Seoul', country: 'KR', timeZone: 'Asia/Seoul'),
  City(name: 'Singapore', country: 'SG', timeZone: 'Asia/Singapore'),
  City(name: 'Sydney', country: 'AU', timeZone: 'Australia/Sydney'),
  City(name: 'Melbourne', country: 'AU', timeZone: 'Australia/Melbourne'),
  City(name: 'Mexico City', country: 'MX', timeZone: 'America/Mexico_City'),
  City(name: 'Toronto', country: 'CA', timeZone: 'America/Toronto'),
  City(name: 'Vancouver', country: 'CA', timeZone: 'America/Vancouver'),
];

