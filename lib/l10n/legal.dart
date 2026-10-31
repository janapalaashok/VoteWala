import '../config/config_service.dart';

/// VoteWala's public policies. Each has a web address: `#/legal/<id>`.
///
/// The English text is the governing version; each page starts with a short
/// Telugu summary. Admins can edit them (admin panel → Legal pages).
class LegalDoc {
  const LegalDoc(this.id, this.titleEn, this.titleTe, this.summaryTe, this.sections);

  final String id;
  final String titleEn, titleTe;
  final String summaryTe;

  /// (heading, body) pairs. `{contact}` is replaced with the contact email.
  final List<(String, String)> sections;

  String title(bool te) => te ? titleTe : titleEn;

  LegalDoc copyWith({String? titleEn, String? titleTe, String? summaryTe, List<(String, String)>? sections}) =>
      LegalDoc(id, titleEn ?? this.titleEn, titleTe ?? this.titleTe, summaryTe ?? this.summaryTe, sections ?? this.sections);

  Map<String, dynamic> toJson() => {
        'titleEn': titleEn,
        'titleTe': titleTe,
        'summaryTe': summaryTe,
        'sections': [for (final (h, b) in sections) {'h': h, 'b': b}],
      };

  factory LegalDoc.fromJson(String id, Map<String, dynamic> j, LegalDoc fallback) => LegalDoc(
        id,
        j['titleEn'] as String? ?? fallback.titleEn,
        j['titleTe'] as String? ?? fallback.titleTe,
        j['summaryTe'] as String? ?? fallback.summaryTe,
        j['sections'] is List
            ? [
                for (final s in j['sections'] as List)
                  if (s is Map) ('${s['h'] ?? ''}', '${s['b'] ?? ''}'),
              ]
            : fallback.sections,
      );
}

const legalUpdated = '31 October 2026';

/// Built-in texts; the admin panel can replace any of them.
const defaultLegalDocs = [
  LegalDoc(
    'privacy',
    'Privacy Policy',
    'గోప్యతా విధానం',
    'మేము న్యాయమైన పోల్స్‌కు అవసరమైనవి మాత్రమే సేకరిస్తాం: మీ ఖాతా (ఈమెయిల్ లేదా Google), మీ ఓట్లు, స్థానిక అభిప్రాయాలు, '
        'మీరు ఇష్టపడి పంపే ఫోటోలు. మీ వ్యక్తిగత ఓటు ఎవరికీ చూపించం, అమ్మం; మొత్తాలు మాత్రమే ప్రచురిస్తాం. '
        'మీ డేటా చూడటానికి, సరిచేయడానికి, తొలగించడానికి మమ్మల్ని సంప్రదించవచ్చు.',
    [
      ('Who we are',
          'VoteWala ("we", "us") is a public opinion platform for Andhra Pradesh. This policy explains what personal '
              'data we process when you use the VoteWala website and apps, why, and your rights under the Digital Personal '
              'Data Protection Act, 2023 (India).'),
      ('What we collect',
          '• Account: your email address, and your name and profile picture if you sign in with Google. Passwords are '
              'handled by Google Firebase Authentication; we never see them.\n'
              '• Participation: the polls you vote in and your choices, your GOOD / BAD feedback on local facilities, your '
              '"If you were the MLA" priority, your badges and your vote count.\n'
              '• Optional content: photos and short captions you choose to submit, and text you write under "Other".\n'
              '• On your device: your language and saved candidates, stored in your browser or app.\n'
              'We do not collect your phone contacts, precise location or government ID. Photo location data (EXIF/GPS) is '
              'removed on your device before upload.'),
      ('Why we use it',
          '• To let you sign in and to keep polls fair: one vote per account per poll.\n'
              '• To calculate and publish results as totals.\n'
              '• To review photos and prepare grievance reports about civic issues (totals and approved photos only).\n'
              '• To prevent abuse, such as automated or duplicate voting.\n'
              'The legal basis is your consent, which you give by creating an account and voting. You can withdraw it at '
              'any time by deleting your account (see "Your rights").'),
      ('Your political opinion stays private',
          'Political opinion is sensitive personal data. Your individual choices are never shown publicly, never sold '
              'and never shared with political parties, candidates or the government. Published results, dashboards and '
              'grievance reports contain only totals. The share card shows your choice only if you switch "Show my choice" '
              'on.'),
      ('Who processes the data',
          'Data is stored and processed on Google Cloud / Firebase (Google LLC and its affiliates) acting as our '
              'processor. VoteWala administrators can see your account email and name, how many votes you have cast, '
              'totals and submitted photos, so that they can handle abuse; they cannot see how an individual voted. '
              'Accounts that break the Community Guidelines can be blocked from voting. We disclose data to authorities only when Indian law requires it.'),
      ('How long we keep it',
          'Account data is kept while your account exists. Ballots are kept to preserve the integrity of published '
              'results; if you delete your account, your ballots are disconnected from your identity. Rejected photos are '
              'deleted within 90 days; approved photos may be kept as part of a grievance record.'),
      ('Your rights',
          'You may ask to access, correct or erase your personal data, withdraw consent, nominate a person to exercise '
              'your rights, and raise a grievance. Write to {contact}. We respond within 30 days. If you are not satisfied, '
              'you may approach the Data Protection Board of India.'),
      ('Children',
          'VoteWala is for people aged 18 and above. We do not knowingly process data of children. If you believe a child '
              'has an account, contact us and we will delete it.'),
      ('Security',
          'Data is encrypted in transit, access is restricted by security rules and administrator roles, and every vote '
              'is checked on the server. No system is perfectly secure; we will notify affected users and the Data '
              'Protection Board of a personal data breach as the law requires.'),
      ('Changes',
          'We will post changes on this page with a new date. Significant changes will also be announced in the app.'),
    ],
  ),
  LegalDoc(
    'terms',
    'Terms of Use',
    'వినియోగ నిబంధనలు',
    'VoteWala అనధికారిక అభిప్రాయ వేదిక. ఒక్కరికి ఒక్క ఖాతా, నిజాయితీగా ఓటు వేయాలి; నకిలీ ఖాతాలు, ఆటోమేటెడ్ ఓటింగ్ నిషేధం. '
        'ఫలితాలు పాల్గొన్న వారి అభిప్రాయాలు మాత్రమే, అధికారిక ఎన్నికల ఫలితాలు కావు.',
    [
      ('Acceptance',
          'By creating an account or using VoteWala you agree to these Terms and to our Privacy Policy. If you do not '
              'agree, please do not use the service.'),
      ('Eligibility',
          'You must be at least 18 years old. VoteWala is meant for residents of, and people interested in, Andhra '
              'Pradesh.'),
      ('Your account',
          'Use one account per person, keep your sign-in details safe, and give a working email address. You are '
              'responsible for activity under your account.'),
      ('Fair participation',
          'Do not: create multiple or fake accounts; use bots, scripts or paid vote campaigns; try to alter counts or '
              'access data that is not yours; submit photos or text that are false, abusive, obscene, defamatory, '
              'communal, show other people\'s faces or personal details without consent, or break any law. We may remove '
              'such content, discard affected votes and suspend accounts.'),
      ('Nature of results',
          'Results reflect the opinions of users who chose to take part. They are not official election results, exit '
              'polls or scientifically representative surveys, and are not endorsed by the Election Commission of India, '
              'the Government of Andhra Pradesh or any political party.'),
      ('Content you submit',
          'You keep ownership of photos and text you submit. You allow VoteWala to store them, review them and include '
              'approved photos and totals in grievance reports shared with elected representatives or authorities.'),
      ('Grievance reports',
          'VoteWala may bring collective concerns to representatives. We do not promise any response or action by them, '
              'and status updates on the site show only what we have recorded with evidence.'),
      ('Availability',
          'We aim to keep VoteWala available but may change, pause or stop features, including showing results during '
              'periods when the law restricts the publication of opinion polls.'),
      ('Limitation of liability',
          'VoteWala is provided "as is". To the extent the law allows, we are not liable for indirect losses or for '
              'decisions made based on poll results.'),
      ('Governing law',
          'These Terms are governed by the laws of India. Courts in Andhra Pradesh have jurisdiction, subject to any '
              'mandatory consumer protection law.'),
      ('Contact', 'Questions about these Terms: {contact}.'),
    ],
  ),
  LegalDoc(
    'disclaimer',
    'Disclaimer',
    'నిరాకరణ',
    'VoteWala ఎన్నికల సంఘం, ప్రభుత్వం లేదా ఏ రాజకీయ పార్టీతోనూ సంబంధం లేని స్వతంత్ర వేదిక. ఫలితాలు ఎన్నికల అంచనా కాదు. '
        'అభ్యర్థుల పేర్లు, ఫోటోలు ప్రజా సమాచారం నుండి తీసుకున్నవి.',
    [
      ('Independent platform',
          'VoteWala is an independent platform. It is not affiliated with, endorsed by or acting for the Election '
              'Commission of India, the Chief Electoral Officer of Andhra Pradesh, any government body or any political '
              'party or candidate.'),
      ('Not an election or prediction',
          'Voting on VoteWala is not voting in an election. Results show the opinions of participating users and are '
              'not a prediction of any election outcome. Participation is self-selected and results are not weighted to '
              'represent the population.'),
      ('Election periods',
          'In line with Section 126A and Section 126(1)(b) of the Representation of the People Act, 1951, VoteWala may '
              'hide results or pause polls during periods when the publication of opinion poll or exit poll results is '
              'restricted.'),
      ('Candidate information',
          'Names, parties, photos and 2024 results of candidates come from public sources such as the Election '
              'Commission of India and Wikimedia Commons. Logos and photos belong to their owners. If something is '
              'incorrect, write to {contact}.'),
      ('Photos and reports',
          'Photos are submitted by users and reviewed by VoteWala, but are not independently verified. Grievance '
              'reports present totals and do not claim that any representative has seen or acted on an issue unless that '
              'has been confirmed.'),
    ],
  ),
  LegalDoc(
    'cookies',
    'Data Storage & Cookies',
    'డేటా నిల్వ & కుకీలు',
    'VoteWala ప్రకటనల కుకీలు లేదా ట్రాకర్లు వాడదు. సైన్ ఇన్, భాష, సేవ్ చేసిన అభ్యర్థుల కోసం మాత్రమే మీ బ్రౌజర్/యాప్‌లో చిన్న డేటా ఉంచుతాం.',
    [
      ('What we store on your device',
          '• Sign-in session (Firebase Authentication), so you stay signed in.\n'
              '• Your language, saved candidates and notification preferences.\n'
              '• A cached copy of the site settings so pages load quickly.'),
      ('What we do not use',
          'No advertising cookies, no third-party trackers and no cross-site profiling. Google sign-in may set cookies '
              'on Google\'s own pages under Google\'s policies.'),
      ('Your choices',
          'You can clear site data in your browser or app settings at any time. You will then be signed out and your '
              'local preferences will reset; your votes stay recorded in your account.'),
    ],
  ),
  LegalDoc(
    'guidelines',
    'Community Guidelines',
    'కమ్యూనిటీ మార్గదర్శకాలు',
    'నిజాయితీగా, గౌరవంగా పాల్గొనండి. ఫోటోలు స్థానిక సమస్యకు సంబంధించినవే పంపండి; ఇతరుల ముఖాలు, ఫోన్ నంబర్లు, ద్వేషపూరిత కంటెంట్ వద్దు.',
    [
      ('Vote honestly', 'One person, one account. Vote for what you actually believe.'),
      ('Photos that help',
          'Send clear photos of the local issue itself: roads, drains, lights, garbage, water. Avoid faces, vehicle '
              'number plates, house numbers and other personal details.'),
      ('Never allowed',
          'Hate speech, communal or caste-based content, threats, sexual content, misinformation, content about '
              'children, and anything that breaks Indian law.'),
      ('What happens next',
          'Admins review photos before they are used. Content that breaks these guidelines is rejected; repeated or '
              'serious abuse leads to account suspension. Report problems to {contact}.'),
    ],
  ),
  LegalDoc(
    'grievance',
    'Grievance Redressal & Contact',
    'ఫిర్యాదుల పరిష్కారం & సంప్రదింపు',
    'మీ డేటా, కంటెంట్ లేదా ఖాతా గురించి ఫిర్యాదు ఉంటే {contact} కు రాయండి. 24 గంటల్లో అందినట్టు తెలిపి, 15 రోజుల్లో పరిష్కరిస్తాం.',
    [
      ('How to raise a grievance',
          'Email {contact} with: your account email, what the issue is (privacy, content, account, results), and links '
              'or screenshots if any.'),
      ('Our timelines',
          'We acknowledge within 24 hours and aim to resolve within 15 days. Requests to remove unlawful content are '
              'handled within 72 hours of a valid complaint. Data protection requests are answered within 30 days.'),
      ('Escalation',
          'If you are not satisfied with our response to a data protection request, you may approach the Data '
              'Protection Board of India.'),
    ],
  ),
];

/// The published policies: admin edits over the built-in texts.
List<LegalDoc> get legalDocs => [for (final d in defaultLegalDocs) appConfig.legal[d.id] ?? d];

LegalDoc? legalById(String id) => legalDocs.where((d) => d.id == id).firstOrNull;
