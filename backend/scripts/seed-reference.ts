/** Categories and default runtime config. Safe to re-run. */
import postgres from 'postgres'
import 'dotenv/config'

const categories = [
  { id: 1, slug: 'local', name_en: 'Local', name_te: 'స్థానికం', name_hi: 'स्थानीय' },
  { id: 2, slug: 'politics', name_en: 'Politics', name_te: 'రాజకీయాలు', name_hi: 'राजनीति' },
  { id: 3, slug: 'national', name_en: 'National', name_te: 'జాతీయం', name_hi: 'राष्ट्रीय' },
  { id: 4, slug: 'international', name_en: 'International', name_te: 'అంతర్జాతీయం', name_hi: 'अंतरराष्ट्रीय' },
  { id: 5, slug: 'business', name_en: 'Business', name_te: 'వ్యాపారం', name_hi: 'व्यापार' },
  { id: 6, slug: 'sports', name_en: 'Sports', name_te: 'క్రీడలు', name_hi: 'खेल' },
  { id: 7, slug: 'entertainment', name_en: 'Entertainment', name_te: 'వినోదం', name_hi: 'मनोरंजन' },
  { id: 8, slug: 'technology', name_en: 'Technology', name_te: 'సాంకేతికం', name_hi: 'प्रौद्योगिकी' },
  { id: 9, slug: 'health', name_en: 'Health', name_te: 'ఆరోగ్యం', name_hi: 'स्वास्थ्य' },
  { id: 10, slug: 'education', name_en: 'Education', name_te: 'విద్య', name_hi: 'शिक्षा' },
  { id: 11, slug: 'crime', name_en: 'Crime', name_te: 'నేరాలు', name_hi: 'अपराध' },
  { id: 12, slug: 'agriculture', name_en: 'Agriculture', name_te: 'వ్యవసాయం', name_hi: 'कृषि' },
  { id: 13, slug: 'weather', name_en: 'Weather', name_te: 'వాతావరణం', name_hi: 'मौसम' },
  { id: 14, slug: 'other', name_en: 'Other', name_te: 'ఇతరాలు', name_hi: 'अन्य' },
].map((c, i) => ({ ...c, sort_order: i, is_active: true }))

const config = [
  { key: 'feed', value: { adEvery: 5, magazineEvery: 10, magazineOffset: 3, districtWindowHours: 48, adsEnabled: true } },
  { key: 'app', value: { minVersion: '1.0.0', pushEnabled: false } },
]

const sql = postgres(process.env.DATABASE_URL!, { max: 1, prepare: false })
await sql`
  INSERT INTO app.categories ${sql(categories)}
  ON CONFLICT (id) DO UPDATE SET slug = EXCLUDED.slug, name_en = EXCLUDED.name_en, name_te = EXCLUDED.name_te,
    name_hi = EXCLUDED.name_hi, sort_order = EXCLUDED.sort_order`
for (const c of config) {
  await sql`INSERT INTO app.app_config (key, value) VALUES (${c.key}, ${sql.json(c.value)}) ON CONFLICT (key) DO NOTHING`
}
await sql.end()
console.log(`Seeded ${categories.length} categories and default config.`)
