import 'package:flutter/material.dart';

// Importando desde pucpflow (que es tu verdadero package name)
import 'package:pucpflow/Cafillari/core/theme.dart';
import 'package:pucpflow/Cafillari/widgets/feature_card.dart';

// Importando las pantallas
import 'package:pucpflow/Cafillari/screens/monitoring/monitoring_screen.dart';
import 'package:pucpflow/Cafillari/screens/traceability/traceability_screen.dart';
import 'package:pucpflow/Cafillari/screens/alerts/alerts_screen.dart';
import 'package:pucpflow/Cafillari/screens/data_visualization/data_visualization_screen.dart';
import 'package:pucpflow/Cafillari/screens/remote_control/remote_control_screen.dart';
import 'package:pucpflow/Cafillari/screens/reports/reports_screen.dart';
import 'package:pucpflow/Cafillari/screens/reports/coffee_map_screen.dart';


class CafillariHomePage extends StatelessWidget {
  const CafillariHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CAFILLARI'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              SizedBox(
                height: 150,
                child: Image.asset('assets/logo_cafillari.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
              const Text('Bienvenido a Cafillari', style: AppTextStyles.title),
              const SizedBox(height: 8),
              const Text('El nuevo amanecer del café inteligente.', style: AppTextStyles.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: 30),
              FeatureCard(
              icon: Icons.map,
              title: 'Mapa Cafetalero',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardCafetalero())),
            ),
              FeatureCard(
                icon: Icons.sensors,
                title: 'Monitoreo en Tiempo Real',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonitoringScreen())),
              ),
              FeatureCard(
                icon: Icons.timeline,
                title: 'Trazabilidad del Proceso',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TraceabilityScreen())),
              ),
              FeatureCard(
                icon: Icons.notifications_active,
                title: 'Alertas Inteligentes',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlertsScreen())),
              ),
              FeatureCard(
                icon: Icons.show_chart,
                title: 'Visualización de Datos',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DataVisualizationScreen())),
              ),
              FeatureCard(
                icon: Icons.settings_remote,
                title: 'Control Remoto',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RemoteControlScreen())),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen())),
        child: const Icon(Icons.description),
        tooltip: 'Generar Reportes',
      ),
    );
  }
}
