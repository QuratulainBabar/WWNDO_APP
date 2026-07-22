import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meetup_location.dart';

/// Google Places Autocomplete search for meetup location picking.
class PlacesSearchService {
  PlacesSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Set via `--dart-define=GOOGLE_PLACES_API_KEY=your_key`.
  static const String apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  bool get isConfigured => apiKey.isNotEmpty;

  Future<List<MeetupLocation>> search(String query) async {
    return _autocomplete(
      query,
      types: 'establishment|geocode',
      demoFallback: _demoSuggestions,
    );
  }

  /// City / locality autocomplete for trip From / To fields.
  Future<List<MeetupLocation>> searchCities(String query) async {
    return _autocomplete(
      query,
      types: '(cities)',
      demoFallback: _demoCitySuggestions,
    );
  }

  Future<List<MeetupLocation>> _autocomplete(
    String query, {
    required String types,
    required List<MeetupLocation> Function(String query) demoFallback,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    if (!isConfigured) {
      return demoFallback(trimmed);
    }

    final uri = Uri.parse(_autocompleteUrl).replace(
      queryParameters: {
        'input': trimmed,
        'key': apiKey,
        'types': types,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Places search failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Places search error: $status');
    }

    final predictions = body['predictions'] as List<dynamic>? ?? [];
    return predictions
        .map((item) {
          final map = item as Map<String, dynamic>;
          final description = map['description'] as String? ?? '';
          final structured =
              map['structured_formatting'] as Map<String, dynamic>?;
          final mainText = structured?['main_text'] as String? ?? description;
          return MeetupLocation(
            name: mainText,
            address: description,
            placeId: map['place_id'] as String?,
          );
        })
        .toList();
  }

  List<MeetupLocation> _demoCitySuggestions(String query) {
    const samples = [
      MeetupLocation(name: 'London', address: 'London, UK'),
      MeetupLocation(name: 'Lagos', address: 'Lagos, Nigeria'),
      MeetupLocation(name: 'Paris', address: 'Paris, France'),
      MeetupLocation(name: 'New York', address: 'New York, NY, USA'),
      MeetupLocation(name: 'Dubai', address: 'Dubai, United Arab Emirates'),
      MeetupLocation(name: 'Toronto', address: 'Toronto, ON, Canada'),
      MeetupLocation(name: 'Berlin', address: 'Berlin, Germany'),
      MeetupLocation(name: 'Madrid', address: 'Madrid, Spain'),
      MeetupLocation(name: 'Rome', address: 'Rome, Italy'),
      MeetupLocation(name: 'Amsterdam', address: 'Amsterdam, Netherlands'),
      MeetupLocation(name: 'Istanbul', address: 'Istanbul, Türkiye'),
      MeetupLocation(name: 'Cairo', address: 'Cairo, Egypt'),
      MeetupLocation(name: 'Mumbai', address: 'Mumbai, India'),
      MeetupLocation(name: 'Singapore', address: 'Singapore'),
      MeetupLocation(name: 'Tokyo', address: 'Tokyo, Japan'),
      MeetupLocation(name: 'Sydney', address: 'Sydney NSW, Australia'),
      MeetupLocation(name: 'Los Angeles', address: 'Los Angeles, CA, USA'),
      MeetupLocation(name: 'Chicago', address: 'Chicago, IL, USA'),
      MeetupLocation(name: 'Manchester', address: 'Manchester, UK'),
      MeetupLocation(name: 'Abuja', address: 'Abuja, Nigeria'),
      MeetupLocation(name: 'Dakar', address: 'Dakar, Senegal'),
      MeetupLocation(name: 'Casablanca', address: 'Casablanca, Morocco'),
      MeetupLocation(name: 'Johannesburg', address: 'Johannesburg, South Africa'),
      MeetupLocation(name: 'Nairobi', address: 'Nairobi, Kenya'),
      MeetupLocation(name: 'Accra', address: 'Accra, Ghana'),
    ];

    final needle = query.toLowerCase();
    final matches = samples
        .where(
          (place) =>
              place.name.toLowerCase().contains(needle) ||
              place.address.toLowerCase().contains(needle),
        )
        .toList();

    if (matches.length < 8) {
      final startsWith = samples.where((place) {
        final words =
            '${place.name} ${place.address}'.toLowerCase().split(RegExp(r'[\s,]+'));
        return words.any((w) => w.startsWith(needle));
      });
      final seen = matches.map((m) => m.address).toSet();
      for (final place in startsWith) {
        if (seen.add(place.address)) matches.add(place);
      }
    }

    return matches.take(20).toList();
  }

  List<MeetupLocation> _demoSuggestions(String query) {
    const samples = [
      MeetupLocation(
        name: 'Central Park',
        address: 'Central Park, New York, NY, USA',
      ),
      MeetupLocation(
        name: 'Times Square',
        address: 'Times Square, Manhattan, NY, USA',
      ),
      MeetupLocation(
        name: 'JFK Airport',
        address: 'John F. Kennedy International Airport, Queens, NY, USA',
      ),
      MeetupLocation(
        name: 'LaGuardia Airport',
        address: 'LaGuardia Airport, Queens, NY, USA',
      ),
      MeetupLocation(
        name: 'Starbucks',
        address: 'Starbucks Coffee, 5th Avenue, New York, NY, USA',
      ),
      MeetupLocation(
        name: 'Starbucks Reserve',
        address: 'Starbucks Reserve Roastery, Chelsea, New York, NY, USA',
      ),
      MeetupLocation(
        name: 'Grand Central Terminal',
        address: 'Grand Central Terminal, East 42nd Street, New York, NY, USA',
      ),
      MeetupLocation(
        name: 'Penn Station',
        address: 'Pennsylvania Station, New York, NY, USA',
      ),
      MeetupLocation(
        name: 'Empire State Building',
        address: 'Empire State Building, New York, NY, USA',
      ),
      MeetupLocation(
        name: 'Brooklyn Bridge',
        address: 'Brooklyn Bridge, New York, NY, USA',
      ),
      MeetupLocation(
        name: 'Bennett University',
        address: 'Bennett University, Greater Noida, Uttar Pradesh, India',
      ),
      MeetupLocation(
        name: 'Charles de Gaulle Airport',
        address: 'Paris Charles de Gaulle Airport, Roissy-en-France, France',
      ),
      MeetupLocation(
        name: 'Orly Airport',
        address: 'Paris Orly Airport, Orly, France',
      ),
      MeetupLocation(
        name: 'Gare du Nord',
        address: 'Gare du Nord, Paris, France',
      ),
      MeetupLocation(
        name: 'Gare de Lyon',
        address: 'Gare de Lyon, Paris, France',
      ),
      MeetupLocation(
        name: 'Gare Montparnasse',
        address: 'Gare Montparnasse, Paris, France',
      ),
      MeetupLocation(
        name: 'Eiffel Tower',
        address: 'Eiffel Tower, Champ de Mars, Paris, France',
      ),
      MeetupLocation(
        name: 'Louvre Museum',
        address: 'Musée du Louvre, Paris, France',
      ),
      MeetupLocation(
        name: 'Place de la Concorde',
        address: 'Place de la Concorde, Paris, France',
      ),
      MeetupLocation(
        name: 'Champs-Élysées',
        address: 'Avenue des Champs-Élysées, Paris, France',
      ),
      MeetupLocation(
        name: 'Galeries Lafayette',
        address: 'Galeries Lafayette Haussmann, Paris, France',
      ),
      MeetupLocation(
        name: 'Café de Flore',
        address: 'Café de Flore, Saint-Germain-des-Prés, Paris, France',
      ),
      MeetupLocation(
        name: 'Hotel Plaza Athénée',
        address: 'Hôtel Plaza Athénée, Avenue Montaigne, Paris, France',
      ),
      MeetupLocation(
        name: 'Paris-Nord Bus Station',
        address: 'Gare Routière Paris-Nord, Paris, France',
      ),
      MeetupLocation(
        name: 'Heathrow Airport',
        address: 'London Heathrow Airport, Longford, UK',
      ),
      MeetupLocation(
        name: 'Gatwick Airport',
        address: 'London Gatwick Airport, Crawley, UK',
      ),
      MeetupLocation(
        name: "King's Cross Station",
        address: "King's Cross Station, London, UK",
      ),
      MeetupLocation(
        name: 'Paddington Station',
        address: 'Paddington Station, London, UK',
      ),
      MeetupLocation(
        name: 'Covent Garden',
        address: 'Covent Garden, London, UK',
      ),
      MeetupLocation(
        name: 'Dubai International Airport',
        address: 'Dubai International Airport, Dubai, UAE',
      ),
      MeetupLocation(
        name: 'Dubai Mall',
        address: 'The Dubai Mall, Downtown Dubai, UAE',
      ),
      MeetupLocation(
        name: 'Burj Khalifa',
        address: 'Burj Khalifa, Downtown Dubai, UAE',
      ),
      MeetupLocation(
        name: 'Mall of the Emirates',
        address: 'Mall of the Emirates, Dubai, UAE',
      ),
      MeetupLocation(
        name: 'Indira Gandhi International Airport',
        address: 'Indira Gandhi International Airport, New Delhi, India',
      ),
      MeetupLocation(
        name: 'Chhatrapati Shivaji Maharaj International Airport',
        address: 'CSMIA, Mumbai, Maharashtra, India',
      ),
      MeetupLocation(
        name: 'Connaught Place',
        address: 'Connaught Place, New Delhi, India',
      ),
      MeetupLocation(
        name: 'Select Citywalk Mall',
        address: 'Select Citywalk, Saket, New Delhi, India',
      ),
      MeetupLocation(
        name: 'India Gate',
        address: 'India Gate, Rajpath, New Delhi, India',
      ),
      MeetupLocation(
        name: 'Lagos Airport',
        address: 'Murtala Muhammed International Airport, Lagos, Nigeria',
      ),
      MeetupLocation(
        name: 'Ikeja City Mall',
        address: 'Ikeja City Mall, Lagos, Nigeria',
      ),
      MeetupLocation(
        name: 'Lekki Conservation Centre',
        address: 'Lekki Conservation Centre, Lagos, Nigeria',
      ),
      MeetupLocation(
        name: 'Accra Airport',
        address: 'Kotoka International Airport, Accra, Ghana',
      ),
      MeetupLocation(
        name: 'Accra Mall',
        address: 'Accra Mall, Tetteh Quarshie, Accra, Ghana',
      ),
      MeetupLocation(
        name: 'Dakar Airport',
        address: 'Blaise Diagne International Airport, Dakar, Senegal',
      ),
      MeetupLocation(
        name: 'Place de l\'Indépendance',
        address: 'Place de l\'Indépendance, Dakar, Senegal',
      ),
      MeetupLocation(
        name: 'Toronto Pearson Airport',
        address: 'Toronto Pearson International Airport, Mississauga, ON, Canada',
      ),
      MeetupLocation(
        name: 'Union Station Toronto',
        address: 'Union Station, Toronto, ON, Canada',
      ),
      MeetupLocation(
        name: 'CN Tower',
        address: 'CN Tower, Toronto, ON, Canada',
      ),
      MeetupLocation(
        name: 'Boston Logan Airport',
        address: 'Boston Logan International Airport, Boston, MA, USA',
      ),
      MeetupLocation(
        name: 'Boston University',
        address: 'Boston University, Boston, MA, USA',
      ),
      MeetupLocation(
        name: 'Boston South Station',
        address: 'South Station, Boston, MA, USA',
      ),
      MeetupLocation(
        name: 'Boston Children\'s Museum',
        address: 'Boston Children\'s Museum, Boston, MA, USA',
      ),
      MeetupLocation(
        name: 'Park Street Station',
        address: 'Park Street Station, Boston, MA, USA',
      ),
      MeetupLocation(
        name: 'Public Garden Boston',
        address: 'Boston Public Garden, Boston, MA, USA',
      ),
      MeetupLocation(
        name: 'Panera Bread',
        address: 'Panera Bread, Downtown Crossing, Boston, MA, USA',
      ),
      MeetupLocation(
        name: 'Hilton Hotel Lobby',
        address: 'Hilton Hotel, Downtown, USA',
      ),
      MeetupLocation(
        name: 'Marriott Hotel Lobby',
        address: 'Marriott Hotel, City Center',
      ),
      MeetupLocation(
        name: 'Shopping Mall Food Court',
        address: 'Main Shopping Mall, Food Court Entrance',
      ),
      MeetupLocation(
        name: 'Central Bus Station',
        address: 'Central Bus Terminal, City Center',
      ),
      MeetupLocation(
        name: 'Main Train Station',
        address: 'Central Railway Station',
      ),
      MeetupLocation(
        name: 'Airport Meeting Point',
        address: 'Arrivals Hall Meeting Point',
      ),
      MeetupLocation(
        name: 'Coffee Shop Near Station',
        address: 'Station Café, Main Entrance',
      ),
      MeetupLocation(
        name: 'Paris Opera',
        address: 'Palais Garnier, Place de l\'Opéra, Paris, France',
      ),
      MeetupLocation(
        name: 'Parc des Princes',
        address: 'Parc des Princes, Paris, France',
      ),
      MeetupLocation(
        name: 'Pasadena City Hall',
        address: 'Pasadena City Hall, Pasadena, CA, USA',
      ),
      MeetupLocation(
        name: 'Palo Alto Transit Center',
        address: 'Palo Alto Transit Center, Palo Alto, CA, USA',
      ),
      MeetupLocation(
        name: 'Pakistan Embassy Paris',
        address: 'Embassy of Pakistan, Paris, France',
      ),
      MeetupLocation(
        name: 'Palais de Tokyo',
        address: 'Palais de Tokyo, Paris, France',
      ),
      MeetupLocation(
        name: 'Place Vendôme',
        address: 'Place Vendôme, Paris, France',
      ),
    ];

    final needle = query.toLowerCase();
    final matches = samples
        .where(
          (place) =>
              place.name.toLowerCase().contains(needle) ||
              place.address.toLowerCase().contains(needle),
        )
        .toList();

    // If few exact matches, also return places whose words start with the query.
    if (matches.length < 8) {
      final startsWith = samples.where((place) {
        final words = '${place.name} ${place.address}'.toLowerCase().split(RegExp(r'[\s,]+'));
        return words.any((w) => w.startsWith(needle));
      });
      final seen = matches.map((m) => m.address).toSet();
      for (final place in startsWith) {
        if (seen.add(place.address)) matches.add(place);
      }
    }

    return matches.take(20).toList();
  }
}
