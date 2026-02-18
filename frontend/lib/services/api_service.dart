import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/models/index.dart';

class ApiService {
    /// Crée un nouvel admin établissement
    static Future<void> createAdminEtablissement({
      required String codeAgent,
      required String motDePasse,
      required String etablissementId,
      required String token,
    }) async {
      final response = await postWithAuth(
        '/super-admin/admin-etablissements',
        token,
        {
          'codeAgent': codeAgent,
          'motDePasse': motDePasse,
          'etablissementId': etablissementId,
        },
      );
      if (response.statusCode != 201) {
        throw Exception(jsonDecode(response.body)['message'] ?? "Erreur lors de la création de l'admin");
      }
    }

    /// Modifie un admin établissement
    static Future<void> updateAdminEtablissement({
      required String id,
      required String codeAgent,
      String? motDePasse,
      required String etablissementId,
      required String token,
    }) async {
      final body = {
        'codeAgent': codeAgent,
        'etablissementId': etablissementId,
      };
      if (motDePasse != null && motDePasse.isNotEmpty) {
        body['motDePasse'] = motDePasse;
      }
      final response = await patchWithAuth(
        '/super-admin/admin-etablissement/$id',
        token,
        body,
      );
      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['message'] ?? "Erreur lors de la modification de l'admin");
      }
    }
  /// Login with code agent and password
  static Future<LoginResponse> login({
    required String codeAgent,
    required String motDePasse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.authEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'codeAgent': codeAgent,
          'motDePasse': motDePasse,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LoginResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? AppConstants.errorInvalidCredentials,
        );
      } else {
        throw Exception(AppConstants.errorServerError);
      }
    } on http.ClientException {
      throw Exception(AppConstants.errorNetworkError);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(AppConstants.errorUnknownError);
    }
  }

  /// Make authenticated GET request with token
  static Future<http.Response> getWithAuth(
    String endpoint,
    String token,
  ) async {
    return await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );
  }

  /// Make authenticated POST request with token
  static Future<http.Response> postWithAuth(
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    return await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );
  }

  /// Make authenticated PUT request with token
  static Future<http.Response> putWithAuth(
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    return await http.put(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );
  }

  /// Make authenticated PATCH request with token
  static Future<http.Response> patchWithAuth(
    String endpoint,
    String token,
    Map<String, dynamic>? body,
  ) async {
    return await http.patch(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );
  }

  /// Make authenticated DELETE request with token
  static Future<http.Response> deleteWithAuth(
    String endpoint,
    String token,
  ) async {
    return await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );
  }

  // ========== SUPER ADMIN ENDPOINTS ==========

  /// Get all établissements
  static Future<List<Etablissement>> getEtablissements(String token) async {
    final response = await getWithAuth('/super-admin/etablissements', token);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Etablissement.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors du chargement des établissements');
    }
  }

  /// Get single établissement
  static Future<Etablissement> getEtablissement(String id, String token) async {
    final response =
        await getWithAuth('/super-admin/etablissements/$id', token);

    if (response.statusCode == 200) {
      return Etablissement.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Établissement introuvable');
    }
  }

  /// Create établissement
  static Future<Etablissement> createEtablissement(
    String token,
    String nom,
    String ville,
    String? telephone,
    String? email,
  ) async {
    final response = await postWithAuth(
      '/super-admin/etablissements',
      token,
      {
        'nom': nom,
        'ville': ville,
        'telephone': telephone,
        'email': email,
      },
    );

    if (response.statusCode == 201) {
      return Etablissement.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la création');
    }
  }

  /// Update établissement
  static Future<Etablissement> updateEtablissement(
    String id,
    String token,
    String nom,
    String ville,
    String? telephone,
    String? email,
  ) async {
    final response = await putWithAuth(
      '/super-admin/etablissements/$id',
      token,
      {
        'nom': nom,
        'ville': ville,
        'telephone': telephone,
        'email': email,
      },
    );

    if (response.statusCode == 200) {
      return Etablissement.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la modification');
    }
  }

  /// Toggle établissement state
  static Future<Etablissement> toggleEtablissementState(
    String id,
    String token,
  ) async {
    final response =
        await patchWithAuth('/super-admin/changer-etat-etablissements/$id', token, null);

    if (response.statusCode == 200) {
      return Etablissement.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du changement d\'état');
    }
  }

  /// Delete établissement
  static Future<void> deleteEtablissement(String id, String token) async {
    final response =
        await deleteWithAuth('/super-admin/etablissements/$id', token);

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression');
    }
  }

  /// Get all admin établissements
  static Future<List<AdminEtablissement>> getAdminEtablissements(
    String token,
  ) async {
    final response =
        await getWithAuth('/super-admin/admin-etablissements', token);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AdminEtablissement.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors du chargement des admins');
    }
  }

  /// Toggle admin state
  static Future<void> toggleAdminState(String id, String token) async {
    final response =
        await patchWithAuth('/super-admin/changer-etat-admin/$id', token, null);

    if (response.statusCode != 200) {
      throw Exception('Erreur lors du changement d\'état');
    }
  }

  /// Delete admin établissement
  static Future<void> deleteAdminEtablissement(String id, String token) async {
    final response =
        await deleteWithAuth('/super-admin/admin-etablissements/$id', token);

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression');
    }
  }
}
