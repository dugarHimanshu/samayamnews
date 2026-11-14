/**
 * Demo content for client presentations: articles across districts (Telugu + English, some older than
 * the 48h district window), ads and magazines. All demo articles use source = DEMO_SOURCE so they can
 * be removed with `npm run seed:demo -- --reset`.
 *
 * Stories are generic local-news examples and do not describe real people or events.
 */
import postgres from 'postgres'
import sharp from 'sharp'
import 'dotenv/config'
import { MEDIA_BUCKET, supabaseAdmin } from '../src/services/storage.js'

const DEMO_SOURCE = 'Samayam Demo Desk'
const sql = postgres(process.env.DATABASE_URL!, { max: 1, prepare: false })
const storage = supabaseAdmin().storage

if (process.argv.includes('--reset')) {
  const r = await sql`DELETE FROM app.articles WHERE source = ${DEMO_SOURCE}`
  await sql`DELETE FROM app.ads WHERE created_by IS NULL AND tag LIKE 'DEMO%'`
  await sql`DELETE FROM app.magazines WHERE category LIKE 'Demo:%'`
  console.log(`Removed ${r.count} demo articles plus demo ads/magazines.`)
  await sql.end()
  process.exit(0)
}

const img = (id: string) => `https://images.unsplash.com/${id}?auto=format&fit=crop&w=1200&q=80`

interface DemoArticle {
  district: string
  mandal?: string
  category: string
  language: 'te' | 'en'
  hoursAgo: number
  breaking?: boolean
  author: string
  title: string
  summary: string
  body: string
  image?: string
}

const articles: DemoArticle[] = [
  {
    district: 'Hyderabad', category: 'local', language: 'te', hoursAgo: 1, breaking: true, author: 'సిటీ డెస్క్',
    title: 'నగరంలో కొత్తగా 40 బస్తీ దవాఖానాలు ప్రారంభం',
    summary: 'పేద ప్రజలకు ఉచిత వైద్య సేవలు అందించేందుకు నగరవ్యాప్తంగా 40 కొత్త బస్తీ దవాఖానాలు ఈ రోజు నుంచి అందుబాటులోకి వచ్చాయి.',
    body: 'నగరంలోని వివిధ ప్రాంతాల్లో 40 కొత్త బస్తీ దవాఖానాలు ఈ రోజు ప్రారంభమయ్యాయి. ప్రతి కేంద్రంలో ఒక వైద్యుడు, నర్సు, ల్యాబ్ టెక్నీషియన్ అందుబాటులో ఉంటారు.\n\nప్రాథమిక పరీక్షలు, మందులు పూర్తిగా ఉచితంగా అందిస్తామని అధికారులు తెలిపారు. ఉదయం 9 నుంచి సాయంత్రం 4 గంటల వరకు సేవలు ఉంటాయి.\n\nరాబోయే మూడు నెలల్లో మరో 25 కేంద్రాలను ప్రారంభించనున్నట్లు అధికారులు వెల్లడించారు.',
    image: img('photo-1519494026892-80bbd2d6fd0d'),
  },
  {
    district: 'Hyderabad', category: 'technology', language: 'en', hoursAgo: 5, author: 'Tech Desk',
    title: 'City startup hub adds 2,000 seats for early-stage founders',
    summary: 'A new wing of the public startup incubator opens with mentoring programmes and subsidised workspace for student founders.',
    body: 'The city’s public startup incubator opened a new wing today, adding around 2,000 desks for early-stage companies.\n\nOfficials said a third of the space is reserved for student founders and teams from smaller towns across the state, with free mentoring sessions every week.\n\nApplications for the first cohort open next Monday and will be reviewed on a rolling basis.',
    image: img('photo-1497366216548-37526070297c'),
  },
  {
    district: 'Warangal', category: 'agriculture', language: 'te', hoursAgo: 3, author: 'వరంగల్ ప్రతినిధి',
    title: 'ఎనుమాముల మార్కెట్‌లో పత్తికి మద్దతు ధర',
    summary: 'ఈ సీజన్‌లో పత్తి కొనుగోళ్లు ఊపందుకున్నాయి. క్వింటాలుకు మద్దతు ధర లభిస్తుండటంతో రైతులు సంతోషం వ్యక్తం చేశారు.',
    body: 'ఎనుమాముల వ్యవసాయ మార్కెట్‌లో పత్తి కొనుగోళ్లు ఊపందుకున్నాయి. ఈ రోజు సుమారు 12 వేల క్వింటాళ్ల పత్తి మార్కెట్‌కు వచ్చింది.\n\nతేమ శాతం నిబంధనల మేరకు ఉన్న పత్తికి పూర్తి మద్దతు ధర చెల్లిస్తున్నామని మార్కెట్ అధికారులు తెలిపారు.\n\nరైతులు పత్తిని బాగా ఆరబెట్టి తీసుకురావాలని అధికారులు సూచించారు.',
    image: img('photo-1595435934249-5df7ed86e1c0'),
  },
  {
    district: 'Karimnagar', category: 'sports', language: 'en', hoursAgo: 8, author: 'Sports Desk',
    title: 'District under-19 cricket trials draw 600 young players',
    summary: 'Selectors will pick 30 players for a month-long coaching camp ahead of the inter-district tournament.',
    body: 'More than 600 young cricketers turned up for district under-19 trials held over two days at the local stadium.\n\nSelectors said 30 players will join a month-long coaching camp, with the final squad announced before the inter-district tournament in January.\n\nOrganisers thanked parents and schools for the turnout and said more trials would be held in rural mandals next season.',
    image: img('photo-1531415074968-036ba1b575da'),
  },
  {
    district: 'Khammam', category: 'education', language: 'te', hoursAgo: 20, author: 'ఖమ్మం ప్రతినిధి',
    title: 'ప్రభుత్వ పాఠశాలల్లో డిజిటల్ తరగతి గదులు',
    summary: 'జిల్లాలోని 120 ప్రభుత్వ పాఠశాలల్లో స్మార్ట్ బోర్డులతో డిజిటల్ తరగతులు ప్రారంభమయ్యాయి.',
    body: 'జిల్లాలోని 120 ప్రభుత్వ పాఠశాలల్లో డిజిటల్ తరగతి గదులు ప్రారంభమయ్యాయి. ప్రతి పాఠశాలకు స్మార్ట్ బోర్డు, ప్రొజెక్టర్ అందించారు.\n\nఉపాధ్యాయులకు ఇప్పటికే శిక్షణ పూర్తయిందని విద్యాశాఖ అధికారులు తెలిపారు.\n\nవచ్చే విద్యా సంవత్సరం నాటికి మిగిలిన పాఠశాలలకూ ఈ సదుపాయం విస్తరిస్తామని చెప్పారు.',
    image: img('photo-1509062522246-3755977927d7'),
  },
  {
    district: 'Visakhapatnam', category: 'weather', language: 'en', hoursAgo: 2, breaking: true, author: 'Weather Desk',
    title: 'Coastal districts on alert as low-pressure area intensifies',
    summary: 'Fishermen have been advised not to venture into the sea for the next 48 hours as heavy rain is forecast along the coast.',
    body: 'A low-pressure area over the Bay of Bengal is expected to intensify over the next 24 hours, bringing heavy rain to coastal districts.\n\nFishermen have been advised not to go to sea for the next two days. District officials have kept relief centres ready in low-lying areas.\n\nResidents can call the district control room for help; the number is displayed at all mandal offices.',
    image: img('photo-1527482797697-8795b05a13fe'),
  },
  {
    district: 'Visakhapatnam', category: 'business', language: 'te', hoursAgo: 30, author: 'విశాఖ ప్రతినిధి',
    title: 'విశాఖ పోర్టులో రికార్డు స్థాయిలో సరుకు రవాణా',
    summary: 'ఈ త్రైమాసికంలో పోర్టు ద్వారా సరుకు రవాణా గత ఏడాదితో పోలిస్తే 12 శాతం పెరిగింది.',
    body: 'విశాఖపట్నం పోర్టు ఈ త్రైమాసికంలో రికార్డు స్థాయిలో సరుకు రవాణా చేసింది. గత ఏడాదితో పోలిస్తే 12 శాతం వృద్ధి నమోదైంది.\n\nకొత్త బెర్త్‌లు అందుబాటులోకి రావడం, కార్యకలాపాల వేగం పెరగడం దీనికి కారణమని అధికారులు తెలిపారు.\n\nరాబోయే నెలల్లో మరిన్ని నౌకలు వచ్చే అవకాశం ఉందని చెప్పారు.',
    image: img('photo-1494412574643-ff11b0a5c1c3'),
  },
  {
    district: 'Guntur', category: 'agriculture', language: 'en', hoursAgo: 12, author: 'Guntur Correspondent',
    title: 'Chilli prices steady as new crop reaches the yard',
    summary: 'Traders expect arrivals to double over the next two weeks as harvesting picks up across the district.',
    body: 'Chilli prices held steady at the market yard as the first lots of the new crop arrived this week.\n\nTraders said arrivals are expected to double over the next fortnight as harvesting picks up. Cold-storage operators reported enough capacity for the season.\n\nMarket officials urged farmers to bring properly graded produce to get better prices.',
    image: img('photo-1583119022894-919a68a3d0e3'),
  },
  {
    district: 'Tirupati', category: 'local', language: 'te', hoursAgo: 6, author: 'తిరుపతి ప్రతినిధి',
    title: 'తిరుపతిలో కొత్త ఎలక్ట్రిక్ బస్సు సర్వీసులు',
    summary: 'నగరంలో 50 ఎలక్ట్రిక్ బస్సులు ప్రారంభమయ్యాయి. రైల్వే స్టేషన్, బస్టాండ్ మధ్య ప్రతి 10 నిమిషాలకు ఒక బస్సు.',
    body: 'తిరుపతి నగరంలో 50 కొత్త ఎలక్ట్రిక్ బస్సు సర్వీసులు ఈ రోజు ప్రారంభమయ్యాయి.\n\nరైల్వే స్టేషన్, సెంట్రల్ బస్టాండ్, ప్రధాన కూడళ్ల మధ్య ప్రతి 10 నిమిషాలకు ఒక బస్సు నడుస్తుంది.\n\nకాలుష్యం తగ్గించడంతో పాటు ప్రయాణికులకు సౌకర్యవంతమైన ప్రయాణం అందించడమే లక్ష్యమని అధికారులు తెలిపారు.',
    image: img('photo-1570125909232-eb263c188f7e'),
  },
  {
    district: 'NTR', category: 'health', language: 'en', hoursAgo: 15, author: 'Health Desk',
    title: 'Free eye-screening camps to cover 200 villages this month',
    summary: 'Mobile medical teams will screen residents and distribute spectacles free of cost.',
    body: 'District health officials launched a month-long eye-screening drive that will reach about 200 villages.\n\nMobile teams will screen residents, distribute spectacles and refer cataract cases to the district hospital for free surgery.\n\nThe schedule for each mandal is being shared through village secretariats.',
    image: img('photo-1576091160550-2173dba999ef'),
  },
  {
    district: 'Nizamabad', category: 'crime', language: 'te', hoursAgo: 60, author: 'నిజామాబాద్ ప్రతినిధి',
    title: 'సైబర్ మోసాలపై అవగాహన సదస్సు',
    summary: 'ఆన్‌లైన్ మోసాలకు గురికాకుండా జాగ్రత్తలు పాటించాలని పోలీసులు ప్రజలకు సూచించారు.',
    body: 'జిల్లా పోలీసులు కళాశాల విద్యార్థుల కోసం సైబర్ మోసాలపై అవగాహన సదస్సు నిర్వహించారు.\n\nతెలియని లింకులపై క్లిక్ చేయవద్దని, ఓటీపీ ఎవరితోనూ పంచుకోవద్దని సూచించారు.\n\nమోసానికి గురైతే వెంటనే 1930 నంబర్‌కు ఫోన్ చేయాలని తెలిపారు.',
    image: img('photo-1550751827-4bd374c3f58b'),
  },
  {
    district: 'Kurnool', category: 'politics', language: 'en', hoursAgo: 72, author: 'Kurnool Correspondent',
    title: 'Municipal council approves ₹120 crore drinking-water plan',
    summary: 'The plan includes new reservoirs and pipelines to give every ward a daily water supply within two years.',
    body: 'The municipal council approved a ₹120 crore plan to improve drinking-water supply across the city.\n\nThe project includes two new service reservoirs and about 90 km of new pipelines. Officials said every ward should receive daily supply within two years.\n\nWork on the first phase is expected to begin after tenders are finalised next month.',
    image: img('photo-1548839140-29a749e1cf4d'),
  },
  {
    district: 'Ranga Reddy', category: 'business', language: 'en', hoursAgo: 90, author: 'Business Desk',
    title: 'New logistics park expected to create 5,000 jobs',
    summary: 'The facility near the outer ring road will house warehouses for e-commerce and cold-chain companies.',
    body: 'A new logistics park coming up near the outer ring road is expected to create around 5,000 jobs once fully operational.\n\nThe park will house warehouses for e-commerce, pharmaceutical and cold-chain companies, with a dedicated skilling centre for local youth.\n\nThe first phase is scheduled to open by the end of next year.',
    image: img('photo-1586528116311-ad8dd3c8310d'),
  },
  {
    district: 'Adilabad', category: 'local', language: 'te', hoursAgo: 100, author: 'ఆదిలాబాద్ ప్రతినిధి',
    title: 'కుంటాల జలపాతం వద్ద పర్యాటకుల సందడి',
    summary: 'వర్షాలు కురవడంతో జలపాతానికి నీటి ప్రవాహం పెరిగింది. వారాంతంలో పర్యాటకుల సంఖ్య భారీగా పెరిగింది.',
    body: 'ఇటీవలి వర్షాలతో కుంటాల జలపాతం వద్ద నీటి ప్రవాహం పెరిగింది. వారాంతంలో వేలాది మంది పర్యాటకులు తరలివచ్చారు.\n\nపర్యాటకుల భద్రత కోసం అదనపు సిబ్బందిని నియమించినట్లు అటవీ శాఖ అధికారులు తెలిపారు.\n\nజలపాతం దగ్గర నీటిలోకి దిగవద్దని సూచించారు.',
    image: img('photo-1432405972618-c60b0225b8f9'),
  },
]

const ads = [
  { sponsor: 'AURA MOBILITY', headline: 'Next-gen electric scooters built for Indian roads', tag: 'DEMO · SPONSORED', description: 'Fast charging and 150 km range.', cta_text: 'Explore', cta_url: 'https://example.com', image_url: img('photo-1593941707882-a5bba14938c7') },
  { sponsor: 'SRI LAKSHMI JEWELLERS', headline: 'Festive collection now in store', tag: 'DEMO · SPONSORED', description: 'Visit our showroom this weekend.', cta_text: 'Visit', cta_url: 'https://example.com', image_url: img('photo-1515562141207-7a88fb7ce338') },
  { sponsor: 'GREEN FIELDS AGRO', headline: 'Certified seeds and soil testing for every farmer', tag: 'DEMO · SPONSORED', description: 'Free soil test with every purchase.', cta_text: 'Learn more', cta_url: 'https://example.com', image_url: img('photo-1500382017468-9049fed747ef') },
]

const magazines = [
  { title: 'Samayam Weekend Special', subtitle: 'Stories from across Telangana and Andhra Pradesh', issue: 'November 2026', category: 'Demo: Special Edition', cover_url: img('photo-1504711434969-e33886168f5c'), pdf_url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', page_count: 24 },
  { title: 'Farmers’ Digest', subtitle: 'Prices, weather and schemes for the season', issue: 'Kharif 2026', category: 'Demo: Agriculture', cover_url: img('photo-1500937386664-56d1dfef3854'), pdf_url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', page_count: 16 },
]

/** Downloads a photo and runs it through the same WebP pipeline the worker uses. */
async function uploadImage(url: string): Promise<string | null> {
  try {
    const res = await fetch(url)
    if (!res.ok) throw new Error(String(res.status))
    const input = Buffer.from(await res.arrayBuffer())
    const meta = await sharp(input).metadata()
    const [row] = await sql`
      INSERT INTO app.media (kind, raw_key, content_type, size_bytes, status)
      VALUES ('image', 'seed', 'image/jpeg', ${input.length}, 'pending') RETURNING id`
    const id = row!.id as string
    const variants: Record<string, string> = {}
    for (const width of [320, 640, 1080]) {
      const out = await sharp(input).rotate().resize({ width, withoutEnlargement: true }).webp({ quality: 78 }).toBuffer()
      const key = `${id}/${width}.webp`
      const up = await storage.from(MEDIA_BUCKET).upload(key, out, { contentType: 'image/webp', upsert: true, cacheControl: '31536000' })
      if (up.error) throw up.error
      variants[String(width)] = key
    }
    await sql`UPDATE app.media SET status = 'ready', variants = ${sql.json(variants)}, width = ${meta.width ?? null}, height = ${meta.height ?? null} WHERE id = ${id}`
    return id
  } catch (err) {
    console.warn(`  image skipped (${url}): ${(err as Error).message}`)
    return null
  }
}

const districtRows = await sql`SELECT id, name_en, state_id FROM app.locations WHERE level = 'district'`
const districtByName = new Map(districtRows.map((r) => [String(r.name_en).toLowerCase(), r]))
const catRows = await sql`SELECT id, slug FROM app.categories`
const catBySlug = new Map(catRows.map((r) => [r.slug as string, r.id as number]))
if (!districtRows.length || !catRows.length) throw new Error('Run seed:locations and seed:reference first')

let created = 0
for (const a of articles) {
  const d = districtByName.get(a.district.toLowerCase())
  if (!d) {
    console.warn(`  unknown district ${a.district}, skipped`)
    continue
  }
  const exists = await sql`SELECT 1 FROM app.articles WHERE title = ${a.title} AND source = ${DEMO_SOURCE}`
  if (exists.length) continue
  const mediaId = a.image ? await uploadImage(a.image) : null
  await sql`
    INSERT INTO app.articles (title, summary, body, language, category_id, state_id, district_id, cover_media_id,
      author_name, source, is_breaking, published_at)
    VALUES (${a.title}, ${a.summary}, ${a.body}, ${a.language}, ${catBySlug.get(a.category)!}, ${d.state_id}, ${d.id},
      ${mediaId}, ${a.author}, ${DEMO_SOURCE}, ${a.breaking ?? false}, now() - make_interval(hours => ${a.hoursAgo}))`
  created++
}

for (const ad of ads) {
  const exists = await sql`SELECT 1 FROM app.ads WHERE headline = ${ad.headline}`
  if (!exists.length) await sql`INSERT INTO app.ads ${sql({ ...ad, weight: 1, is_active: true })}`
}
for (const m of magazines) {
  const exists = await sql`SELECT 1 FROM app.magazines WHERE title = ${m.title}`
  if (!exists.length) await sql`INSERT INTO app.magazines ${sql({ ...m, is_published: true })}`
}

await sql.end()
console.log(`Demo content: ${created} new articles, ${ads.length} ads, ${magazines.length} magazines.`)
process.exit(0)
