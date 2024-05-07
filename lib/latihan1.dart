import 'package:flutter/material.dart'; // Import dasar untuk membangun antarmuka pengguna (UI) menggunakan Flutter.
import 'package:http/http.dart' as http; // Import untuk melakukan permintaan HTTP ke server.
import 'dart:convert'; // Import untuk mengonversi data dari dan ke format JSON.
import 'package:flutter_bloc/flutter_bloc.dart'; // Import untuk mengimplementasikan pola manajemen keadaan menggunakan BLoC (Business Logic Component) di Flutter.

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
        create: (context) => CountryCubit(), // Membuat instance dari CountryCubit untuk digunakan di seluruh aplikasi.
        child: UniversityListPage(), // Menampilkan halaman UniversityListPage sebagai halaman utama.
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
                'Universities in ${state.selectedCountry?.name ?? 'Unknown'}'); // Judul AppBar menampilkan nama negara terpilih.
          },
        ),
      ),
      body: Column(
        children: [
          BlocBuilder<CountryCubit, CountryState>(
            builder: (context, state) {
              return DropdownButton<Country>(
                value: state.selectedCountry, // Nilai dropdown sesuai dengan negara yang dipilih.
                onChanged: (Country? newValue) {
                  context.read<CountryCubit>().selectCountry(newValue!); // Memperbarui negara yang dipilih.
                },
                items: state.countries
                    .map<DropdownMenuItem<Country>>((Country value) {
                  return DropdownMenuItem<Country>(
                    value: value,
                    child: Text(value.name), // Menampilkan nama negara dalam dropdown.
                  );
                }).toList(),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<CountryCubit, CountryState>(
              builder: (context, state) {
                return FutureBuilder<List<University>>(
                  future: state.futureUniversities, // Menggunakan futureUniversities dari state untuk menampilkan daftar universitas.
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator()); // Menampilkan indikator loading saat data sedang diambil.
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}')); // Menampilkan pesan error jika gagal mengambil data.
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(snapshot.data![index].name),
                            subtitle: Text(snapshot.data![index].website),
                          ); // Menampilkan daftar universitas dalam bentuk list tile.
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
  final Country? selectedCountry; // Negara yang dipilih.
  final List<Country> countries; // Daftar negara.
  final Future<List<University>> futureUniversities; // Future untuk daftar universitas di negara terpilih.

  CountryState({
    this.selectedCountry,
    required this.countries,
    required Future<List<University>> futureUniversities,
  }) : this.futureUniversities = futureUniversities;
}

class CountryCubit extends Cubit<CountryState> {
  CountryCubit()
      : super(CountryState(
          selectedCountry: null, // Awalnya tidak ada negara yang dipilih.
          countries: [
            Country('Indonesia'), // Daftar negara yang tersedia.
            Country('Singapura'),
            Country('Malaysia'),
            Country('Thailand'),
            Country('Vietnam'),
            Country('Filipina'),
            Country('Brunei'),
            Country('Myanmar'),
            Country('Kamboja'),
            Country('Laos'),
            // Tambahkan negara ASEAN lainnya jika diperlukan
          ],
          futureUniversities:
              fetchUniversities('Indonesia'), // Default untuk Indonesia.
        ));

  void selectCountry(Country country) {
    emit(state.copyWith(
      selectedCountry: country, // Memperbarui negara yang dipilih.
      futureUniversities: fetchUniversities(country.name), // Mengambil daftar universitas untuk negara yang dipilih.
    ));
  }

  static Future<List<University>> fetchUniversities(String countryName) async {
    final response = await http.get(Uri.parse(
        'http://universities.hipolabs.com/search?country=$countryName'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<University> universities =
          data.map((json) => University.fromJson(json)).toList();
      return universities; // Mengembalikan daftar universitas dari respons JSON.
    } else {
      throw Exception('Failed to load universities'); // Melemparkan pengecualian jika gagal mengambil data universitas.
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
