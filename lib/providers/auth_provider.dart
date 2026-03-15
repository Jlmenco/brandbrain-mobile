import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  bool _authenticated = false;
  List<Organization> _orgs = [];
  Organization? _selectedOrg;
  List<CostCenter> _costCenters = [];
  CostCenter? _selectedCC;

  bool get loading => _loading;
  bool get authenticated => _authenticated;
  List<Organization> get orgs => _orgs;
  Organization? get selectedOrg => _selectedOrg;
  List<CostCenter> get costCenters => _costCenters;
  CostCenter? get selectedCC => _selectedCC;
  ApiClient get api => _api;

  Future<void> init() async {
    final token = await _api.getToken();
    if (token != null) {
      try {
        _orgs = await _api.listOrgs();
        if (_orgs.isNotEmpty) {
          _selectedOrg = _orgs.first;
          await _loadCostCenters();
        }
        _authenticated = true;
      } catch (_) {
        await _api.clearToken();
        _authenticated = false;
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _api.login(email, password);
    _orgs = await _api.listOrgs();
    if (_orgs.isNotEmpty) {
      _selectedOrg = _orgs.first;
      await _loadCostCenters();
    }
    _authenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearToken();
    _authenticated = false;
    _orgs = [];
    _selectedOrg = null;
    _costCenters = [];
    _selectedCC = null;
    notifyListeners();
  }

  void selectOrg(Organization org) {
    _selectedOrg = org;
    _loadCostCenters();
    notifyListeners();
  }

  Future<void> _loadCostCenters() async {
    if (_selectedOrg == null) return;
    try {
      _costCenters = await _api.listCostCenters(_selectedOrg!.id);
      _selectedCC = _costCenters.isNotEmpty ? _costCenters.first : null;
    } catch (_) {
      _costCenters = [];
      _selectedCC = null;
    }
  }
}
