// Andhra Pradesh constituency directory as per the Delimitation of
// Parliamentary and Assembly Constituencies Order, 2008 (post-2014 numbering).
// District names are the 13 districts used by the delimitation order, not the
// 26 districts created in 2022.
//
// Before production use, cross-check every row against the official lists:
//   https://ceoandhra.nic.in  (Chief Electoral Officer, Andhra Pradesh)
//   https://eci.gov.in/delimitation-website/
// Corrections should be made here and re-applied with `npm run db:seed`.

export const DIRECTORY_SOURCE_URL = "https://eci.gov.in/delimitation-website/";

export type Res = "GEN" | "SC" | "ST";

export interface PcRow {
  no: number;
  en: string;
  te: string;
  res: Res;
}

export interface AcRow {
  no: number;
  en: string;
  te: string;
  res: Res;
  district: string;
  pc: number;
}

export const PARLIAMENTARY: PcRow[] = [
  { no: 1, en: "Araku", te: "అరకు", res: "ST" },
  { no: 2, en: "Srikakulam", te: "శ్రీకాకుళం", res: "GEN" },
  { no: 3, en: "Vizianagaram", te: "విజయనగరం", res: "GEN" },
  { no: 4, en: "Visakhapatnam", te: "విశాఖపట్నం", res: "GEN" },
  { no: 5, en: "Anakapalli", te: "అనకాపల్లి", res: "GEN" },
  { no: 6, en: "Kakinada", te: "కాకినాడ", res: "GEN" },
  { no: 7, en: "Amalapuram", te: "అమలాపురం", res: "SC" },
  { no: 8, en: "Rajahmundry", te: "రాజమండ్రి", res: "GEN" },
  { no: 9, en: "Narsapuram", te: "నరసాపురం", res: "GEN" },
  { no: 10, en: "Eluru", te: "ఏలూరు", res: "GEN" },
  { no: 11, en: "Machilipatnam", te: "మచిలీపట్నం", res: "GEN" },
  { no: 12, en: "Vijayawada", te: "విజయవాడ", res: "GEN" },
  { no: 13, en: "Guntur", te: "గుంటూరు", res: "GEN" },
  { no: 14, en: "Narasaraopet", te: "నరసరావుపేట", res: "GEN" },
  { no: 15, en: "Bapatla", te: "బాపట్ల", res: "SC" },
  { no: 16, en: "Ongole", te: "ఒంగోలు", res: "GEN" },
  { no: 17, en: "Nandyal", te: "నంద్యాల", res: "GEN" },
  { no: 18, en: "Kurnool", te: "కర్నూలు", res: "GEN" },
  { no: 19, en: "Anantapur", te: "అనంతపురం", res: "GEN" },
  { no: 20, en: "Hindupur", te: "హిందూపురం", res: "GEN" },
  { no: 21, en: "Kadapa", te: "కడప", res: "GEN" },
  { no: 22, en: "Nellore", te: "నెల్లూరు", res: "GEN" },
  { no: 23, en: "Tirupati", te: "తిరుపతి", res: "SC" },
  { no: 24, en: "Rajampet", te: "రాజంపేట", res: "GEN" },
  { no: 25, en: "Chittoor", te: "చిత్తూరు", res: "SC" },
];

const SKL = "Srikakulam";
const VZM = "Vizianagaram";
const VSP = "Visakhapatnam";
const EG = "East Godavari";
const WG = "West Godavari";
const KRI = "Krishna";
const GNT = "Guntur";
const PKM = "Prakasam";
const NLR = "Nellore";
const KDP = "Kadapa";
const KNL = "Kurnool";
const ATP = "Anantapur";
const CTR = "Chittoor";

export const ASSEMBLY: AcRow[] = [
  { no: 1, en: "Ichchapuram", te: "ఇచ్ఛాపురం", res: "GEN", district: SKL, pc: 2 },
  { no: 2, en: "Palasa", te: "పలాస", res: "GEN", district: SKL, pc: 2 },
  { no: 3, en: "Tekkali", te: "టెక్కలి", res: "GEN", district: SKL, pc: 2 },
  { no: 4, en: "Pathapatnam", te: "పాతపట్నం", res: "GEN", district: SKL, pc: 2 },
  { no: 5, en: "Srikakulam", te: "శ్రీకాకుళం", res: "GEN", district: SKL, pc: 2 },
  { no: 6, en: "Amadalavalasa", te: "ఆమదాలవలస", res: "GEN", district: SKL, pc: 2 },
  { no: 7, en: "Etcherla", te: "ఎచ్చెర్ల", res: "GEN", district: SKL, pc: 3 },
  { no: 8, en: "Narasannapeta", te: "నరసన్నపేట", res: "GEN", district: SKL, pc: 2 },
  { no: 9, en: "Rajam", te: "రాజాం", res: "SC", district: SKL, pc: 3 },
  { no: 10, en: "Palakonda", te: "పాలకొండ", res: "ST", district: SKL, pc: 1 },
  { no: 11, en: "Kurupam", te: "కురుపాం", res: "ST", district: VZM, pc: 1 },
  { no: 12, en: "Parvathipuram", te: "పార్వతీపురం", res: "SC", district: VZM, pc: 1 },
  { no: 13, en: "Salur", te: "సాలూరు", res: "ST", district: VZM, pc: 1 },
  { no: 14, en: "Bobbili", te: "బొబ్బిలి", res: "GEN", district: VZM, pc: 3 },
  { no: 15, en: "Cheepurupalli", te: "చీపురుపల్లి", res: "GEN", district: VZM, pc: 3 },
  { no: 16, en: "Gajapathinagaram", te: "గజపతినగరం", res: "GEN", district: VZM, pc: 3 },
  { no: 17, en: "Nellimarla", te: "నెల్లిమర్ల", res: "GEN", district: VZM, pc: 3 },
  { no: 18, en: "Vizianagaram", te: "విజయనగరం", res: "GEN", district: VZM, pc: 3 },
  { no: 19, en: "Srungavarapukota", te: "శృంగవరపుకోట", res: "GEN", district: VZM, pc: 4 },
  { no: 20, en: "Bhimili", te: "భీమిలి", res: "GEN", district: VSP, pc: 4 },
  { no: 21, en: "Visakhapatnam East", te: "విశాఖపట్నం తూర్పు", res: "GEN", district: VSP, pc: 4 },
  { no: 22, en: "Visakhapatnam South", te: "విశాఖపట్నం దక్షిణ", res: "GEN", district: VSP, pc: 4 },
  { no: 23, en: "Visakhapatnam North", te: "విశాఖపట్నం ఉత్తర", res: "GEN", district: VSP, pc: 4 },
  { no: 24, en: "Visakhapatnam West", te: "విశాఖపట్నం పశ్చిమ", res: "GEN", district: VSP, pc: 4 },
  { no: 25, en: "Gajuwaka", te: "గాజువాక", res: "GEN", district: VSP, pc: 4 },
  { no: 26, en: "Chodavaram", te: "చోడవరం", res: "GEN", district: VSP, pc: 5 },
  { no: 27, en: "Madugula", te: "మాడుగుల", res: "GEN", district: VSP, pc: 5 },
  { no: 28, en: "Araku Valley", te: "అరకు లోయ", res: "ST", district: VSP, pc: 1 },
  { no: 29, en: "Paderu", te: "పాడేరు", res: "ST", district: VSP, pc: 1 },
  { no: 30, en: "Anakapalli", te: "అనకాపల్లి", res: "GEN", district: VSP, pc: 5 },
  { no: 31, en: "Pendurthi", te: "పెందుర్తి", res: "GEN", district: VSP, pc: 5 },
  { no: 32, en: "Elamanchili", te: "ఎలమంచిలి", res: "GEN", district: VSP, pc: 5 },
  { no: 33, en: "Payakaraopet", te: "పాయకరావుపేట", res: "SC", district: VSP, pc: 5 },
  { no: 34, en: "Narsipatnam", te: "నర్సీపట్నం", res: "GEN", district: VSP, pc: 5 },
  { no: 35, en: "Tuni", te: "తుని", res: "GEN", district: EG, pc: 6 },
  { no: 36, en: "Prathipadu (Kakinada)", te: "ప్రత్తిపాడు (కాకినాడ)", res: "GEN", district: EG, pc: 6 },
  { no: 37, en: "Pithapuram", te: "పిఠాపురం", res: "GEN", district: EG, pc: 6 },
  { no: 38, en: "Kakinada Rural", te: "కాకినాడ గ్రామీణ", res: "GEN", district: EG, pc: 6 },
  { no: 39, en: "Peddapuram", te: "పెద్దాపురం", res: "GEN", district: EG, pc: 6 },
  { no: 40, en: "Anaparthy", te: "అనపర్తి", res: "GEN", district: EG, pc: 8 },
  { no: 41, en: "Kakinada City", te: "కాకినాడ నగరం", res: "GEN", district: EG, pc: 6 },
  { no: 42, en: "Ramachandrapuram", te: "రామచంద్రపురం", res: "GEN", district: EG, pc: 7 },
  { no: 43, en: "Mummidivaram", te: "ముమ్మిడివరం", res: "GEN", district: EG, pc: 7 },
  { no: 44, en: "Amalapuram", te: "అమలాపురం", res: "SC", district: EG, pc: 7 },
  { no: 45, en: "Razole", te: "రాజోలు", res: "SC", district: EG, pc: 7 },
  { no: 46, en: "Gannavaram (Konaseema)", te: "గన్నవరం (కోనసీమ)", res: "SC", district: EG, pc: 7 },
  { no: 47, en: "Kothapeta", te: "కొత్తపేట", res: "GEN", district: EG, pc: 7 },
  { no: 48, en: "Mandapeta", te: "మండపేట", res: "GEN", district: EG, pc: 7 },
  { no: 49, en: "Rajanagaram", te: "రాజానగరం", res: "GEN", district: EG, pc: 8 },
  { no: 50, en: "Rajahmundry City", te: "రాజమండ్రి నగరం", res: "GEN", district: EG, pc: 8 },
  { no: 51, en: "Rajahmundry Rural", te: "రాజమండ్రి గ్రామీణ", res: "GEN", district: EG, pc: 8 },
  { no: 52, en: "Jaggampeta", te: "జగ్గంపేట", res: "GEN", district: EG, pc: 6 },
  { no: 53, en: "Rampachodavaram", te: "రంపచోడవరం", res: "ST", district: EG, pc: 1 },
  { no: 54, en: "Kovvur", te: "కొవ్వూరు", res: "SC", district: WG, pc: 8 },
  { no: 55, en: "Nidadavole", te: "నిడదవోలు", res: "GEN", district: WG, pc: 8 },
  { no: 56, en: "Achanta", te: "ఆచంట", res: "GEN", district: WG, pc: 9 },
  { no: 57, en: "Palakollu", te: "పాలకొల్లు", res: "GEN", district: WG, pc: 9 },
  { no: 58, en: "Narsapuram", te: "నరసాపురం", res: "GEN", district: WG, pc: 9 },
  { no: 59, en: "Bhimavaram", te: "భీమవరం", res: "GEN", district: WG, pc: 9 },
  { no: 60, en: "Undi", te: "ఉండి", res: "GEN", district: WG, pc: 9 },
  { no: 61, en: "Tanuku", te: "తణుకు", res: "GEN", district: WG, pc: 9 },
  { no: 62, en: "Tadepalligudem", te: "తాడేపల్లిగూడెం", res: "GEN", district: WG, pc: 9 },
  { no: 63, en: "Unguturu", te: "ఉంగుటూరు", res: "GEN", district: WG, pc: 10 },
  { no: 64, en: "Denduluru", te: "దెందులూరు", res: "GEN", district: WG, pc: 10 },
  { no: 65, en: "Eluru", te: "ఏలూరు", res: "GEN", district: WG, pc: 10 },
  { no: 66, en: "Gopalapuram", te: "గోపాలపురం", res: "SC", district: WG, pc: 8 },
  { no: 67, en: "Polavaram", te: "పోలవరం", res: "ST", district: WG, pc: 10 },
  { no: 68, en: "Chintalapudi", te: "చింతలపూడి", res: "SC", district: WG, pc: 10 },
  { no: 69, en: "Tiruvuru", te: "తిరువూరు", res: "SC", district: KRI, pc: 12 },
  { no: 70, en: "Nuzvid", te: "నూజివీడు", res: "GEN", district: KRI, pc: 10 },
  { no: 71, en: "Gannavaram (Krishna)", te: "గన్నవరం (కృష్ణా)", res: "GEN", district: KRI, pc: 11 },
  { no: 72, en: "Gudivada", te: "గుడివాడ", res: "GEN", district: KRI, pc: 11 },
  { no: 73, en: "Kaikalur", te: "కైకలూరు", res: "GEN", district: KRI, pc: 10 },
  { no: 74, en: "Pedana", te: "పెడన", res: "GEN", district: KRI, pc: 11 },
  { no: 75, en: "Machilipatnam", te: "మచిలీపట్నం", res: "GEN", district: KRI, pc: 11 },
  { no: 76, en: "Avanigadda", te: "అవనిగడ్డ", res: "GEN", district: KRI, pc: 11 },
  { no: 77, en: "Pamarru", te: "పామర్రు", res: "SC", district: KRI, pc: 11 },
  { no: 78, en: "Penamaluru", te: "పెనమలూరు", res: "GEN", district: KRI, pc: 11 },
  { no: 79, en: "Vijayawada West", te: "విజయవాడ పశ్చిమ", res: "GEN", district: KRI, pc: 12 },
  { no: 80, en: "Vijayawada Central", te: "విజయవాడ సెంట్రల్", res: "GEN", district: KRI, pc: 12 },
  { no: 81, en: "Vijayawada East", te: "విజయవాడ తూర్పు", res: "GEN", district: KRI, pc: 12 },
  { no: 82, en: "Mylavaram", te: "మైలవరం", res: "GEN", district: KRI, pc: 12 },
  { no: 83, en: "Nandigama", te: "నందిగామ", res: "SC", district: KRI, pc: 12 },
  { no: 84, en: "Jaggayyapeta", te: "జగ్గయ్యపేట", res: "GEN", district: KRI, pc: 12 },
  { no: 85, en: "Pedakurapadu", te: "పెదకూరపాడు", res: "GEN", district: GNT, pc: 14 },
  { no: 86, en: "Tadikonda", te: "తాడికొండ", res: "SC", district: GNT, pc: 13 },
  { no: 87, en: "Mangalagiri", te: "మంగళగిరి", res: "GEN", district: GNT, pc: 13 },
  { no: 88, en: "Ponnur", te: "పొన్నూరు", res: "GEN", district: GNT, pc: 13 },
  { no: 89, en: "Vemuru", te: "వేమూరు", res: "SC", district: GNT, pc: 15 },
  { no: 90, en: "Repalle", te: "రేపల్లె", res: "GEN", district: GNT, pc: 15 },
  { no: 91, en: "Tenali", te: "తెనాలి", res: "GEN", district: GNT, pc: 13 },
  { no: 92, en: "Bapatla", te: "బాపట్ల", res: "GEN", district: GNT, pc: 15 },
  { no: 93, en: "Prathipadu (Guntur)", te: "ప్రత్తిపాడు (గుంటూరు)", res: "SC", district: GNT, pc: 13 },
  { no: 94, en: "Guntur West", te: "గుంటూరు పశ్చిమ", res: "GEN", district: GNT, pc: 13 },
  { no: 95, en: "Guntur East", te: "గుంటూరు తూర్పు", res: "GEN", district: GNT, pc: 13 },
  { no: 96, en: "Chilakaluripet", te: "చిలకలూరిపేట", res: "GEN", district: GNT, pc: 14 },
  { no: 97, en: "Narasaraopet", te: "నరసరావుపేట", res: "GEN", district: GNT, pc: 14 },
  { no: 98, en: "Sattenapalle", te: "సత్తెనపల్లి", res: "GEN", district: GNT, pc: 14 },
  { no: 99, en: "Vinukonda", te: "వినుకొండ", res: "GEN", district: GNT, pc: 14 },
  { no: 100, en: "Gurajala", te: "గురజాల", res: "GEN", district: GNT, pc: 14 },
  { no: 101, en: "Macherla", te: "మాచర్ల", res: "GEN", district: GNT, pc: 14 },
  { no: 102, en: "Yerragondapalem", te: "ఎర్రగొండపాలెం", res: "SC", district: PKM, pc: 16 },
  { no: 103, en: "Darsi", te: "దర్శి", res: "GEN", district: PKM, pc: 16 },
  { no: 104, en: "Parchur", te: "పర్చూరు", res: "GEN", district: PKM, pc: 15 },
  { no: 105, en: "Addanki", te: "అద్దంకి", res: "GEN", district: PKM, pc: 15 },
  { no: 106, en: "Chirala", te: "చీరాల", res: "GEN", district: PKM, pc: 15 },
  { no: 107, en: "Santhanuthalapadu", te: "సంతనూతలపాడు", res: "SC", district: PKM, pc: 15 },
  { no: 108, en: "Ongole", te: "ఒంగోలు", res: "GEN", district: PKM, pc: 16 },
  { no: 109, en: "Kandukur", te: "కందుకూరు", res: "GEN", district: PKM, pc: 22 },
  { no: 110, en: "Kondapi", te: "కొండపి", res: "SC", district: PKM, pc: 16 },
  { no: 111, en: "Markapuram", te: "మార్కాపురం", res: "GEN", district: PKM, pc: 16 },
  { no: 112, en: "Giddalur", te: "గిద్దలూరు", res: "GEN", district: PKM, pc: 16 },
  { no: 113, en: "Kanigiri", te: "కనిగిరి", res: "GEN", district: PKM, pc: 16 },
  { no: 114, en: "Kavali", te: "కావలి", res: "GEN", district: NLR, pc: 22 },
  { no: 115, en: "Atmakur", te: "ఆత్మకూరు", res: "GEN", district: NLR, pc: 22 },
  { no: 116, en: "Kovur", te: "కోవూరు", res: "GEN", district: NLR, pc: 22 },
  { no: 117, en: "Nellore City", te: "నెల్లూరు నగరం", res: "GEN", district: NLR, pc: 22 },
  { no: 118, en: "Nellore Rural", te: "నెల్లూరు గ్రామీణ", res: "GEN", district: NLR, pc: 22 },
  { no: 119, en: "Sarvepalli", te: "సర్వేపల్లి", res: "GEN", district: NLR, pc: 23 },
  { no: 120, en: "Gudur", te: "గూడూరు", res: "SC", district: NLR, pc: 23 },
  { no: 121, en: "Sullurpeta", te: "సూళ్లూరుపేట", res: "SC", district: NLR, pc: 23 },
  { no: 122, en: "Venkatagiri", te: "వెంకటగిరి", res: "GEN", district: NLR, pc: 23 },
  { no: 123, en: "Udayagiri", te: "ఉదయగిరి", res: "GEN", district: NLR, pc: 22 },
  { no: 124, en: "Badvel", te: "బద్వేలు", res: "SC", district: KDP, pc: 21 },
  { no: 125, en: "Rajampet", te: "రాజంపేట", res: "GEN", district: KDP, pc: 24 },
  { no: 126, en: "Kadapa", te: "కడప", res: "GEN", district: KDP, pc: 21 },
  { no: 127, en: "Kodur", te: "కోడూరు", res: "SC", district: KDP, pc: 24 },
  { no: 128, en: "Rayachoti", te: "రాయచోటి", res: "GEN", district: KDP, pc: 24 },
  { no: 129, en: "Pulivendla", te: "పులివెందుల", res: "GEN", district: KDP, pc: 21 },
  { no: 130, en: "Kamalapuram", te: "కమలాపురం", res: "GEN", district: KDP, pc: 21 },
  { no: 131, en: "Jammalamadugu", te: "జమ్మలమడుగు", res: "GEN", district: KDP, pc: 21 },
  { no: 132, en: "Proddatur", te: "ప్రొద్దుటూరు", res: "GEN", district: KDP, pc: 21 },
  { no: 133, en: "Mydukur", te: "మైదుకూరు", res: "GEN", district: KDP, pc: 21 },
  { no: 134, en: "Allagadda", te: "ఆళ్లగడ్డ", res: "GEN", district: KNL, pc: 17 },
  { no: 135, en: "Srisailam", te: "శ్రీశైలం", res: "GEN", district: KNL, pc: 17 },
  { no: 136, en: "Nandikotkur", te: "నందికొట్కూరు", res: "SC", district: KNL, pc: 17 },
  { no: 137, en: "Kurnool", te: "కర్నూలు", res: "GEN", district: KNL, pc: 18 },
  { no: 138, en: "Panyam", te: "పాణ్యం", res: "GEN", district: KNL, pc: 17 },
  { no: 139, en: "Nandyal", te: "నంద్యాల", res: "GEN", district: KNL, pc: 17 },
  { no: 140, en: "Banaganapalle", te: "బనగానపల్లె", res: "GEN", district: KNL, pc: 17 },
  { no: 141, en: "Dhone", te: "డోన్", res: "GEN", district: KNL, pc: 17 },
  { no: 142, en: "Pattikonda", te: "పత్తికొండ", res: "GEN", district: KNL, pc: 18 },
  { no: 143, en: "Kodumur", te: "కోడుమూరు", res: "SC", district: KNL, pc: 18 },
  { no: 144, en: "Yemmiganur", te: "ఎమ్మిగనూరు", res: "GEN", district: KNL, pc: 18 },
  { no: 145, en: "Mantralayam", te: "మంత్రాలయం", res: "GEN", district: KNL, pc: 18 },
  { no: 146, en: "Adoni", te: "ఆదోని", res: "GEN", district: KNL, pc: 18 },
  { no: 147, en: "Alur", te: "ఆలూరు", res: "GEN", district: KNL, pc: 18 },
  { no: 148, en: "Rayadurg", te: "రాయదుర్గం", res: "GEN", district: ATP, pc: 19 },
  { no: 149, en: "Uravakonda", te: "ఉరవకొండ", res: "GEN", district: ATP, pc: 19 },
  { no: 150, en: "Guntakal", te: "గుంతకల్లు", res: "GEN", district: ATP, pc: 19 },
  { no: 151, en: "Tadipatri", te: "తాడిపత్రి", res: "GEN", district: ATP, pc: 19 },
  { no: 152, en: "Singanamala", te: "శింగనమల", res: "SC", district: ATP, pc: 19 },
  { no: 153, en: "Anantapur Urban", te: "అనంతపురం అర్బన్", res: "GEN", district: ATP, pc: 19 },
  { no: 154, en: "Kalyandurg", te: "కళ్యాణదుర్గం", res: "GEN", district: ATP, pc: 19 },
  { no: 155, en: "Raptadu", te: "రాప్తాడు", res: "GEN", district: ATP, pc: 20 },
  { no: 156, en: "Madakasira", te: "మడకశిర", res: "SC", district: ATP, pc: 20 },
  { no: 157, en: "Hindupur", te: "హిందూపురం", res: "GEN", district: ATP, pc: 20 },
  { no: 158, en: "Penukonda", te: "పెనుకొండ", res: "GEN", district: ATP, pc: 20 },
  { no: 159, en: "Puttaparthi", te: "పుట్టపర్తి", res: "GEN", district: ATP, pc: 20 },
  { no: 160, en: "Dharmavaram", te: "ధర్మవరం", res: "GEN", district: ATP, pc: 20 },
  { no: 161, en: "Kadiri", te: "కదిరి", res: "GEN", district: ATP, pc: 20 },
  { no: 162, en: "Thamballapalle", te: "తంబళ్లపల్లె", res: "GEN", district: CTR, pc: 24 },
  { no: 163, en: "Pileru", te: "పీలేరు", res: "GEN", district: CTR, pc: 24 },
  { no: 164, en: "Madanapalle", te: "మదనపల్లె", res: "GEN", district: CTR, pc: 24 },
  { no: 165, en: "Punganur", te: "పుంగనూరు", res: "GEN", district: CTR, pc: 24 },
  { no: 166, en: "Chandragiri", te: "చంద్రగిరి", res: "GEN", district: CTR, pc: 25 },
  { no: 167, en: "Tirupati", te: "తిరుపతి", res: "GEN", district: CTR, pc: 23 },
  { no: 168, en: "Srikalahasti", te: "శ్రీకాళహస్తి", res: "GEN", district: CTR, pc: 23 },
  { no: 169, en: "Satyavedu", te: "సత్యవేడు", res: "SC", district: CTR, pc: 23 },
  { no: 170, en: "Nagari", te: "నగరి", res: "GEN", district: CTR, pc: 25 },
  { no: 171, en: "Gangadhara Nellore", te: "గంగాధర నెల్లూరు", res: "SC", district: CTR, pc: 25 },
  { no: 172, en: "Chittoor", te: "చిత్తూరు", res: "GEN", district: CTR, pc: 25 },
  { no: 173, en: "Puthalapattu", te: "పూతలపట్టు", res: "SC", district: CTR, pc: 25 },
  { no: 174, en: "Palamaner", te: "పలమనేరు", res: "GEN", district: CTR, pc: 25 },
  { no: 175, en: "Kuppam", te: "కుప్పం", res: "GEN", district: CTR, pc: 25 },
];

export const acId = (no: number) => `AC-${String(no).padStart(3, "0")}`;
export const pcId = (no: number) => `PC-${String(no).padStart(2, "0")}`;
