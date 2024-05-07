import 'package:flutter/material.dart'; // Import modul dasar Flutter
import 'dart:convert'; // Import modul dart:convert untuk mengelola JSON
import 'package:http/http.dart' as http; // Import modul http dari paket http untuk melakukan permintaan HTTP
import 'package:flutter_bloc/flutter_bloc.dart'; // Import modul flutter_bloc untuk manajemen state
// Model untuk menyimpan data universitas
class University {
  final String name; // Nama universitas
  final String? stateProvince; // Provinsi universitas (opsional)
  final List<String> domains; // Domain universitas
  final List<String> webPages; // Halaman web universitas
  final String alphaTwoCode; // Kode alfa dua digit untuk negara universitas
  final String country; // Nama negara universitas

  University({
    required this.name,
    this.stateProvince,
    required this.domains,
    required this.webPages,
    required this.alphaTwoCode,
    required this.country,
  });

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      stateProvince: json['state-province'],
      domains: List<String>.from(json['domains']),
      webPages: List<String>.from(json['web_pages']),
      alphaTwoCode: json['alpha_two_code'],
      country: json['country'],
    );
  }
}

// Events
abstract class UniversityEvent {}

class FetchUniversitiesEvent extends UniversityEvent {
  final String country;
  FetchUniversitiesEvent(this.country);
}

// Bloc
class UniversityBloc extends Bloc<UniversityEvent, List<University>> {
  UniversityBloc() : super([]) {
    on<FetchUniversitiesEvent>(_fetchUniversities);
  }

  Future<void> _fetchUniversities(
    FetchUniversitiesEvent event,
    Emitter<List<University>> emit,
  ) async {
    try {
      final universities = await _fetchUniversitiesFromApi(event.country);
      emit(universities);
    } catch (e) {
      print('Error: $e');
      emit([]);
    }
  }

  Future<List<University>> _fetchUniversitiesFromApi(String country) async {
    final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$country'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => University.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load universities');
    }
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => UniversityBloc(),
        child: UniversitiesPage(),
      ),
    );
  }
}

class UniversitiesPage extends StatefulWidget {
  @override
  _UniversitiesPageState createState() => _UniversitiesPageState();
}

class _UniversitiesPageState extends State<UniversitiesPage> {
  final List<String> _aseanCountries = [
    'Indonesia',
    'Singapore',
    'Malaysia',
    'Thailand',
    'Philippines',
    'Vietnam',
    'Myanmar',
    'Cambodia',
    'Brunei',
    'Laos',
  ];

  String _selectedCountry = 'Indonesia';

  @override
  void initState() {
    super.initState();
    context.read<UniversityBloc>().add(FetchUniversitiesEvent(_selectedCountry));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ASEAN Universities'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedCountry,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCountry = newValue!;
                  context
                      .read<UniversityBloc>()
                      .add(FetchUniversitiesEvent(newValue));
                });
              },
              items: _aseanCountries.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          BlocBuilder<UniversityBloc, List<University>>(
            builder: (context, universities) {
              if (universities.isEmpty) {
                return CircularProgressIndicator();
              }
              return Expanded(
                child: ListView.builder(
                  itemCount: universities.length,
                  itemBuilder: (context, index) {
                    final university = universities[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            university.name,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Divider(), // Add divider instead of Card
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
