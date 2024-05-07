import 'package:flutter/material.dart'; // Import package Flutter Material untuk membangun UI
import 'package:http/http.dart' as http; // Import package http untuk melakukan HTTP requests
import 'dart:convert'; // Import package dart:convert untuk mengonversi JSON
import 'package:provider/provider.dart'; // Import package provider untuk manajemen state

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
      throw Exception('Gagal memuat daftar universitas');
    }
  }

  @override
  Widget build(BuildContext context) {
    var countryModel = Provider.of<CountryModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Universitas di ${countryModel.selectedCountry?.name ?? 'Tidak Diketahui'}'),
      ),
      body: Column(
        children: [
          // DropdownButton untuk memilih negara
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
          // Menampilkan daftar universitas
          Expanded(
            child: Center(
              child: FutureBuilder<List<University>>(
                future: futureUniversities,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Menampilkan indikator loading saat data sedang diambil
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    // Menampilkan pesan error jika gagal mengambil data
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Menampilkan daftar universitas
                    return ListView.builder(
                      itemCount: snapshot.data!.length * 2 - 1,
                      itemBuilder: (context, index) {
                        if (index.isOdd) {
                          // Menambahkan pemisah antara item universitas
                          return Divider(
                            thickness: 1.5,
                            color: Colors.grey[300],
                            indent: 20,
                            endIndent: 20,
                          );
                        }
                        final universityIndex = index ~/ 2;
                        // ListTile untuk menampilkan nama dan situs web universitas
                        return ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 20.0),
                          title: Center(
                            child: Text(
                              snapshot.data![universityIndex].name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          subtitle: Center(
                            child: Text(
                              snapshot.data![universityIndex].website,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            // Aksi yang dilakukan ketika item universitas diklik
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

// Model untuk menyimpan data negara dan negara yang dipilih
class Country {
  final String name;

  Country(this.name);
}

class CountryModel extends ChangeNotifier {
  Country? selectedCountry;
  // Daftar negara ASEAN
  List<Country> countries = [
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
    // Tambah negara ASEAN lainnya sesuai kebutuhan
  ];

  void selectCountry(Country country) {
    // Memperbarui negara yang dipilih dan memberitahu listener
    selectedCountry = country;
    notifyListeners();
  }
}
