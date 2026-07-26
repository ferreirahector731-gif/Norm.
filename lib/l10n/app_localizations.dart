import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('it'),
    Locale('pt'),
    Locale('ru'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('ar'),
    Locale('hi'),
    Locale('tr'),
    Locale('pl'),
    Locale('nl'),
    Locale('sv'),
    Locale('da'),
    Locale('fi'),
    Locale('nb'),
    Locale('cs')
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Norm'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Tu espacio. Tus reglas.'**
  String get appTagline;

  /// No description provided for @note.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get note;

  /// No description provided for @doc.
  ///
  /// In es, this message translates to:
  /// **'Doc'**
  String get doc;

  /// No description provided for @canvas.
  ///
  /// In es, this message translates to:
  /// **'Lienzo'**
  String get canvas;

  /// No description provided for @sheet.
  ///
  /// In es, this message translates to:
  /// **'Hoja'**
  String get sheet;

  /// No description provided for @chart.
  ///
  /// In es, this message translates to:
  /// **'Gráfico'**
  String get chart;

  /// No description provided for @task.
  ///
  /// In es, this message translates to:
  /// **'Tarea'**
  String get task;

  /// No description provided for @link.
  ///
  /// In es, this message translates to:
  /// **'Enlace'**
  String get link;

  /// No description provided for @newNote.
  ///
  /// In es, this message translates to:
  /// **'Nueva nota'**
  String get newNote;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @import.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get import;

  /// No description provided for @export.
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get export;

  /// No description provided for @importObsidian.
  ///
  /// In es, this message translates to:
  /// **'Importar Obsidian'**
  String get importObsidian;

  /// No description provided for @importNotion.
  ///
  /// In es, this message translates to:
  /// **'Importar Notion'**
  String get importNotion;

  /// No description provided for @importCsv.
  ///
  /// In es, this message translates to:
  /// **'Importar CSV'**
  String get importCsv;

  /// No description provided for @importJson.
  ///
  /// In es, this message translates to:
  /// **'Importar JSON'**
  String get importJson;

  /// No description provided for @exportMarkdown.
  ///
  /// In es, this message translates to:
  /// **'Exportar Markdown'**
  String get exportMarkdown;

  /// No description provided for @exportJson.
  ///
  /// In es, this message translates to:
  /// **'Exportar JSON (.gz)'**
  String get exportJson;

  /// No description provided for @reindex.
  ///
  /// In es, this message translates to:
  /// **'Reindexar referencias'**
  String get reindex;

  /// No description provided for @migration.
  ///
  /// In es, this message translates to:
  /// **'Migración'**
  String get migration;

  /// No description provided for @session.
  ///
  /// In es, this message translates to:
  /// **'Sesión'**
  String get session;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @guest.
  ///
  /// In es, this message translates to:
  /// **'Invitado'**
  String get guest;

  /// No description provided for @aiMemory.
  ///
  /// In es, this message translates to:
  /// **'Memoria de IA'**
  String get aiMemory;

  /// No description provided for @oneWeek.
  ///
  /// In es, this message translates to:
  /// **'1 semana'**
  String get oneWeek;

  /// No description provided for @oneMonth.
  ///
  /// In es, this message translates to:
  /// **'1 mes'**
  String get oneMonth;

  /// No description provided for @threeMonths.
  ///
  /// In es, this message translates to:
  /// **'3 meses'**
  String get threeMonths;

  /// No description provided for @forever.
  ///
  /// In es, this message translates to:
  /// **'Siempre'**
  String get forever;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal. Por favor reinicia o contacta a soporte.'**
  String get errorGeneric;

  /// No description provided for @errorDbInit.
  ///
  /// In es, this message translates to:
  /// **'Error de inicialización de la base de datos. Reintentando…'**
  String get errorDbInit;

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get loading;

  /// No description provided for @betaBanner.
  ///
  /// In es, this message translates to:
  /// **'Estás usando Norm en fase Beta. Algunas funciones pueden cambiar con el tiempo. Gracias por ayudarnos a construir la mejor experiencia.'**
  String get betaBanner;

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understood;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
