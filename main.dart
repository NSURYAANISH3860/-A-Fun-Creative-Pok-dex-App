import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(PokepediaApp());

class PokepediaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poképedia',
      theme: ThemeData(
        primarySwatch: Colors.red,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/* ---------------------------
   Login Screen with Lottie
   --------------------------- */
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  bool _loading = false;

  void _proceed() async {
    setState(() => _loading = true);
    await Future.delayed(Duration(milliseconds: 700));
    final name = _nameCtrl.text.trim().isEmpty ? 'Trainer' : _nameCtrl.text.trim();
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(trainerName: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 600;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24, vertical: 24),
          child: Column(
            children: [
              SizedBox(height: 8),
              Text('Welcome to Poképedia', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Lottie.network(
                    // public lottie json (playful poké-like animation)
                    'https://assets6.lottiefiles.com/packages/lf20_tfb3estd.json',
                    width: isWide ? 420 : 280,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Your Trainer Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading ? SizedBox(width:18,height:18,child: CircularProgressIndicator(strokeWidth:2, color: Colors.white)) : Icon(Icons.play_arrow),
                  label: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Enter Poképedia'),
                  ),
                  onPressed: _loading ? null : _proceed,
                ),
              ),
              SizedBox(height: 6),
              Text('Explore Pokémon, view types & abilities, and have fun!', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------------------
   Home Screen: fetch & show list
   --------------------------- */
class HomeScreen extends StatefulWidget {
  final String trainerName;
  HomeScreen({required this.trainerName});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final String apiEndpoint = 'https://pokeapi.co/api/v2/pokemon?limit=200';
  List<PokemonCardInfo> _pokemons = [];
  List<PokemonCardInfo> _filtered = [];
  bool _loading = true;
  String _error = '';
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPokemons();
    _search.addListener(() => _applySearch());
  }

  void _applySearch() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List.from(_pokemons));
    } else {
      setState(() => _filtered = _pokemons.where((p) => p.name.contains(q) || p.id.toString() == q).toList());
    }
  }

  Future<void> _loadPokemons() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http.get(Uri.parse(apiEndpoint));
      if (res.statusCode != 200) throw Exception('Failed to fetch list');
      final map = jsonDecode(res.body);
      final List results = map['results'] ?? [];
      // results have 'name' and 'url' -> extract ID from url and build sprite URL
      final list = results.map<PokemonCardInfo>((r) {
        final name = (r['name'] as String).replaceAll('-', ' ');
        final url = r['url'] as String;
        final id = _extractIdFromUrl(url);
        final sprite = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
        return PokemonCardInfo(id: id, name: name, spriteUrl: sprite, detailsUrl: url);
      }).toList();
      setState(() {
        _pokemons = list;
        _filtered = List.from(list);
      });
    } catch (e) {
      _error = 'Unable to fetch Pokémon list.';
    } finally {
      setState(() => _loading = false);
    }
  }

  int _extractIdFromUrl(String url) {
    // url typically ends with /pokemon/{id}/
    final parts = url.split('/');
    for (var i = parts.length -1; i >= 0; i--) {
      final p = parts[i];
      if (p.isNotEmpty) {
        final asInt = int.tryParse(p);
        if (asInt != null) return asInt;
      }
    }
    return 0;
  }

  Future<void> _refresh() async {
    await _loadPokemons();
  }

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.of(context).size.width > 900 ? 6 : MediaQuery.of(context).size.width > 600 ? 4 : 2;
    return Scaffold(
      appBar: AppBar(
        title: Text('Poképedia'),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text('Hi, ${widget.trainerName}', style: TextStyle(fontSize: 14))),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14,12,14,8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or id (e.g., pikachu or 25)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Reload'),
                  onPressed: _loading ? null : _refresh,
                )
              ],
            ),
          ),

          Expanded(
            child: _loading
              ? Center(child: SpinKitFadingCircle(size: 48, color: Theme.of(context).primaryColor))
              : _error.isNotEmpty
                ? Center(child: Text(_error))
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: _filtered.isEmpty
                      ? ListView(
                          physics: AlwaysScrollableScrollPhysics(),
                          children: [SizedBox(height: 60), Center(child: Text('No Pokémon found'))],
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final p = _filtered[i];
                            return PokemonCard(pokemon: p, onTap: () => _openDetails(p));
                          },
                        ),
                  ),
          )
        ],
      ),
    );
  }

  void _openDetails(PokemonCardInfo p) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PokemonDetailsScreen(info: p)));
  }
}

/* ---------------------------
   Pokemon Card widget
   --------------------------- */
class PokemonCard extends StatelessWidget {
  final PokemonCardInfo pokemon;
  final VoidCallback onTap;
  PokemonCard({required this.pokemon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final idText = '#${pokemon.id.toString().padLeft(3,'0')}';
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CachedNetworkImage(
                  imageUrl: pokemon.spriteUrl,
                  placeholder: (_,__) => SpinKitPulse(size: 28, color: Colors.redAccent),
                  errorWidget: (_,__,__) => Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Column(
                children: [
                  Text(pokemon.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4),
                  Text(idText, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

/* ---------------------------
   Details Screen (fetch abilities, types, stats)
   --------------------------- */
class PokemonDetailsScreen extends StatefulWidget {
  final PokemonCardInfo info;
  PokemonDetailsScreen({required this.info});
  @override
  State<PokemonDetailsScreen> createState() => _PokemonDetailsScreenState();
}
class _PokemonDetailsScreenState extends State<PokemonDetailsScreen> {
  bool _loading = true;
  String _error = '';
  PokemonDetails? _details;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http.get(Uri.parse(widget.info.detailsUrl));
      if (res.statusCode != 200) throw Exception('Failed');
      final map = jsonDecode(res.body);
      final abilities = (map['abilities'] as List).map((a) => a['ability']['name'] as String).toList();
      final types = (map['types'] as List).map((t) => t['type']['name'] as String).toList();
      final weight = map['weight'] as int;
      final height = map['height'] as int;
      final stats = (map['stats'] as List).map((s) => {'name': s['stat']['name'], 'base': s['base_stat']}).toList();
      setState(() {
        _details = PokemonDetails(abilities: abilities, types: types, weight: weight, height: height, stats: stats);
      });
    } catch (e) {
      setState(() { _error = 'Unable to fetch details.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.info;
    return Scaffold(
      appBar: AppBar(title: Text(p.name.toUpperCase())),
      body: _loading
        ? Center(child: SpinKitFadingCube(size: 36, color: Colors.redAccent))
        : _error.isNotEmpty
          ? Center(child: Text(_error))
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CachedNetworkImage(imageUrl: p.spriteUrl, width: 110, height: 110),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name.toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: _details!.types.map((t) => Chip(label: Text(t), backgroundColor: Colors.grey[200])).toList(),
                            ),
                            SizedBox(height: 8),
                            Text('Height: ${_details!.height}  •  Weight: ${_details!.weight}', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: Text('Abilities', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(height: 8),
                  Row(children: _details!.abilities.map((a) => Padding(padding: EdgeInsets.only(right:8), child: Chip(label: Text(a)))).toList()),
                  SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: Text('Base Stats', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(height: 8),
                  ..._details!.stats.map((s) => ListTile(
                    dense: true,
                    leading: Text('${s['base']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    title: Text(s['name']),
                    contentPadding: EdgeInsets.zero,
                  )),
                  Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.catching_pokemon),
                      label: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Catch (fake)')),
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Congrats! ${p.name} caught 🏆'))),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}

/* ---------------------------
   Simple data classes
   --------------------------- */
class PokemonCardInfo {
  final int id;
  final String name;
  final String spriteUrl;
  final String detailsUrl;
  PokemonCardInfo({required this.id, required this.name, required this.spriteUrl, required this.detailsUrl});
}

class PokemonDetails {
  final List<String> abilities;
  final List<String> types;
  final int weight;
  final int height;
  final List<Map<String, dynamic>> stats;
  PokemonDetails({required this.abilities, required this.types, required this.weight, required this.height, required this.stats});
}
