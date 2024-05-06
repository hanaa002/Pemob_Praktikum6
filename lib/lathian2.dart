import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

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
    return ChangeNotifierProvider(
      create: (context) => CountryModel(),
      child: MaterialApp(
        title: 'University List',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: UniversityListPage(),
      ),
    );
  }
}

class UniversityListPage extends StatefulWidget {
  const UniversityListPage({Key? key}) : super(key: key);

  @override
  State<UniversityListPage> createState() => _UniversityListPageState();
}

class _UniversityListPageState extends State<UniversityListPage> {
  late Future<List<University>> futureUniversities;

  @override
  void initState() {
    super.initState();
    final countryModel = Provider.of<CountryModel>(context, listen: false);
    futureUniversities =
        fetchUniversities(countryModel.selectedCountry?.name ?? 'Indonesia');
    countryModel.addListener(() {
      futureUniversities =
          fetchUniversities(countryModel.selectedCountry?.name ?? 'Indonesia');
      setState(() {});
    });
  }

  Future<List<University>> fetchUniversities(String countryName) async {
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

  @override
  Widget build(BuildContext context) {
    var countryModel = Provider.of<CountryModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Universities in ${countryModel.selectedCountry?.name ?? 'Unknown'}'),
      ),
      body: Column(
        children: [
          // DropdownButton to select country
          DropdownButton<Country>(
            value: countryModel.selectedCountry,
            onChanged: (Country? newValue) {
              countryModel.selectCountry(newValue!);
            },
            items: countryModel.countries
                .map<DropdownMenuItem<Country>>((Country value) {
              return DropdownMenuItem<Country>(
                value: value,
                child: Text(value.name),
              );
            }).toList(),
          ),
          // Display list of universities
          Expanded(
            child: Center(
              child: FutureBuilder<List<University>>(
                future: futureUniversities,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Show loading indicator while data is being fetched
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    // Show error message if failed to fetch data
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Display list of universities
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final university = snapshot.data![index];
                        return ListTile(
                          title: Text(university.name),
                          subtitle: Text(university.website),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            // Action to perform when university item is tapped
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Model to store country data and selected country
class Country {
  final String name;

  Country(this.name);
}

class CountryModel extends ChangeNotifier {
  Country? selectedCountry;
  // List of ASEAN countries
  List<Country> countries = [
    Country('Indonesia'),
    Country('Singapore'),
    Country('Malaysia'),
    Country('Thailand'),
    Country('Vietnam'),
    Country('Philippines'),
    Country('Brunei'),
    Country('Myanmar'),
    Country('Cambodia'),
    Country('Laos'),
    // Add other ASEAN countries as needed
  ];

  void selectCountry(Country country) {
    // Update selected country and notify listeners
    selectedCountry = country;
    notifyListeners();
  }
}
