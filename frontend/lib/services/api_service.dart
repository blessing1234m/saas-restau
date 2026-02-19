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

  /// Get admin's établissement with dashboard data
  static Future<Map<String, dynamic>> getAdminEtablissement(String token) async {
    try {
      final response = await getWithAuth('/admin-etablissements/mon-etablissement', token);
      
      print('[API] Response status: ${response.statusCode}');
      print('[API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 403) {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'Accès refusé';
        throw Exception(message);
      } else if (response.statusCode == 404) {
        throw Exception('Établissement non trouvé.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ?? 'Erreur lors du chargement de l\'établissement');
        } catch (e) {
          throw Exception('Erreur: ${response.statusCode} - ${response.body}');
        }
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Erreur réseau: ${e.toString()}');
    }
  }

  // ========== SOUS-RESTAURANTS ==========

  /// Create a new sous-restaurant
  static Future<SousRestaurant> createSousRestaurant({
    required String nom,
    String? description,
    required String token,
  }) async {
    final response = await postWithAuth(
      '/admin-etablissements/sous-restaurants',
      token,
      {
        'nom': nom,
        if (description != null) 'description': description,
      },
    );

    if (response.statusCode == 201) {
      return SousRestaurant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la création du sous-restaurant');
    }
  }

  /// Get all sous-restaurants
  static Future<List<SousRestaurant>> getSousRestaurants(String token) async {
    final response = await getWithAuth('/admin-etablissements/sous-restaurants', token);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => SousRestaurant.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors du chargement des sous-restaurants');
    }
  }

  /// Get a specific sous-restaurant
  static Future<SousRestaurant> getSousRestaurant(
    String sousRestaurantId,
    String token,
  ) async {
    final response = await getWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId',
      token,
    );

    if (response.statusCode == 200) {
      return SousRestaurant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du chargement du sous-restaurant');
    }
  }

  /// Update a sous-restaurant
  static Future<SousRestaurant> updateSousRestaurant({
    required String sousRestaurantId,
    String? nom,
    String? description,
    required String token,
  }) async {
    final response = await putWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId',
      token,
      {
        if (nom != null) 'nom': nom,
        if (description != null) 'description': description,
      },
    );

    if (response.statusCode == 200) {
      return SousRestaurant.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la modification du sous-restaurant');
    }
  }

  /// Delete a sous-restaurant
  static Future<void> deleteSousRestaurant(
    String sousRestaurantId,
    String token,
  ) async {
    final response = await deleteWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId',
      token,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du sous-restaurant');
    }
  }

  // ========== CATEGORIES ==========

  /// Create a new category
  static Future<Categorie> createCategorie({
    required String sousRestaurantId,
    required String nom,
    String? description,
    String? photoAffichage,
    int? ordre,
    required String token,
  }) async {
    final response = await postWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories',
      token,
      {
        'nom': nom,
        if (description != null) 'description': description,
        if (photoAffichage != null) 'photoAffichage': photoAffichage,
        if (ordre != null) 'ordre': ordre,
      },
    );

    if (response.statusCode == 201) {
      return Categorie.fromJson(jsonDecode(response.body));
    } else {
      print('[API] Erreur création catégorie - Status: ${response.statusCode}');
      print('[API] Response body: ${response.body}');
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg);
    }
  }

  /// Get all categories for a sous-restaurant
  static Future<List<Categorie>> getCategories(
    String sousRestaurantId,
    String token,
  ) async {
    final response = await getWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories',
      token,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Categorie.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors du chargement des catégories');
    }
  }

  /// Get a specific category
  static Future<Categorie> getCategorie(
    String sousRestaurantId,
    String categorieId,
    String token,
  ) async {
    final response = await getWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories/$categorieId',
      token,
    );

    if (response.statusCode == 200) {
      return Categorie.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du chargement de la catégorie');
    }
  }

  /// Update a category
  static Future<Categorie> updateCategorie({
    required String sousRestaurantId,
    required String categorieId,
    String? nom,
    String? description,
    String? photoAffichage,
    int? ordre,
    required String token,
  }) async {
    final response = await putWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories/$categorieId',
      token,
      {
        if (nom != null) 'nom': nom,
        if (description != null) 'description': description,
        if (photoAffichage != null) 'photoAffichage': photoAffichage,
        if (ordre != null) 'ordre': ordre,
      },
    );

    if (response.statusCode == 200) {
      return Categorie.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la modification de la catégorie');
    }
  }

  /// Delete a category
  static Future<void> deleteCategorie(
    String sousRestaurantId,
    String categorieId,
    String token,
  ) async {
    final response = await deleteWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories/$categorieId',
      token,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression de la catégorie');
    }
  }

  // ========== PLATS ==========

  /// Create a new plat
  static Future<Plat> createPlat({
    required String sousRestaurantId,
    required String categorieId,
    required String nom,
    String? description,
    required double prix,
    List<String>? images,
    required String token,
  }) async {
    final response = await postWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories/$categorieId/plats',
      token,
      {
        'nom': nom,
        if (description != null) 'description': description,
        'prix': prix,
        if (images != null && images.isNotEmpty) 'images': images,
      },
    );

    if (response.statusCode == 201) {
      return Plat.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la création du plat');
    }
  }

  /// Get all plats for a category
  static Future<List<Plat>> getPlats(
    String sousRestaurantId,
    String categorieId,
    String token,
  ) async {
    final response = await getWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories/$categorieId/plats',
      token,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Plat.fromJson(e)).toList();
    } else {
      throw Exception('Erreur lors du chargement des plats');
    }
  }

  /// Get a specific plat
  static Future<Plat> getPlat(
    String sousRestaurantId,
    String categorieId,
    String platId,
    String token,
  ) async {
    final response = await getWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories/$categorieId/plats/$platId',
      token,
    );

    if (response.statusCode == 200) {
      return Plat.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du chargement du plat');
    }
  }

  /// Update a plat
  static Future<Plat> updatePlat({
    required String sousRestaurantId,
    required String categorieId,
    required String platId,
    String? nom,
    String? description,
    double? prix,
    List<String>? images,
    required String token,
  }) async {
    final response = await putWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories/$categorieId/plats/$platId',
      token,
      {
        if (nom != null) 'nom': nom,
        if (description != null) 'description': description,
        if (prix != null) 'prix': prix,
        if (images != null) 'images': images,
      },
    );

    if (response.statusCode == 200) {
      return Plat.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la modification du plat');
    }
  }

  /// Delete a plat
  static Future<void> deletePlat(
    String sousRestaurantId,
    String categorieId,
    String platId,
    String token,
  ) async {
    final response = await deleteWithAuth(
      '/admin-etablissements/sous-restaurants/$sousRestaurantId/categories/$categorieId/plats/$platId',
      token,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du plat');
    }
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) {
        return data['message'];
      }
      if (data is String) {
        return data;
      }
      return 'Erreur lors de la création de la catégorie (code ${response.statusCode})';
    } catch (_) {
      return 'Erreur lors de la création de la catégorie (code ${response.statusCode})';
    }
  }
}
