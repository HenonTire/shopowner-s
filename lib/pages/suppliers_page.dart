import 'package:flutter/material.dart';
import 'package:shop_manager/theme/app_themes.dart';

class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
      ),
      body: Center(
        child: Column(
          
       
          children: [
            Text(
              'Manage your suppliers.',
              style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w500)
            ),


          ],
        ),
      ),
    );
  }
}