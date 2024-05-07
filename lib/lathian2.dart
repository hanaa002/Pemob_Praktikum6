import 'package:flutter/material.dart'; // Paket dasar untuk membangun antarmuka pengguna (UI) menggunakan Flutter.
import 'package:http/http.dart'
    as http; // Paket untuk melakukan permintaan HTTP ke server.
import 'dart:convert'; // Paket untuk mengonversi data dari dan ke format JSON.
import 'package:provider/provider.dart'; // Paket untuk mengelola status aplikasi dan berbagi data antara widget.

void main() {
  runApp(const MyApp());
}

// Kelas untuk merepresentasikan informasi universitas
class University {
  final String name;
  final String website;

  University({required this.name, required this.website});

  // Constructor factory untuk membuat objek University dari JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: json['web_pages'][0],
    );
  }
}

// Kelas utama aplikasi
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          CountryModel(), // Membuat instance dari CountryModel untuk di-share
      child: MaterialApp(
        title: 'University List',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: UniversityListPage(), // Halaman utama aplikasi
      ),
    );
  }
}

// Halaman untuk menampilkan daftar universitas
class UniversityListPage extends StatefulWidget {
  const UniversityListPage({Key? key}) : super(key: key);

  @override
  State<UniversityListPage> createState() => _UniversityListPageState();
}

class _UniversityListPageState extends State<UniversityListPage> {
  late Future<List<University>>
      futureUniversities; // Future untuk menampung daftar universitas

  @override
  void initState() {
    super.initState();
    final countryModel = Provider.of<CountryModel>(context, listen: false);
    futureUniversities = fetchUniversities(countryModel.selectedCountry?.name ??
        'Indonesia'); // Mengambil daftar universitas untuk negara terpilih atau Indonesia secara default
    countryModel.addListener(() {
      futureUniversities = fetchUniversities(countryModel
              .selectedCountry?.name ??
          'Indonesia'); // Mengambil ulang daftar universitas saat negara terpilih berubah
      setState(() {});
    });
  }

  // Mengambil daftar universitas dari API
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
            'Universities in ${countryModel.selectedCountry?.name ?? 'Unknown'}'), // Judul AppBar
      ),
      body: Column(
        children: [
          // DropdownButton untuk memilih negara
          DropdownButton<Country>(
            value: countryModel.selectedCountry,
            onChanged: (Country? newValue) {
              countryModel.selectCountry(newValue!); // Memilih negara baru
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
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final university = snapshot.data![index];
                        return ListTile(
                          title: Text(university.name),
                          subtitle: Text(university.website),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            // Aksi yang dilakukan saat item universitas ditekan
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
  Country? selectedCountry; // Negara yang dipilih
  // List negara ASEAN
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
    // Tambahkan negara ASEAN lainnya jika diperlukan
  ];

  void selectCountry(Country country) {
    // Memperbarui negara yang dipilih dan memberi tahu pendengar
    selectedCountry = country;
    notifyListeners();
  }
}
