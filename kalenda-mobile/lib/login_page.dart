import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/animations.dart';
import 'core/api_client.dart';
import 'core/colors.dart';
import 'data/local_store.dart';

/// Phrases affichees tant que l'API n'a pas repondu.
const _fallbackPhrases = [
  'Tableaux, circuits, interventions et consommables.',
  'Un outil par métier, adapté à votre façon de travailler.',
];

/// Client ID Google, injecte a la compilation.
///
/// Vide tant qu'aucun client OAuth n'est configure : le bouton Google est
/// alors masque plutot que de proposer un ecran qui echouerait.
///
/// ```sh
/// flutter run --dart-define=KALENDA_GOOGLE_CLIENT_ID=<web-client-id>
/// ```
const String _googleClientId = String.fromEnvironment(
  'KALENDA_GOOGLE_CLIENT_ID',
);

bool get _googleEnabled => _googleClientId.trim().isNotEmpty;

/// Etapes du parcours d'inscription, dans l'ordre.
const _steps = ['Identité', 'Module', 'Métier'];

/// Mode de saisie du champ identifiant.
enum _IdKind { email, phone }

/// Ecran de connexion et d'inscription d'Alliya Kalenda.
///
/// L'inscription n'est pas un formulaire : c'est un parcours en trois etapes.
/// On commence par l'identite, puis l'utilisateur choisit son module
/// d'activite — le catalogue vient de l'API, pas du code — et enfin sa
/// specialite, dont les champs sont ceux du module choisi.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.store});

  final LocalStore store;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  // Un seul champ : e-mail ou numero. Le backend decide via la presence
  // d'un « @ », nous n'imposons pas de choisir a l'avance.
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  // Nom de famille puis prenom, saisis separement.
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  // Date de naissance facultative, choisie dans un selecteur natif.
  DateTime? _birthDate;

  /// Specialite : un controleur par champ declare par le module choisi.
  final _speciality = <String, TextEditingController>{};

  bool _register = false;
  bool _busy = false;
  String? _error;

  int _step = 0;
  String? _moduleId;

  /// Jeton Google en attente quand le compte n'existe pas encore.
  ///
  /// L'ecran bascule alors sur le parcours en gardant le jeton : sans cela,
  /// il faudrait resselectionner le compte Google apres avoir choisi le
  /// module et saisi le mot de passe.
  String? _pendingGoogle;
  String? _pendingGoogleMessage;

  /// Pays dont l'indicatif est applique aux numeros saisis.
  String _country = kDefaultCountry;

  /// E-mail ou telephone : le choix est fait au bouton, pas deduit.
  _IdKind _identifierKind = _IdKind.email;

  // Catalogue servi par l'API.
  List<KalendaModule> _modules = const [];
  bool _loadingModules = true;
  bool _modulesError = false;

  KalendaModule? get _module {
    if (_moduleId == null) return null;
    for (final module in _modules) {
      if (module.id == _moduleId) return module;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _identifier.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    for (final controller in _speciality.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Charge le catalogue des modules. Public : aucune session requise.
  Future<void> _loadModules() async {
    try {
      final modules = await widget.store.modules();
      if (!mounted) return;
      setState(() {
        _modules = modules;
        _loadingModules = false;
        _modulesError = modules.isEmpty;
      });
      // Un module disponible est propose par defaut.
      if (modules.isNotEmpty) {
        final first = modules.firstWhere(
          (module) => module.isAvailable,
          orElse: () => modules.first,
        );
        _moduleId ??= first.id;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingModules = false;
        _modulesError = true;
      });
    }
  }

  void _resetWizard() {
    for (final controller in _speciality.values) {
      controller.dispose();
    }
    _speciality.clear();
    setState(() {
      _step = 0;
      _error = null;
    });
  }

  /// Un controleur par champ du module, cree a la volee.
  TextEditingController _controllerFor(String key) {
    return _speciality.putIfAbsent(key, TextEditingController.new);
  }

  void _next() {
    if (_step == 0 && !(_formKey.currentState?.validate() ?? false)) return;
    if (_register && _password.text != _passwordConfirm.text) {
      setState(() => _error = 'Les deux mots de passe ne correspondent pas.');
      return;
    }
    if (_step == 1 && _moduleId == null) {
      setState(() => _error = 'Choisissez le module de votre métier.');
      return;
    }
    setState(() {
      _step += 1;
      _error = null;
    });
  }

  /// Le compte n'est cree qu'a la derniere etape.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_register && _moduleId == null) {
      setState(() => _error = 'Choisissez le module de votre métier.');
      return;
    }
    if (_register && _password.text != _passwordConfirm.text) {
      setState(() => _error = 'Les deux mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential = _pendingGoogle;
      String value(String key) => _speciality[key]?.text.trim() ?? '';
      if (_register && credential != null) {
        // Identite deja verifiee par Google : ni e-mail ni nom ne sont
        // redemandes, seul le mot de passe et le module restent a choisir.
        await widget.store.registerWithGoogle(
          credential: credential,
          password: _password.text,
          module: _moduleId ?? '',
          jobTitle: value('jobTitle'),
          companyName: value('companyName'),
          phone: value('phone'),
          certifications: value('certifications'),
        );
      } else if (_register) {
        // Le mode choisi decide du champ envoye : on n'en deduit rien de la
        // saisie, l'utilisateur l'a choisi explicitement.
        final byPhone = _identifierKind == _IdKind.phone;
        final identifier = byPhone
            ? toIdentifier(_identifier.text, dialFor(_country))
            : _identifier.text.trim();
        await widget.store.register(
          email: byPhone ? null : identifier,
          phone: byPhone ? identifier : null,
          password: _password.text,
          lastName: _lastName.text.trim(),
        firstName: _firstName.text.trim(),
        // Date facultative : envoyee seulement si elle a ete choisie.
        birthDate: _birthDate == null
            ? null
            : '${_birthDate!.year.toString().padLeft(4, '0')}-'
                '${_birthDate!.month.toString().padLeft(2, '0')}-'
                '${_birthDate!.day.toString().padLeft(2, '0')}',
          module: _moduleId ?? '',
          jobTitle: value('jobTitle'),
          companyName: value('companyName'),
          certifications: value('certifications'),
        );
      } else {
        final byPhone = _identifierKind == _IdKind.phone;
        await widget.store.login(
          byPhone
              ? toIdentifier(_identifier.text, dialFor(_country))
              : _identifier.text.trim(),
          _password.text,
        );
      }
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Connexion Google : le plugin renvoie un jeton d'identite que le backend
  /// verifie avant de delivrer la session. Aucun secret ne transite par l'app.
  Future<void> _submitGoogle() async {
    // Le bouton reste affiche meme sans Client ID : on explique alors ce
    // qu'il manque plutot que de laisser une erreur incomprehensible.
    if (!_googleEnabled) {
      setState(
        () => _error =
            'Connexion Google non configurée. Lancez avec '
            '--dart-define=KALENDA_GOOGLE_CLIENT_ID=<server-client-id>.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await GoogleSignIn.instance.initialize(serverClientId: _googleClientId);
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw "Google n'a pas renvoyé de jeton d'identité.";
      }
      try {
        await widget.store.loginWithGoogle(idToken);
      } on GoogleSignupRequired catch (required) {
        // Compte inconnu : on bascule sur le parcours en gardant le jeton.
        // Aucun mot de passe n'a ete emis par le backend a ce stade.
        _resetWizard();
        setState(() {
          _pendingGoogle = idToken;
          _pendingGoogleMessage = required.message;
          _register = true;
          _password.clear();
          _passwordConfirm.clear();
        });
      }
    } on Exception catch (error) {
      // L'utilisateur a annule la selection : pas une erreur a afficher.
      if (!error.toString().contains('canceled')) {
        setState(() => _error = '$error');
      }
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        // Sur grand ecran (desktop, tablette paysage), on reprend la mise en
        // page du web : panneau de marque a gauche, formulaire a droite.
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Seuil unique de bascule : il pilote a la fois la disposition et
            // l'affichage du bandeau de marque, pour eviter les deux versions
            // de l'ecran qui cohabitent.
            final wide = constraints.maxWidth >= 900;
            return wide
                ? Row(
                    children: [
                      Expanded(flex: 5, child: _brandPanel()),
                      Expanded(
                        flex: 4,
                        child: Container(
                          color: kAppBackground,
                          alignment: Alignment.center,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 32,
                            ),
                            // `Center` est necessaire : un `ConstrainedBox` seul
                            // s'aligne a gauche dans la zone de defilement, la
                            // colonne de formulaire n'etait donc pas centree.
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                child: _form(wide: true),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    // Hauteur minimale = ecran moins le padding : la colonne
                    // se centre quand elle tient, et remonte des que le
                    // clavier ou une etape plus longue la ferait deborder.
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 48).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: _form(wide: false),
                        ),
                      ),
                    ),
                  );
          },
        ),
      ),
    );
  }

  /// Contenu commun aux deux dispositions : la carte du formulaire.
  Widget _form({required bool wide}) => Form(
    key: _formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Le bandeau de marque n'a pas sa place dans la colonne de formulaire
        // quand le panneau lateral s'en charge.
        if (!wide) ...[const _Brand(), const SizedBox(height: 18)],
        _card(),
      ],
    ),
  );

  /// Panneau de gauche sur grand ecran : marque, promesse et module mis en
  /// avant. Les textes des modules viennent de l'API.
  Widget _brandPanel() {
    final featured = _modules.isEmpty
        ? null
        : _modules.firstWhere(
            (module) => module.isAvailable,
            orElse: () => _modules.first,
          );

    // Une phrase par module : elles defilent sous le titre plutot que de
    // s'empiler, ce qui garde le panneau lisible sans le rallonger.
    final phrases = _modules
        .expand((module) => [module.promise, module.label])
        .where((text) => text.isNotEmpty)
        .toList();

    return Container(
      color: kNavy,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      child: Stack(
        children: [
          // Halos decoratifs, dans la tonalite de la marque.
          Positioned(left: -70, top: 40, child: _Glow(kAccent, .22)),
          Positioned(right: -50, bottom: 60, child: _Glow(kAmber, .12)),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Brand(onPanel: true),
                  const SizedBox(height: 28),
                  Text(
                    'Tout votre travail,\nau même endroit.',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Phrases rotatives : le message change selon le module.
                  SizedBox(
                    height: 44,
                    child: RotatingPhrases(
                      phrases: phrases.isEmpty ? _fallbackPhrases : phrases,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .6),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (featured != null) ...[
                    const SizedBox(height: 26),
                    _featuredCard(featured),
                  ],
                  if (_modules.any((module) => !module.isAvailable)) ...[
                    const SizedBox(height: 22),
                    const _UpcomingLabel(),
                    const SizedBox(height: 8),
                    _UpcomingModules(
                      modules: _modules
                          .where((module) => !module.isAvailable)
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cartouche du module disponible, avec ses fonctions cles.
  Widget _featuredCard(KalendaModule module) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: .15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              module.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kAccent.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Disponible',
                style: TextStyle(
                  color: kAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (module.highlights.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final text in module.highlights.take(4))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: kAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    ),
  );

  /// Carte blanche qui porte le formulaire : contraste lisible sur le navy.
  Widget _card() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google n'apparait qu'en connexion : l'inscription passe par e-mail,
        // car le parcours a besoin du module et de la specialite.
        // Le bouton reste visible meme sans Client ID : meme apparence que
        // sur le web, et le clic explique ce qu'il manque.
        if (!_register) ...[
          _googleButton(),
          const SizedBox(height: 12),
          const _OrDivider(),
          const SizedBox(height: 12),
        ] else
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'PAR E-MAIL',
              style: TextStyle(
                color: Color(0xff9aa9b8),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ),

        // Titre de l'ecran, suivi du lien de bascule. Le SegmentedButton est
        // volontairement abandonne : il occupait une ligne entiere et
        // concurrençait le titre, alors qu'un seul mot a changer suffit.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _register ? 'Créer un compte' : 'Connexion',
                    style: GoogleFonts.spaceGrotesk(
                      color: kNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _register
                        ? 'Choisissez votre module, on adapte l\'outil.'
                        : 'Accédez à votre module et vos données.',
                    style: const TextStyle(
                      color: Color(0xff6b7c8d),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            // Aligne sur la ligne de titre, pas sur le bas du bloc.
            // Visible dans les deux sens : le masquer en inscription piegeait
            // l'utilisateur dans le parcours, qui n'a pas de bouton « quitter ».
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
                onTap: _toggleMode,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  _register ? 'J\'ai déjà un compte' : 'Créer un compte',
                  style: const TextStyle(
                    color: kAccent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_register) ...[const SizedBox(height: 14), _stepper()],
        const SizedBox(height: 14),

        // Etapes du parcours d'inscription.
        ..._currentStep(),

        // Sous la connexion : sans bouton Google configure, il ne resterait
        // que deux champs et un bouton, ce qui donne un formulaire seeme vide.
        if (!_register) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(
                () => _error =
                    'La réinitialisation arrive bientôt. Écrivez-nous si besoin.',
              ),
              style: TextButton.styleFrom(
                foregroundColor: kAccent,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],

        ..._navigation(),
      ],
    ),
  );

  /// Bascule connexion / inscription.
  void _toggleMode() {
    setState(() => _register = !_register);
    if (_register) {
      _resetWizard();
    } else {
      setState(() => _error = null);
    }
  }

  /// Les champs correspondant a l'etape courante.
  List<Widget> _currentStep() {
    if (!_register || _step == 0) {
      // Identite Google : nom et contact sont deja connus et verifies,
      // seul le mot de passe reste a saisir.
      if (_register && _pendingGoogle != null) {
        return [
          if (_pendingGoogleMessage != null) ...[
            _Notice(
              text:
                  '$_pendingGoogleMessage Choisissez votre module et créez votre mot de passe.',
            ),
            const SizedBox(height: 12),
          ],
          _passwordField(),
          const SizedBox(height: 10),
          _passwordConfirmField(),
        ];
      }
      return [
        if (_register) ...[
          _nameFields(),
          const SizedBox(height: 10),
          // Date facultative : l'utilisateur peut la completer plus tard
          // depuis son profil.
          _birthDateField(),
          const SizedBox(height: 10),
        ],
        _identifierField(),
        const SizedBox(height: 10),
        _passwordField(),
        if (_register) ...[const SizedBox(height: 10), _passwordConfirmField()],
      ];
    }

    if (_step == 1) return _moduleStep();

    return _specialityStep();
  }

  /// Style de saisie commun a tous les champs.
  ///
  /// `isDense` et un `contentPadding` explicite evitent la hauteur par defaut
  /// de Material 3, qui allongeait le formulaire de plusieurs lignes.
  InputDecoration _input(String label, {String? hint, Widget? prefix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xfff7fafc),
        prefixIcon: prefix,
        prefixIconConstraints: prefix == null
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : const BoxConstraints(minWidth: 92, minHeight: 32),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffe3eaf1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffe3eaf1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kAccent, width: 1.4),
        ),
      );

  /// Nom et post-nom, saisis separement comme le veut l'usage local.
  Widget _nameFields() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: TextFormField(
          controller: _lastName,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 14),
          decoration: _input('Nom'),
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Requis' : null,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: _firstName,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 14),
          decoration: _input('Post-nom'),
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Requis' : null,
        ),
      ),
    ],
  );

  /// Date de naissance, facultative.
  ///
  /// Un `showDatePicker` plutot qu'une saisie libre : le format ne peut pas
  /// etre faux, et le clavier mobile propose la bonnevue. La date est
  /// bornee a aujourd'hui.
  Widget _birthDateField() {
    final today = DateTime.now();
    final text = _birthDate == null
        ? ''
        : '${_birthDate!.year.toString().padLeft(4, '0')}-'
            '${_birthDate!.month.toString().padLeft(2, '0')}-'
            '${_birthDate!.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _birthDate ?? DateTime(today.year - 25),
          // On ne saisit pas une date future.
          firstDate: DateTime(today.year - 100),
          lastDate: today,
        );
        if (picked != null) setState(() => _birthDate = picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _input(
          'Date de naissance (facultatif)',
        ).copyWith(
          suffixIcon: const Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: Color(0xff9aa9b8),
          ),
        ),
        child: Text(
          text.isEmpty ? 'Choisir une date' : text,
          style: TextStyle(
            fontSize: 14,
            color: text.isEmpty ? const Color(0xff9aa9b8) : const Color(0xff16202c),
          ),
        ),
      ),
    );
  }

  /// Un seul champ pour l'e-mail ou le numero : le choix est fait au
  /// bouton, pas deduit de ce que l'utilisateur tape.
  Widget _identifierField() {
    final byPhone = _identifierKind == _IdKind.phone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Deux onglets plutot qu'un champ melange : l'utilisateur sait ce
        // qui est attendu, et l'indicatif n'apparait que s'il est utile.
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xfff7fafc),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              for (final kind in _IdKind.values)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _identifierKind = kind),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _identifierKind == kind
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _identifierKind == kind
                            ? const [
                                BoxShadow(
                                  color: Color(0x140b2240),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        kind == _IdKind.email ? 'E-mail' : 'Téléphone',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _identifierKind == kind
                              ? kAccent
                              : const Color(0xff6b7c8d),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (byPhone)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CountryButton(country: _country, onTap: _pickCountry),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _identifier,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 14),
                  decoration: _input('Numéro de téléphone'),
                  validator: (value) =>
                      (value == null || value.trim().length < 3)
                      ? 'Saisissez votre numéro'
                      : null,
                ),
              ),
            ],
          )
        else
          TextFormField(
            controller: _identifier,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14),
            decoration: _input(
              'Adresse e-mail',
              hint: 'ex. contact@alliyakalenda.cd',
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Saisissez votre e-mail';
              if (!text.contains('@')) return 'E-mail invalide';
              return null;
            },
          ),
      ],
    );
  }

  /// Bouton affichant l'indicatif courant ; il ouvre la feuille de recherche.
  Future<void> _pickCountry() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => _CountrySheet(
        selected: _country,
        onSelected: (code) => Navigator.of(context).pop(code),
      ),
    );
    if (selected != null) setState(() => _country = selected);
  }

  Widget _passwordField() => TextFormField(
    controller: _password,
    obscureText: true,
    style: const TextStyle(fontSize: 14),
    decoration: _input('Mot de passe'),
    validator: (value) =>
        (value ?? '').length < 8 ? '8 caractères minimum' : null,
    onFieldSubmitted: (_) => _register ? _next() : _submit(),
  );

  /// A l'inscription, le mot de passe se tape deux fois : une faute de frappe
  /// dans un identifiant est irreversible.
  Widget _passwordConfirmField() => TextFormField(
    controller: _passwordConfirm,
    obscureText: true,
    style: const TextStyle(fontSize: 14),
    decoration: _input(
      'Confirmer le mot de passe',
      hint: 'Retapez votre mot de passe',
    ),
    validator: (value) => value != _password.text
        ? 'Les deux mots de passe ne correspondent pas'
        : null,
    onFieldSubmitted: (_) => _register ? _next() : _submit(),
  );

  /// Etape 2 : le module, liste servie par l'API.
  List<Widget> _moduleStep() {
    if (_loadingModules) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }

    return [
      const Text(
        'Quel module utilisez-vous ?',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 2),
      Text(
        "L'application se configure autour de votre métier.",
        style: TextStyle(
          fontSize: 11.5,
          color: Colors.black.withValues(alpha: .55),
        ),
      ),
      if (_modulesError) ...[
        const SizedBox(height: 10),
        const _Notice(text: "Catalogue indisponible. Vérifiez l'API."),
      ],
      const SizedBox(height: 10),
      for (final module in _modules) ...[
        _ModuleTile(
          module: module,
          selected: module.id == _moduleId,
          onTap: module.isAvailable
              ? () => setState(() {
                  _moduleId = module.id;
                  _error = null;
                })
              : null,
        ),
        const SizedBox(height: 6),
      ],
    ];
  }

  /// Etape 3 : les champs de specialite declares par le module.
  List<Widget> _specialityStep() {
    final module = _module;
    if (module == null) return const [];

    return [
      if (module.highlights.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kAccent.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kAccent.withValues(alpha: .3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Module ${module.label}',
                style: const TextStyle(
                  color: kAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              for (final text in module.highlights.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: kAccent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xff4a5b6b),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      for (final field in module.fields) ...[
        if (field.isSelect) _selectField(field) else _textField(field),
        const SizedBox(height: 10),
      ],
    ];
  }

  /// Liste deroulante pour un champ de type `select`.
  Widget _selectField(ModuleField field) {
    final controller = _controllerFor(field.key);
    return DropdownButtonFormField<String>(
      initialValue: controller.text.isEmpty ? null : controller.text,
      isExpanded: true,
      iconSize: 18,
      style: const TextStyle(fontSize: 14),
      decoration: _input(field.displayLabel),
      items: field.options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (value) => setState(() => controller.text = value ?? ''),
      validator: (value) => (value == null || value.isEmpty)
          ? 'Choisissez ${field.label.toLowerCase()}'
          : null,
    );
  }

  /// Saisie libre pour un champ de type `text`.
  Widget _textField(ModuleField field) {
    final controller = _controllerFor(field.key);
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: _input(field.displayLabel),
      validator: field.optional
          ? null
          : (value) =>
                (value == null || value.trim().isEmpty) ? 'Champ requis' : null,
    );
  }

  /// Message d'erreur, navigation et validation.
  List<Widget> _navigation() {
    final last = _step == _steps.length - 1;

    return [
      if (_error != null) ...[
        Text(
          _error!,
          style: const TextStyle(
            color: Color(0xffc8453a),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
      ],
      if (_register && !last)
        Row(
          children: [
            if (_step > 0) ...[_backButton(), const SizedBox(width: 8)],
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _next,
                style: _primaryStyle(),
                child: const Text('Continuer'),
              ),
            ),
          ],
        )
      else
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: _primaryStyle(),
          child: Text(
            _busy
                ? 'Connexion…'
                : (_register ? 'Créer mon compte' : 'Se connecter'),
          ),
        ),
    ];
  }

  ButtonStyle _primaryStyle() => FilledButton.styleFrom(
    backgroundColor: kNavy,
    padding: const EdgeInsets.symmetric(vertical: 13),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
  );

  Widget _backButton() => OutlinedButton(
    onPressed: _busy
        ? null
        : () => setState(() {
            _step -= 1;
            _error = null;
          }),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xff5a6b7a),
      side: const BorderSide(color: Color(0xffe3eaf1)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    child: const Text('Retour'),
  );

  /// Fil d'etapes de l'inscription.
  Widget _stepper() => Row(
    children: [
      for (final (index, label) in _steps.indexed)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < _steps.length - 1 ? 6 : 0),
            child: Row(
              children: [
                Container(
                  width: 19,
                  height: 19,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index <= _step ? kNavy : kSurfaceHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    index < _step ? '✓' : '${index + 1}',
                    style: TextStyle(
                      color: index <= _step
                          ? Colors.white
                          : const Color(0xff9aa9b8),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: index <= _step ? kNavy : const Color(0xff9aa9b8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  /// Bouton Google. Material n'embarque pas le logo : on dessine le « G ».
  Widget _googleButton() => OutlinedButton.icon(
    onPressed: _busy ? null : _submitGoogle,
    // Material n'embarque pas le logo Google : on rend le tracé officiel via
    // `flutter_svg`. Un « G » blanc dans un cercle bleu n'etait pas le logo et
    // se lisait comme une substitution.
    icon: const _GoogleMark(),
    label: const Text('Continuer avec Google'),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xff16202c),
      padding: const EdgeInsets.symmetric(vertical: 12),
      side: const BorderSide(color: Color(0xffd7dee6)),
      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
    ),
  );
}

/// Logo Google.
///
/// Le tracé est celui du logo officiel declasse a 48 unites : dessine a la
/// main, il ne donnait pas la bonne forme du « G », d'ou l'usage de `flutter_svg`
/// pour restituer exactement les quatre couleurs.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_googleMarkSvg, width: 17, height: 17);
}

/// Logo Google aux couleurs officielles (jaune, rouge, vert, bleu).
const _googleMarkSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">
  <path fill="#FFC107" d="M43.6 20.1H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.4-3.9z"/>
  <path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
  <path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238C29.21 35.091 26.715 36 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>
  <path fill="#1976D2" d="M43.6 20.1H42V20H24v8h11.303c-.792 2.237-2.231 4.166-4.087 5.571l.003-.002 6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.4-3.9z"/>
</svg>
''';

/// Logo et nom.
///
/// La marque est toujours alignee a gauche, comme sur le web. La centrer
/// au-dessus de la carte pleine largeur la detachait visuellement du
/// formulaire : le logo flottait au milieu sans ligne de rappel.
///
/// [onPanel] ajoute l'anneau clair du panneau lateral, ou le logo est pose
/// sur le navy ; sur mobile il n'en a pas besoin.
class _Brand extends StatelessWidget {
  const _Brand({this.onPanel = false});

  final bool onPanel;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      // Le vrai logo de l'application, comme sur le web : l'icone Material
      // ne representait pas la marque. L'asset est deja arrondi, on ne lui
      // ajoute pas de cadre — un double arrondi le rapetissait.
      Image.asset(
        'assets/branding/Alliya-Kalenda-app-icon-bigA-calendar-1024-rounded.png',
        width: onPanel ? 36 : 32,
        height: onPanel ? 36 : 32,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => SizedBox(
          width: onPanel ? 36 : 32,
          height: onPanel ? 36 : 32,
          child: const DecoratedBox(
            decoration: BoxDecoration(color: Color(0x1AFFFFFF)),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      // Meme famille que le reste de l'application (Space Grotesk pour les
      // titres), pour que l'ecran de connexion ne paraisse pas etranger.
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Alliya Kalenda',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          Text(
            'OUTIL MÉTIER',
            style: GoogleFonts.dmSans(
              color: kAccent,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Halo decoratif flou, derriere le contenu du panneau.
class _Glow extends StatelessWidget {
  const _Glow(this.color, this.opacity);

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    height: 220,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: opacity),
    ),
  );
}

/// Titre de la liste des modules a venir.
class _UpcomingLabel extends StatelessWidget {
  const _UpcomingLabel();

  @override
  Widget build(BuildContext context) => Text(
    'PROCHAINEMENT',
    style: TextStyle(
      color: Colors.white.withValues(alpha: .35),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  );
}

/// Modules annonces mais pas encore livres, en pastilles discrete.
class _UpcomingModules extends StatelessWidget {
  const _UpcomingModules({required this.modules});

  final List<KalendaModule> modules;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final module in modules)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: Text(
            module.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .45),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ],
  );
}

/// Carte de module : selectionnable seulement s'il est livre.
class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final KalendaModule module;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = !module.isAvailable;
    return Material(
      color: selected
          ? kAccent.withValues(alpha: .06)
          : const Color(0xfff7fafc),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? kAccent : const Color(0xffe3eaf1),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            module.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: muted ? const Color(0xff9aa9b8) : kNavy,
                            ),
                          ),
                        ),
                        if (muted) ...[
                          const SizedBox(width: 5),
                          const Text(
                            'Bientôt',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff9aa9b8),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (module.promise.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        module.promise,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: muted
                              ? const Color(0xff9aa9b8)
                              : Colors.black.withValues(alpha: .55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 17,
                  color: kAccent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trait de separation « ou par e-mail ».
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(height: 1, color: Color(0xffe3eaf1))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          'ou par e-mail',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: .4),
          ),
        ),
      ),
      const Expanded(child: Divider(height: 1, color: Color(0xffe3eaf1))),
    ],
  );
}

/// Bouton affichant l'indicatif courant, aligne sur la hauteur d'un champ.
class _CountryButton extends StatelessWidget {
  const _CountryButton({required this.country, required this.onTap});

  final String country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dial = dialFor(country);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xfff7fafc),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xffe3eaf1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+$dial',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff16202c),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: Color(0xff9aa9b8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille de recherche du pays.
///
/// Une liste de trente entrees dans une liste deroulante est inutilisable sur
/// telephone : la feuille ajoute un champ de recherche et filtre sur le nom,
/// l'indicatif ou le code.
class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _query = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = filterCountries(_search);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffe3eaf1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _query,
                autofocus: true,
                onChanged: (value) => setState(() => _search = value),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un pays…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun pays trouvé. Saisissez l’indicatif dans le champ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff6b7c8d),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final country = results[index];
                        final active = country.code == widget.selected;
                        return ListTile(
                          dense: true,
                          selected: active,
                          selectedTileColor: kAccent.withValues(alpha: .08),
                          onTap: () => widget.onSelected(country.code),
                          leading: SizedBox(
                            width: 52,
                            child: Text(
                              '+${country.dial}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xff16202c),
                              ),
                            ),
                          ),
                          title: Text(
                            country.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: active ? FontWeight.w700 : null,
                              color: active ? kAccent : const Color(0xff16202c),
                            ),
                          ),
                          trailing: active
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: kAccent,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'information non bloquant.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: kAmber.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xff8a4a12),
      ),
    ),
  );
}
