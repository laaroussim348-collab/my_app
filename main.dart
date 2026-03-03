import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() => runApp(MaterialApp(
      home: PageDiagnostic(),
      debugShowCheckedModeBanner: false,
    ));

class PageDiagnostic extends StatefulWidget {
  @override
  _PageDiagnosticState createState() => _PageDiagnosticState();
}

class _PageDiagnosticState extends State<PageDiagnostic> {
  // تعريف المتحكمات بالأسماء الصحيحة
  final _typeCtrl = TextEditingController();
  final _infoCtrl = TextEditingController();
  double? lat, lon;
  bool _isSending = false;

  // 1. وظيفة الحصول على الموقع GPS
  Future<void> _obtenirPosition() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          lat = position.latitude;
          lon = position.longitude;
        });
      } catch (e) {
        _afficherMessage("Erreur GPS: $e");
      }
    }
  }

  // 2. وظيفة إرسال الإيميل
  Future<void> _envoyerEmail() async {
    if (lat == null) {
      _afficherMessage("Veuillez obtenir la position GPS d'abord");
      return;
    }

    setState(() => _isSending = true);

    String monEmail = "laaroussim348@gmail.com";
    String monCodeSecret = "czgp hxrc stsn dxjs"; 

    final smtpServer = gmail(monEmail, monCodeSecret);

    final message = Message()
      ..from = Address(monEmail, 'Diagnostic App')
      ..recipients.add(monEmail)
      ..subject = 'RAPPORT : ${_typeCtrl.text}'
      ..text = '''
NOUVEAU RAPPORT TERRAIN
-----------------------
Type d'intervention : ${_typeCtrl.text}
Informations : ${_infoCtrl.text}
Coordonnées : $lat, $lon
Lien Maps : https://www.google.com/maps/search/?api=1&query=$lat,$lon
''';

    try {
      await send(message, smtpServer);
      _afficherMessage("Rapport envoyé avec succès ✅");
      _typeCtrl.clear();
      _infoCtrl.clear();
      setState(() { lat = null; lon = null; });
    } catch (e) {
      _afficherMessage("Échec de l'envoi : $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _afficherMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Diagnostic Terrain"), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _obtenirPosition,
                icon: Icon(Icons.location_on),
                label: Text(lat == null ? "Obtenir Position" : "Position OK ✅"),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.orange, foregroundColor: Colors.white),
              ),
              SizedBox(height: 20),
              TextField(controller: _typeCtrl, decoration: InputDecoration(labelText: "Type d'intervention", border: OutlineInputBorder())),
              SizedBox(height: 15),
              TextField(controller: _infoCtrl, maxLines: 3, decoration: InputDecoration(labelText: "Description / Observations", border: OutlineInputBorder())),
              SizedBox(height: 30),
              _isSending 
                ? CircularProgressIndicator() 
                : ElevatedButton.icon(
                    onPressed: _envoyerEmail, 
                    icon: Icon(Icons.send),
                    label: Text("ENVOYER LE RAPPORT"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 60),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}