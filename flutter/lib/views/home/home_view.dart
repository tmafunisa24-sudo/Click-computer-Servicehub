// lib/views/home/home_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'admin_home_view.dart';
import 'client_home_view.dart';
import 'technician_home_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().user?.role ?? '';

    if (role == 'Admin') return const AdminHomeView();
    if (role == 'Technician') return const TechnicianHomeView();
    return const ClientHomeView();
  }
}