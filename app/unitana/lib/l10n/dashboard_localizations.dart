import 'package:flutter/material.dart';

import 'localization_seed.dart';
import 'localization_seed_es.dart';
import 'localization_seed_fr.dart';
import 'localization_seed_pt.dart';

/// Minimal runtime localization lookup for Pack H pilot wiring.
///
/// This intentionally uses seeded key/value tables with English fallback so we
/// can migrate surfaces incrementally before full ARB generation is introduced.
class DashboardLocalizations {
  final Locale locale;

  const DashboardLocalizations(this.locale);

  static DashboardLocalizations of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    return DashboardLocalizations(locale);
  }

  String text(
    String key, {
    Map<String, String> params = const <String, String>{},
    String? fallback,
  }) {
    final languageCode = locale.languageCode;
    final localized = _lookup(languageCode, key);
    if (localized != null) {
      return _applyParams(localized, params);
    }

    final english = _lookup('en', key);
    if (english != null) {
      return _applyParams(
        _autoTranslateIfNeeded(english, languageCode),
        params,
      );
    }

    if (fallback != null) {
      return _applyParams(
        _autoTranslateIfNeeded(fallback, languageCode),
        params,
      );
    }

    final template = key;
    return _applyParams(template, params);
  }

  static String resolveForLocale({
    required Locale locale,
    required String key,
    Map<String, String> params = const <String, String>{},
    String? fallback,
  }) {
    return DashboardLocalizations(
      locale,
    ).text(key, params: params, fallback: fallback);
  }

  static String? _lookup(String languageCode, String key) {
    final table = _seedByLanguageCode[languageCode];
    return table?[key];
  }

  static String _applyParams(String template, Map<String, String> params) {
    var output = template;
    for (final entry in params.entries) {
      output = output.replaceAll('{${entry.key}}', entry.value);
    }
    return output;
  }

  static String _autoTranslateIfNeeded(String text, String languageCode) {
    switch (languageCode) {
      case 'pt':
        return _replaceDictionary(text, _ptDictionary);
      case 'fr':
        return _replaceDictionary(text, _frDictionary);
      default:
        return text;
    }
  }

  static String _replaceDictionary(
    String text,
    Map<String, String> dictionary,
  ) {
    var out = text;
    for (final entry in dictionary.entries) {
      out = out.replaceAll(entry.key, entry.value);
    }
    return out;
  }

  static const Map<String, String> _ptDictionary = <String, String>{
    'Weather': 'Meteorologia',
    'Time': 'Tempo',
    'Settings': 'Definicoes',
    'Profiles': 'Perfis',
    'Profile': 'Perfil',
    'Language': 'Idioma',
    'Theme': 'Tema',
    'About': 'Sobre',
    'Licenses': 'Licencas',
    'History': 'Historico',
    'Clear History': 'Limpar historico',
    'Clear': 'Limpar',
    'Convert': 'Converter',
    'Swap': 'Trocar',
    'Close': 'Fechar',
    'Search': 'Pesquisar',
    'Choose': 'Escolher',
    'Most recent': 'Mais recente',
    'Results': 'Resultados',
    'No matching tools.': 'Sem ferramentas correspondentes.',
    'No tools yet.': 'Sem ferramentas ainda.',
    'City not set': 'Cidade nao definida',
    'Destination': 'Destino',
    'Home': 'Casa',
    'Updated': 'Atualizado',
    'Stale': 'Desatualizado',
    'Retry': 'Tentar novamente',
    'Open menu': 'Abrir menu',
    'Open tools': 'Abrir ferramentas',
    'Edit Widgets': 'Editar widgets',
    'Done': 'Concluido',
    'Cancel': 'Cancelar',
    'Delete': 'Eliminar',
    'Add Widget': 'Adicionar widget',
    'Tool': 'Ferramenta',
    'dashboard': 'painel',
    'Height': 'Altura',
    'Weight': 'Peso',
    'Distance': 'Distancia',
    'Speed': 'Velocidade',
    'Temperature': 'Temperatura',
    'Pressure': 'Pressao',
    'Volume': 'Volume',
    'Area': 'Area',
    'Length': 'Comprimento',
    'Liquids': 'Liquidos',
    'Baking': 'Culinaria',
    'Pace': 'Ritmo',
    'Currency': 'Moeda',
    'Data Storage': 'Armazenamento',
    'Jet Lag': 'Jet Lag',
    'World Time Map': 'Mapa de fusos',
    'Paper Sizes': 'Tamanhos de papel',
    'Mattress Sizes': 'Tamanhos de colchao',
    'Shoe Sizes': 'Tamanhos de sapatos',
    'Shoes': 'Sapatos',
  };

  static const Map<String, String> _frDictionary = <String, String>{
    'Weather': 'Meteo',
    'Time': 'Heure',
    'Settings': 'Parametres',
    'Profiles': 'Profils',
    'Profile': 'Profil',
    'Language': 'Langue',
    'Theme': 'Theme',
    'About': 'A propos',
    'Licenses': 'Licences',
    'History': 'Historique',
    'Clear History': 'Effacer historique',
    'Clear': 'Effacer',
    'Convert': 'Convertir',
    'Swap': 'Permuter',
    'Close': 'Fermer',
    'Search': 'Rechercher',
    'Choose': 'Choisir',
    'Most recent': 'Le plus recent',
    'Results': 'Resultats',
    'No matching tools.': 'Aucun outil correspondant.',
    'No tools yet.': "Pas d'outils pour l'instant.",
    'City not set': 'Ville non definie',
    'Destination': 'Destination',
    'Home': 'Domicile',
    'Updated': 'Mis a jour',
    'Stale': 'Obsolete',
    'Retry': 'Reessayer',
    'Open menu': 'Ouvrir menu',
    'Open tools': 'Ouvrir outils',
    'Edit Widgets': 'Modifier widgets',
    'Done': 'Termine',
    'Cancel': 'Annuler',
    'Delete': 'Supprimer',
    'Add Widget': 'Ajouter widget',
    'Height': 'Taille',
    'Weight': 'Poids',
    'Distance': 'Distance',
    'Speed': 'Vitesse',
    'Temperature': 'Temperature',
    'Pressure': 'Pression',
    'Volume': 'Volume',
    'Area': 'Surface',
    'Length': 'Longueur',
    'Liquids': 'Liquides',
    'Baking': 'Cuisine',
    'Pace': 'Allure',
    'Currency': 'Devise',
    'Data Storage': 'Stockage',
    'Jet Lag': 'Decalage horaire',
    'Paper Sizes': 'Formats papier',
    'Mattress Sizes': 'Tailles matelas',
    'Shoe Sizes': 'Pointures',
    'Shoes': 'Chaussures',
  };

  static const Map<String, Map<String, String>> _seedByLanguageCode =
      <String, Map<String, String>>{
        'en': LocalizationSeed.enUs,
        'es': LocalizationSeedEs.es419,
        'fr': LocalizationSeedFr.frFr,
        'pt': LocalizationSeedPt.ptPt,
      };
}
