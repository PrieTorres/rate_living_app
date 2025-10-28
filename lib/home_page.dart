// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Review {
  final String title;
  final double rating;
  final LatLng location;
  Review({required this.title, required this.rating, required this.location});
}

final List<Review> dummyReviews = [
  Review(
    title: "Café Central",
    rating: 4.5,
    location: const LatLng(-26.304516, -48.843380), // ex: centro de Joinville
  ),
  Review(
    title: "Restaurante Saboroso",
    rating: 4.2,
    location: const LatLng(-26.312000, -48.840000), // coordenada próxima
  ),
  Review(
    title: "Parque das Flores",
    rating: 4.8,
    location: const LatLng(-26.295000, -48.850000), // outra coordenada próxima
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<Marker> _markers = {};

  final CameraPosition _initialCamPosition = CameraPosition(
    target: dummyReviews[0].location,
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    for (var review in dummyReviews) {
      _markers.add(
        Marker(
          markerId: MarkerId(review.title),  // id único do marcador
          position: review.location,         // posição do marcador no mapa
          infoWindow: InfoWindow(
            title: review.title,
            snippet: "Nota: ${review.rating.toStringAsFixed(1)}/5.0",
          ),
          // Podemos adicionar onTap aqui se quisermos ação ao tocar no marcador.
          // Sem um onTap customizado, ao tocar no marcador será exibida a infoWindow padrão.
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Avaliações"), // Título da AppBar
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          // Opcional: podemos guardar o controller em uma variável se formos usar depois
        },
        initialCameraPosition: _initialCamPosition,
        markers: _markers,               // define os marcadores no mapa
        mapType: MapType.normal,         // tipo de mapa (normal, satélite, etc.)
        myLocationEnabled: false,        // opção para mostrar localização do dispositivo (requer permissão se true)
        zoomControlsEnabled: true,       // mostra botões de zoom (+/-) no mapa
        indoorViewEnabled: true,         // habilita visualização interna (se disponível)
      ),
    );
  }
}
