import 'package:flutter/material.dart';

enum ElectionType { mla, mp }

/// One of the 13 (pre-2022) districts of Andhra Pradesh. Assembly
/// constituencies are numbered contiguously within each district.
class District {
  const District(this.id, this.en, this.te, this.firstAc, this.lastAc);

  final String id;
  final String en;
  final String te;
  final int firstAc;
  final int lastAc;

  int get mlaCount => lastAc - firstAc + 1;
  String name(bool telugu) => telugu ? te : en;
}

class Constituency {
  const Constituency({
    required this.type,
    required this.no,
    required this.en,
    required this.te,
    required this.districtIds,
    this.segments = const [],
    this.pcNo,
  });

  final ElectionType type;
  final int no;
  final String en;
  final String te;
  final List<String> districtIds;

  /// For MP constituencies: the assembly segment numbers.
  final List<int> segments;

  /// For MLA constituencies: the parliament constituency number.
  final int? pcNo;

  String get id => '${type.name}-$no';
  bool get isMla => type == ElectionType.mla;
  String name(bool telugu) => telugu ? te : en;
  List<District> get districts => districtIds.map(ApData.district).toList();

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return en.toLowerCase().contains(q) ||
        te.contains(q) ||
        '$no' == q ||
        districts.any((d) => d.en.toLowerCase().contains(q) || d.te.contains(q));
  }
}

enum PartySymbol { bicycle, fan, glass, lotus, independent }

class Party {
  const Party(this.id, this.short, this.en, this.te, this.color, this.symbol);

  final String id;
  final String short;
  final String en;
  final String te;
  final Color color;
  final PartySymbol symbol;

  String name(bool telugu) => telugu ? te : en;
}

const parties = <Party>[
  Party('tdp', 'TDP', 'Telugu Desam Party', 'తెలుగుదేశం పార్టీ', Color(0xFFF5C400), PartySymbol.bicycle),
  Party('ysrcp', 'YSRCP', 'YSR Congress Party', 'వైఎస్ఆర్ కాంగ్రెస్ పార్టీ', Color(0xFF2F6FDB), PartySymbol.fan),
  Party('jsp', 'Janasena', 'Janasena Party', 'జనసేన పార్టీ', Color(0xFFE53935), PartySymbol.glass),
  Party('bjp', 'BJP', 'Bharatiya Janata Party', 'భారతీయ జనతా పార్టీ', Color(0xFFF57C00), PartySymbol.lotus),
  Party('ind', 'Independent', 'Independent', 'స్వతంత్ర', Color(0xFF8E9AAF), PartySymbol.independent),
];

class ApData {
  static const districts = <District>[
    District('srikakulam', 'Srikakulam', 'శ్రీకాకుళం', 1, 10),
    District('vizianagaram', 'Vizianagaram', 'విజయనగరం', 11, 19),
    District('visakhapatnam', 'Visakhapatnam', 'విశాఖపట్నం', 20, 34),
    District('east-godavari', 'East Godavari', 'తూర్పు గోదావరి', 35, 53),
    District('west-godavari', 'West Godavari', 'పశ్చిమ గోదావరి', 54, 68),
    District('krishna', 'Krishna', 'కృష్ణా', 69, 84),
    District('guntur', 'Guntur', 'గుంటూరు', 85, 101),
    District('prakasam', 'Prakasam', 'ప్రకాశం', 102, 113),
    District('nellore', 'Nellore', 'నెల్లూరు', 114, 123),
    District('kadapa', 'Kadapa', 'కడప', 124, 133),
    District('kurnool', 'Kurnool', 'కర్నూలు', 134, 147),
    District('anantapur', 'Anantapur', 'అనంతపురం', 148, 161),
    District('chittoor', 'Chittoor', 'చిత్తూరు', 162, 175),
  ];

  static District district(String id) => districts.firstWhere((d) => d.id == id);

  static District districtForAc(int no) =>
      districts.firstWhere((d) => no >= d.firstAc && no <= d.lastAc);

  static final List<Constituency> mla = [
    for (var i = 0; i < _acRaw.length; i++) _mla(i + 1, _acRaw[i]),
  ];

  static final List<Constituency> mp = [
    for (var i = 0; i < _pcRaw.length; i++)
      Constituency(
        type: ElectionType.mp,
        no: i + 1,
        en: _pcRaw[i].$1,
        te: _pcRaw[i].$2,
        segments: _pcRaw[i].$3,
        districtIds: [
          for (final d in districts)
            if (_pcRaw[i].$3.any((ac) => ac >= d.firstAc && ac <= d.lastAc)) d.id,
        ],
      ),
  ];

  static List<Constituency> of(ElectionType type) => type == ElectionType.mla ? mla : mp;

  static Constituency byId(String id) {
    final parts = id.split('-');
    final list = parts.first == 'mp' ? mp : mla;
    return list[int.parse(parts.last) - 1];
  }

  static Constituency? pcFor(Constituency ac) => ac.pcNo == null ? null : mp[ac.pcNo! - 1];

  static Constituency _mla(int no, String raw) {
    final names = raw.split('|');
    final pcIndex = _pcRaw.indexWhere((pc) => pc.$3.contains(no));
    return Constituency(
      type: ElectionType.mla,
      no: no,
      en: names[0],
      te: names[1],
      districtIds: [districtForAc(no).id],
      pcNo: pcIndex + 1,
    );
  }
}

/// Assembly constituencies of Andhra Pradesh in official order (2008 delimitation).
const _acRaw = <String>[
  'Ichchapuram|ఇచ్ఛాపురం', 'Palasa|పలాస', 'Tekkali|టెక్కలి', 'Pathapatnam|పాతపట్నం',
  'Srikakulam|శ్రీకాకుళం', 'Amadalavalasa|ఆమదాలవలస', 'Etcherla|ఎచ్చెర్ల', 'Narasannapeta|నరసన్నపేట',
  'Rajam|రాజాం', 'Palakonda|పాలకొండ', 'Kurupam|కురుపాం', 'Parvathipuram|పార్వతీపురం',
  'Salur|సాలూరు', 'Bobbili|బొబ్బిలి', 'Cheepurupalli|చీపురుపల్లి', 'Gajapathinagaram|గజపతినగరం',
  'Nellimarla|నెల్లిమర్ల', 'Vizianagaram|విజయనగరం', 'Srungavarapukota|శృంగవరపుకోట', 'Bhimili|భీమిలి',
  'Visakhapatnam East|విశాఖపట్నం తూర్పు', 'Visakhapatnam South|విశాఖపట్నం దక్షిణ',
  'Visakhapatnam North|విశాఖపట్నం ఉత్తర', 'Visakhapatnam West|విశాఖపట్నం పశ్చిమ',
  'Gajuwaka|గాజువాక', 'Chodavaram|చోడవరం', 'Madugula|మాడుగుల', 'Araku Valley|అరకు లోయ',
  'Paderu|పాడేరు', 'Anakapalli|అనకాపల్లి', 'Pendurthi|పెందుర్తి', 'Elamanchili|ఎలమంచిలి',
  'Payakaraopet|పాయకరావుపేట', 'Narsipatnam|నర్సీపట్నం', 'Tuni|తుని', 'Prathipadu|ప్రత్తిపాడు',
  'Pithapuram|పిఠాపురం', 'Kakinada Rural|కాకినాడ రూరల్', 'Peddapuram|పెద్దాపురం', 'Anaparthy|అనపర్తి',
  'Kakinada City|కాకినాడ సిటీ', 'Ramachandrapuram|రామచంద్రపురం', 'Mummidivaram|ముమ్మిడివరం',
  'Amalapuram|అమలాపురం', 'Razole|రాజోలు', 'P. Gannavaram|పి. గన్నవరం', 'Kothapeta|కొత్తపేట',
  'Mandapeta|మండపేట', 'Rajanagaram|రాజానగరం', 'Rajahmundry City|రాజమండ్రి సిటీ',
  'Rajahmundry Rural|రాజమండ్రి రూరల్', 'Jaggampeta|జగ్గంపేట', 'Rampachodavaram|రంపచోడవరం',
  'Kovvur|కొవ్వూరు', 'Nidadavole|నిడదవోలు', 'Achanta|ఆచంట', 'Palakollu|పాలకొల్లు',
  'Narasapuram|నరసాపురం', 'Bhimavaram|భీమవరం', 'Undi|ఉండి', 'Tanuku|తణుకు',
  'Tadepalligudem|తాడేపల్లిగూడెం', 'Unguturu|ఉంగుటూరు', 'Denduluru|దెందులూరు', 'Eluru|ఏలూరు',
  'Gopalapuram|గోపాలపురం', 'Polavaram|పోలవరం', 'Chintalapudi|చింతలపూడి', 'Tiruvuru|తిరువూరు',
  'Nuzvid|నూజివీడు', 'Gannavaram|గన్నవరం', 'Gudivada|గుడివాడ', 'Kaikalur|కైకలూరు',
  'Pedana|పెడన', 'Machilipatnam|మచిలీపట్నం', 'Avanigadda|అవనిగడ్డ', 'Pamarru|పామర్రు',
  'Penamaluru|పెనమలూరు', 'Vijayawada West|విజయవాడ పశ్చిమ', 'Vijayawada Central|విజయవాడ సెంట్రల్',
  'Vijayawada East|విజయవాడ తూర్పు', 'Mylavaram|మైలవరం', 'Nandigama|నందిగామ',
  'Jaggayyapeta|జగ్గయ్యపేట', 'Pedakurapadu|పెదకూరపాడు', 'Tadikonda|తాడికొండ',
  'Mangalagiri|మంగళగిరి', 'Ponnur|పొన్నూరు', 'Vemuru|వేమూరు', 'Repalle|రేపల్లె', 'Tenali|తెనాలి',
  'Bapatla|బాపట్ల', 'Prathipadu (Guntur)|ప్రత్తిపాడు (గుంటూరు)', 'Guntur West|గుంటూరు పశ్చిమ',
  'Guntur East|గుంటూరు తూర్పు', 'Chilakaluripet|చిలకలూరిపేట', 'Narasaraopet|నరసరావుపేట',
  'Sattenapalle|సత్తెనపల్లి', 'Vinukonda|వినుకొండ', 'Gurajala|గురజాల', 'Macherla|మాచర్ల',
  'Yerragondapalem|యర్రగొండపాలెం', 'Darsi|దర్శి', 'Parchur|పర్చూరు', 'Addanki|అద్దంకి',
  'Chirala|చీరాల', 'Santhanuthalapadu|సంతనూతలపాడు', 'Ongole|ఒంగోలు', 'Kandukur|కందుకూరు',
  'Kondapi|కొండపి', 'Markapuram|మార్కాపురం', 'Giddalur|గిద్దలూరు', 'Kanigiri|కనిగిరి',
  'Kavali|కావలి', 'Atmakur|ఆత్మకూరు', 'Kovur|కోవూరు', 'Nellore City|నెల్లూరు సిటీ',
  'Nellore Rural|నెల్లూరు రూరల్', 'Sarvepalli|సర్వేపల్లి', 'Gudur|గూడూరు', 'Sullurpeta|సూళ్లూరుపేట',
  'Venkatagiri|వెంకటగిరి', 'Udayagiri|ఉదయగిరి', 'Badvel|బద్వేలు', 'Rajampet|రాజంపేట', 'Kadapa|కడప',
  'Kodur|కోడూరు', 'Rayachoti|రాయచోటి', 'Pulivendla|పులివెందుల', 'Kamalapuram|కమలాపురం',
  'Jammalamadugu|జమ్మలమడుగు', 'Proddatur|ప్రొద్దుటూరు', 'Mydukur|మైదుకూరు', 'Allagadda|ఆళ్లగడ్డ',
  'Srisailam|శ్రీశైలం', 'Nandikotkur|నందికొట్కూరు', 'Kurnool|కర్నూలు', 'Panyam|పాణ్యం',
  'Nandyal|నంద్యాల', 'Banaganapalle|బనగానపల్లె', 'Dhone|డోన్', 'Pattikonda|పత్తికొండ',
  'Kodumur|కోడుమూరు', 'Yemmiganur|ఎమ్మిగనూరు', 'Mantralayam|మంత్రాలయం', 'Adoni|ఆదోని',
  'Alur|ఆలూరు', 'Rayadurg|రాయదుర్గం', 'Uravakonda|ఉరవకొండ', 'Guntakal|గుంతకల్లు',
  'Tadipatri|తాడిపత్రి', 'Singanamala|శింగనమల', 'Anantapur Urban|అనంతపురం అర్బన్',
  'Kalyandurg|కళ్యాణదుర్గం', 'Raptadu|రాప్తాడు', 'Madakasira|మడకశిర', 'Hindupur|హిందూపురం',
  'Penukonda|పెనుకొండ', 'Puttaparthi|పుట్టపర్తి', 'Dharmavaram|ధర్మవరం', 'Kadiri|కదిరి',
  'Thamballapalle|తంబళ్లపల్లె', 'Pileru|పీలేరు', 'Madanapalle|మదనపల్లె', 'Punganur|పుంగనూరు',
  'Chandragiri|చంద్రగిరి', 'Tirupati|తిరుపతి', 'Srikalahasti|శ్రీకాళహస్తి', 'Satyavedu|సత్యవేడు',
  'Nagari|నగరి', 'Gangadhara Nellore|గంగాధర నెల్లూరు', 'Chittoor|చిత్తూరు',
  'Puthalapattu|పూతలపట్టు', 'Palamaner|పలమనేరు', 'Kuppam|కుప్పం',
];

/// Parliament constituencies with their assembly segment numbers.
const _pcRaw = <(String, String, List<int>)>[
  ('Araku', 'అరకు', [10, 11, 12, 13, 28, 29, 53]),
  ('Srikakulam', 'శ్రీకాకుళం', [1, 2, 3, 4, 5, 6, 8]),
  ('Vizianagaram', 'విజయనగరం', [7, 9, 14, 15, 16, 17, 18]),
  ('Visakhapatnam', 'విశాఖపట్నం', [19, 20, 21, 22, 23, 24, 25]),
  ('Anakapalli', 'అనకాపల్లి', [26, 27, 30, 31, 32, 33, 34]),
  ('Kakinada', 'కాకినాడ', [35, 36, 37, 38, 39, 41, 52]),
  ('Amalapuram', 'అమలాపురం', [42, 43, 44, 45, 46, 47, 48]),
  ('Rajahmundry', 'రాజమండ్రి', [40, 49, 50, 51, 54, 55, 66]),
  ('Narsapuram', 'నరసాపురం', [56, 57, 58, 59, 60, 61, 62]),
  ('Eluru', 'ఏలూరు', [63, 64, 65, 67, 68, 70, 73]),
  ('Machilipatnam', 'మచిలీపట్నం', [71, 72, 74, 75, 76, 77, 78]),
  ('Vijayawada', 'విజయవాడ', [69, 79, 80, 81, 82, 83, 84]),
  ('Guntur', 'గుంటూరు', [86, 87, 88, 91, 93, 94, 95]),
  ('Narasaraopet', 'నరసరావుపేట', [85, 96, 97, 98, 99, 100, 101]),
  ('Bapatla', 'బాపట్ల', [89, 90, 92, 104, 105, 106, 107]),
  ('Ongole', 'ఒంగోలు', [102, 103, 108, 110, 111, 112, 113]),
  ('Nandyal', 'నంద్యాల', [134, 135, 136, 138, 139, 140, 141]),
  ('Kurnool', 'కర్నూలు', [137, 142, 143, 144, 145, 146, 147]),
  ('Anantapur', 'అనంతపురం', [148, 149, 150, 151, 152, 153, 154]),
  ('Hindupur', 'హిందూపురం', [155, 156, 157, 158, 159, 160, 161]),
  ('Kadapa', 'కడప', [124, 126, 129, 130, 131, 132, 133]),
  ('Nellore', 'నెల్లూరు', [109, 114, 115, 116, 117, 118, 123]),
  ('Tirupati', 'తిరుపతి', [119, 120, 121, 122, 167, 168, 169]),
  ('Rajampet', 'రాజంపేట', [125, 127, 128, 162, 163, 164, 165]),
  ('Chittoor', 'చిత్తూరు', [166, 170, 171, 172, 173, 174, 175]),
];
