import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class University {
  final String name;
  final String website;

  University({required this.name, required this.website});

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: json['web_pages'][0],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (context) => CountryCubit(),
        child: UniversityListPage(),
      ),
    );
  }
}

class UniversityListPage extends StatelessWidget {
  const UniversityListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CountryCubit, CountryState>(
          builder: (context, state) {
            return Text(
                'Universities in ${state.selectedCountry?.name ?? 'Unknown'}');
          },
        ),
      ),
      body: Column(
        children: [
          BlocBuilder<CountryCubit, CountryState>(
            builder: (context, state) {
              return DropdownButton<Country>(
                value: state.selectedCountry,
                onChanged: (Country? newValue) {
                  context.read<CountryCubit>().selectCountry(newValue!);
                },
                items: state.countries
                    .map<DropdownMenuItem<Country>>((Country value) {
                  return DropdownMenuItem<Country>(
                    value: value,
                    child: Text(value.name),
                  );
                }).toList(),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<CountryCubit, CountryState>(
              builder: (context, state) {
                return FutureBuilder<List<University>>(
                  future: state.futureUniversities,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(snapshot.data![index].name),
                            subtitle: Text(snapshot.data![index].website),
                          );
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Country {
  final String name;

  Country(this.name);
}

class CountryState {
  final Country? selectedCountry;
  final List<Country> countries;
  final Future<List<University>> futureUniversities;

  CountryState({
    this.selectedCountry,
    required this.countries,
    required Future<List<University>> futureUniversities,
  }) : this.futureUniversities = futureUniversities;
}

class CountryCubit extends Cubit<CountryState> {
  CountryCubit()
      : super(CountryState(
          selectedCountry: null,
          countries: [
            Country('Indonesia'),
            Country('Singapura'),
            Country('Malaysia'),
            Country('Thailand'),
            Country('Vietnam'),
            Country('Filipina'),
            Country('Brunei'),
            Country('Myanmar'),
            Country('Kamboja'),
            Country('Laos'),
            // Add other ASEAN countries as needed
          ],
          futureUniversities:
              fetchUniversities('Indonesia'), // Default to Indonesia
        ));

  void selectCountry(Country country) {
    emit(state.copyWith(
      selectedCountry: country,
      futureUniversities: fetchUniversities(country.name),
    ));
  }

  static Future<List<University>> fetchUniversities(String countryName) async {
    final response = await http.get(Uri.parse(
        'http://universities.hipolabs.com/search?country=$countryName'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<University> universities =
          data.map((json) => University.fromJson(json)).toList();
      return universities;
    } else {
      throw Exception('Failed to load universities');
    }
  }
}

extension CountryStateCopyWith on CountryState {
  CountryState copyWith({
    Country? selectedCountry,
    List<Country>? countries,
    required Future<List<University>> futureUniversities,
  }) {
    return CountryState(
      selectedCountry: selectedCountry ?? this.selectedCountry,
      countries: countries ?? this.countries,
      futureUniversities: futureUniversities,
    );
  }
}
