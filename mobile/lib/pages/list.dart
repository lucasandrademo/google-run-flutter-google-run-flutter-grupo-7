import 'package:flutter/material.dart';
import '../data/puc_units.dart';

class ListPage extends StatelessWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades da PUC'),
      ),
      body: ListView.builder(
        itemCount: pucUnits.length,
        itemBuilder: (context, index) {
          final unit = pucUnits[index];
          return ListTile(
            title: Text(unit['name']!),
            subtitle: Text(unit['address']!),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.home),
      ),
    );
  }
}
