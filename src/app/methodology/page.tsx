import { getI18n } from "@/i18n/server";
import { minSample } from "@/lib/results";
import { PageHeader } from "@/components/ui";

export const metadata = { title: "Methodology & limitations" };

type Section = { id: string; title: string; body: string[] };

function content(n: number): Record<"en" | "te", Section[]> {
  return {
    en: [
      {
        id: "what",
        title: "What VoteWala measures",
        body: [
          "VoteWala is an independent platform that records the opinions of people who choose to take part in daily polls about MLA (Assembly) and MP (Lok Sabha) candidates in Andhra Pradesh.",
          "VoteWala is not affiliated with any political party, candidate, government body or the Election Commission of India. Results are not official election results, exit polls or forecasts.",
        ],
      },
      {
        id: "who",
        title: "Who can vote",
        body: [
          "Participants sign in with a Google account and verify an Indian mobile number with a one-time password (OTP). Each mobile number can be linked to only one account.",
          "Each verified account can vote once per poll. This rule is enforced by a unique constraint in the database, so it holds even if two requests arrive at the same moment. Votes cannot be changed after they are cast.",
        ],
      },
      {
        id: "schedule",
        title: "Daily schedule",
        body: [
          "Polls are scheduled per calendar day in India Standard Time (IST). Opening and closing times are decided by the server and the database clock, not by your device.",
          "After a poll closes, its end-of-day result is frozen into a final report that does not change afterwards.",
        ],
      },
      {
        id: "results",
        title: "How results are published",
        body: [
          "Each poll has a publication policy chosen before it opens: Live (running counts while open), Delayed (counts shown with a fixed lag, for example 60 minutes) or After close (no counts until the poll closes).",
          `Percentages are hidden until a poll has at least ${n} votes, because very small samples are easily dominated by chance.`,
          "Every option is drawn in the same neutral colour, so colour never suggests a winner or a party.",
        ],
      },
      {
        id: "limitations",
        title: "Sample limitations",
        body: [
          "Participants select themselves. They are not a random or representative sample of Andhra Pradesh voters, and VoteWala does not weight results by age, gender, location, caste, religion or past vote.",
          "Online participation over-represents people with smartphones, internet access and an interest in politics, and under-represents others. Organised campaigns can encourage supporters to take part.",
          "Because the sample is not random, statistical margins of error do not apply. Treat results as a snapshot of participant opinion, not as a prediction of how a constituency will vote.",
        ],
      },
      {
        id: "candidates",
        title: "Candidate information",
        body: [
          "Candidate records are imported from official sources: Election Commission of India affidavits and results, and the Chief Electoral Officer, Andhra Pradesh. Every candidate profile links to its source.",
          "An administrator must verify each record against its source before it can appear in a poll. Party names are shown only as they appear in official records; VoteWala does not show party symbols.",
        ],
      },
      {
        id: "privacy",
        title: "Privacy",
        body: [
          "We store your name and email from Google, your verified mobile number, and a record of which option you chose in each poll. The vote record is needed to enforce one vote per poll.",
          "Individual votes are never published or shared. Only totals per option are shown. Exports for administrators contain totals, not individual votes. Mobile numbers are masked in audit logs and OTP codes are stored only as one-way hashes.",
        ],
      },
    ],
    te: [
      {
        id: "what",
        title: "VoteWala ఏమి కొలుస్తుంది",
        body: [
          "ఆంధ్రప్రదేశ్‌లోని ఎమ్మెల్యే (అసెంబ్లీ), ఎంపీ (లోక్‌సభ) అభ్యర్థులపై రోజువారీ పోల్స్‌లో స్వచ్ఛందంగా పాల్గొనేవారి అభిప్రాయాలను VoteWala నమోదు చేస్తుంది.",
          "VoteWalaకు ఏ రాజకీయ పార్టీ, అభ్యర్థి, ప్రభుత్వ సంస్థ లేదా భారత ఎన్నికల సంఘంతో అనుబంధం లేదు. ఫలితాలు అధికారిక ఎన్నికల ఫలితాలు, ఎగ్జిట్ పోల్స్ లేదా అంచనాలు కావు.",
        ],
      },
      {
        id: "who",
        title: "ఎవరు ఓటు వేయవచ్చు",
        body: [
          "పాల్గొనేవారు Google ఖాతాతో సైన్ ఇన్ చేసి, OTP ద్వారా భారతీయ మొబైల్ నంబర్‌ను ధృవీకరిస్తారు. ఒక్కో మొబైల్ నంబర్ ఒకే ఖాతాకు లింక్ అవుతుంది.",
          "ధృవీకరించిన ప్రతి ఖాతా ఒక్కో పోల్‌లో ఒకసారే ఓటు వేయగలదు. ఈ నియమాన్ని డేటాబేస్ స్థాయిలో అమలు చేస్తాము. ఓటు వేసిన తర్వాత మార్చలేరు.",
        ],
      },
      {
        id: "schedule",
        title: "రోజువారీ షెడ్యూల్",
        body: [
          "పోల్స్ భారత ప్రామాణిక సమయం (IST) ప్రకారం రోజువారీగా షెడ్యూల్ అవుతాయి. ప్రారంభ, ముగింపు సమయాలను సర్వర్ మరియు డేటాబేస్ గడియారం నిర్ణయిస్తాయి; మీ పరికరం కాదు.",
          "పోల్ ముగిసిన తర్వాత ఆ రోజు ఫలితం తుది నివేదికగా స్థిరపరచబడుతుంది; తర్వాత మారదు.",
        ],
      },
      {
        id: "results",
        title: "ఫలితాల ప్రచురణ",
        body: [
          "ప్రతి పోల్‌కు ముందుగానే ప్రచురణ విధానం నిర్ణయించబడుతుంది: ప్రత్యక్ష (పోల్ జరుగుతుండగా లెక్కలు), ఆలస్య (నిర్ణీత ఆలస్యంతో లెక్కలు) లేదా ముగిసిన తర్వాత (పోల్ ముగిసే వరకు లెక్కలు చూపబడవు).",
          `ఒక పోల్‌కు కనీసం ${n} ఓట్లు వచ్చే వరకు శాతాలు చూపము; చాలా చిన్న నమూనాలు యాదృచ్ఛికతకు లోనవుతాయి.`,
          "ప్రతి ఎంపికను ఒకే తటస్థ రంగులో చూపిస్తాము; రంగు ఎప్పుడూ విజేతను లేదా పార్టీని సూచించదు.",
        ],
      },
      {
        id: "limitations",
        title: "నమూనా పరిమితులు",
        body: [
          "పాల్గొనేవారు తమంతట తాము ఎంచుకుంటారు. వారు ఆంధ్రప్రదేశ్ ఓటర్ల యాదృచ్ఛిక లేదా ప్రాతినిధ్య నమూనా కాదు. వయస్సు, లింగం, ప్రాంతం, కులం, మతం లేదా గత ఓటు ఆధారంగా VoteWala ఫలితాలను సర్దుబాటు చేయదు.",
          "ఆన్‌లైన్ భాగస్వామ్యంలో స్మార్ట్‌ఫోన్, ఇంటర్నెట్ ఉన్నవారు, రాజకీయాలపై ఆసక్తి ఉన్నవారు ఎక్కువగా ఉంటారు. వ్యవస్థీకృత ప్రచారాలు మద్దతుదారులను పాల్గొనమని ప్రోత్సహించవచ్చు.",
          "నమూనా యాదృచ్ఛికం కానందున గణాంక దోష పరిమితి (margin of error) వర్తించదు. ఫలితాలను పాల్గొన్నవారి అభిప్రాయ చిత్రంగా మాత్రమే చూడండి; నియోజకవర్గ ఫలితంపై అంచనాగా కాదు.",
        ],
      },
      {
        id: "candidates",
        title: "అభ్యర్థుల సమాచారం",
        body: [
          "అభ్యర్థుల వివరాలు అధికారిక మూలాల నుండి — భారత ఎన్నికల సంఘం అఫిడవిట్లు, ఫలితాలు మరియు ఆంధ్రప్రదేశ్ ప్రధాన ఎన్నికల అధికారి — తీసుకోబడతాయి. ప్రతి ప్రొఫైల్ దాని మూలానికి లింక్ చేయబడింది.",
          "పోల్‌లో కనిపించే ముందు ప్రతి రికార్డును అడ్మినిస్ట్రేటర్ మూలంతో సరిపోల్చి ధృవీకరించాలి. పార్టీ పేర్లు అధికారిక రికార్డుల్లో ఉన్నట్లే చూపబడతాయి; పార్టీ గుర్తులను చూపము.",
        ],
      },
      {
        id: "privacy",
        title: "గోప్యత",
        body: [
          "Google నుండి మీ పేరు, ఇమెయిల్, మీ ధృవీకరించిన మొబైల్ నంబర్, మరియు ప్రతి పోల్‌లో మీరు ఎంచుకున్న ఎంపికను నిల్వ చేస్తాము. ఒక్కో పోల్‌కు ఒకే ఓటు నియమం అమలుకు ఇది అవసరం.",
          "వ్యక్తిగత ఓట్లు ఎప్పుడూ ప్రచురించబడవు లేదా పంచుకోబడవు. ప్రతి ఎంపికకు మొత్తాలు మాత్రమే చూపబడతాయి. ఆడిట్ లాగ్‌లలో మొబైల్ నంబర్లు మాస్క్ చేయబడతాయి; OTP కోడ్‌లు వన్-వే హాష్‌లుగా మాత్రమే నిల్వ అవుతాయి.",
        ],
      },
    ],
  };
}

export default async function MethodologyPage() {
  const { locale, t } = await getI18n();
  const sections = content(minSample())[locale];
  return (
    <>
      <PageHeader title={t.methodology.title} sub={t.home.neutralityBody} />
      <div className="container-page grid gap-10 py-10 lg:grid-cols-[220px_1fr]">
        <nav aria-label={t.methodology.title} className="hidden lg:block">
          <ul className="sticky top-28 space-y-1 text-sm">
            {sections.map((s) => (
              <li key={s.id}>
                <a href={`#${s.id}`} className="block rounded-lg px-3 py-2 text-muted hover:bg-surface hover:text-ink">
                  {s.title}
                </a>
              </li>
            ))}
          </ul>
        </nav>
        <article className="max-w-3xl space-y-6">
          {sections.map((s) => (
            <section key={s.id} id={s.id} className="card scroll-mt-24 p-6 sm:p-8">
              <h2 className="text-xl font-bold">{s.title}</h2>
              <div className="mt-3 space-y-3 text-[15px] leading-relaxed text-ink/85">
                {s.body.map((p, i) => (
                  <p key={i}>{p}</p>
                ))}
              </div>
            </section>
          ))}
        </article>
      </div>
    </>
  );
}
