/**
 * Imports the official LGD (Local Government Directory) hierarchy for Telangana and Andhra Pradesh:
 * state → district → mandal (sub-district) → village, keyed by LGD codes.
 *
 * Source: daily LGD snapshot published at https://ramseraph.github.io/opendata/lgd/ (Parquet).
 *
 * Telugu names:
 *   - states & districts: curated below (from the client's list)
 *   - villages: LGD `village_name_local` (complete for Telangana, sparse for Andhra Pradesh)
 *   - mandals: matched from the client's Telugu list in data/client-mandals-te.txt (if present),
 *              otherwise from the mandal's headquarters village of the same name
 *
 * Idempotent: upserts every row and deactivates locations that disappeared from LGD (never deletes,
 * because articles reference them).
 *
 * Usage: npm run seed:locations [-- --dry-run]
 */
import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { asyncBufferFromFile, parquetReadObjects } from 'hyparquet'
import { compressors } from 'hyparquet-compressors'
import postgres from 'postgres'
import 'dotenv/config'

const DRY_RUN = process.argv.includes('--dry-run')
const BASE = 'https://ramseraph.github.io/opendata/lgd/data'
const CACHE = join(import.meta.dirname, '..', '.cache', 'lgd')
const STATES = { '28': 'Andhra Pradesh', '36': 'Telangana' } as const

const STATE_TE: Record<string, string> = { '28': 'ఆంధ్రప్రదేశ్', '36': 'తెలంగాణ' }

// LGD district name → Telugu (from the client's list). NTR is spelled "Ntr" in LGD.
const DISTRICT_TE: Record<string, string> = {
  // Telangana (33)
  Adilabad: 'ఆదిలాబాద్', 'Bhadradri Kothagudem': 'భద్రాద్రి కొత్తగూడెం', Hanumakonda: 'హనుమకొండ', Hyderabad: 'హైదరాబాద్',
  Jagitial: 'జగిత్యాల', Jangoan: 'జనగామ', 'Jayashankar Bhupalapally': 'జయశంకర్ భూపాలపల్లి', 'Jogulamba Gadwal': 'జోగులాంబ గద్వాల',
  Kamareddy: 'కామారెడ్డి', Karimnagar: 'కరీంనగర్', Khammam: 'ఖమ్మం', 'Kumuram Bheem Asifabad': 'కుమురం భీం ఆసిఫాబాద్',
  Mahabubabad: 'మహబూబాబాద్', Mahabubnagar: 'మహబూబ్‌నగర్', Mancherial: 'మంచిర్యాల', Medak: 'మెదక్',
  'Medchal Malkajgiri': 'మేడ్చల్–మల్కాజిగిరి', Mulugu: 'ములుగు', Nagarkurnool: 'నాగర్‌కర్నూల్', Nalgonda: 'నల్గొండ',
  Narayanpet: 'నారాయణపేట', Nirmal: 'నిర్మల్', Nizamabad: 'నిజామాబాద్', Peddapalli: 'పెద్దపల్లి',
  'Rajanna Sircilla': 'రాజన్న సిరిసిల్ల', 'Ranga Reddy': 'రంగారెడ్డి', Sangareddy: 'సంగారెడ్డి', Siddipet: 'సిద్ధిపేట',
  Suryapet: 'సూర్యాపేట', Vikarabad: 'వికారాబాద్', Wanaparthy: 'వనపర్తి', Warangal: 'వరంగల్', 'Yadadri Bhuvanagiri': 'యాదాద్రి భువనగిరి',
  // Andhra Pradesh (28)
  'Alluri Sitharama Raju': 'అల్లూరి సీతారామరాజు', Anakapalli: 'అనకాపల్లి', Ananthapuramu: 'అనంతపురం', Annamayya: 'అన్నమయ్య',
  Bapatla: 'బాపట్ల', Chittoor: 'చిత్తూరు', 'Dr. B.R. Ambedkar Konaseema': 'డాక్టర్ బి.ఆర్. అంబేద్కర్ కోనసీమ', 'East Godavari': 'తూర్పు గోదావరి',
  Eluru: 'ఏలూరు', Guntur: 'గుంటూరు', Kakinada: 'కాకినాడ', Krishna: 'కృష్ణా', Kurnool: 'కర్నూలు', Markapuram: 'మార్కాపురం',
  Nandyal: 'నంద్యాల', Ntr: 'ఎన్టీఆర్', Palnadu: 'పల్నాడు', 'Parvathipuram Manyam': 'పార్వతీపురం మన్యం', Polavaram: 'పోలవరం',
  Prakasam: 'ప్రకాశం', 'Sri Potti Sriramulu Nellore': 'శ్రీ పొట్టి శ్రీరాములు నెల్లూరు', 'Sri Sathya Sai': 'శ్రీ సత్యసాయి',
  Srikakulam: 'శ్రీకాకుళం', Tirupati: 'తిరుపతి', Visakhapatnam: 'విశాఖపట్నం', Vizianagaram: 'విజయనగరం', 'West Godavari': 'పశ్చిమ గోదావరి',
  'Y.S.R. Kadapa': 'వైఎస్సార్ కడప',
}
const DISTRICT_EN_FIX: Record<string, string> = { Ntr: 'NTR' }

// ------------------------------------------------------------------ download

type Row = Record<string, unknown>

async function dataset(name: string): Promise<Row[]> {
  mkdirSync(CACHE, { recursive: true })
  const metaPath = join(CACHE, 'metadata.json')
  if (!existsSync(metaPath) || Date.now() - statSync(metaPath).mtimeMs > 12 * 3600_000) {
    const res = await fetch(`${BASE}/metadata.json`)
    if (!res.ok) throw new Error(`LGD metadata download failed: ${res.status}`)
    writeFileSync(metaPath, Buffer.from(await res.arrayBuffer()))
  }
  const meta = JSON.parse(readFileSync(metaPath, 'utf8'))
  const url: string = meta.datasets[name]?.daily?.file?.url
  if (!url) throw new Error(`Dataset ${name} not in LGD metadata`)
  const file = join(CACHE, url.split('/').pop()!)
  if (!existsSync(file)) {
    console.log(`Downloading ${name}…`)
    const res = await fetch(url)
    if (!res.ok) throw new Error(`Download failed for ${url}: ${res.status}`)
    writeFileSync(file, Buffer.from(await res.arrayBuffer()))
  }
  const rows = (await parquetReadObjects({ file: await asyncBufferFromFile(file), compressors })) as Row[]
  return rows.filter((r) => String(r.state_code) in STATES)
}

// ------------------------------------------------------------------ name matching (Telugu ↔ English)

const CONS: Record<string, string> = {
  క: 'k', ఖ: 'kh', గ: 'g', ఘ: 'gh', ఙ: 'n', చ: 'ch', ఛ: 'ch', జ: 'j', ఝ: 'jh', ఞ: 'n', ట: 't', ఠ: 'th', డ: 'd', ఢ: 'dh', ణ: 'n',
  త: 't', థ: 'th', ద: 'd', ధ: 'dh', న: 'n', ప: 'p', ఫ: 'ph', బ: 'b', భ: 'bh', మ: 'm', య: 'y', ర: 'r', ల: 'l', వ: 'v', శ: 'sh',
  ష: 'sh', స: 's', హ: 'h', ళ: 'l', ఱ: 'r',
}
const VOWELS: Record<string, string> = { అ: 'a', ఆ: 'aa', ఇ: 'i', ఈ: 'ee', ఉ: 'u', ఊ: 'oo', ఋ: 'ru', ఎ: 'e', ఏ: 'e', ఐ: 'ai', ఒ: 'o', ఓ: 'o', ఔ: 'au' }
const MATRAS: Record<string, string> = { 'ా': 'aa', 'ి': 'i', 'ీ': 'ee', 'ు': 'u', 'ూ': 'oo', 'ృ': 'ru', 'ె': 'e', 'ే': 'e', 'ై': 'ai', 'ొ': 'o', 'ో': 'o', 'ౌ': 'au' }

export function romanizeTelugu(s: string): string {
  let out = ''
  const chars = [...s]
  for (let i = 0; i < chars.length; i++) {
    const c = chars[i]!
    const next = chars[i + 1]
    if (CONS[c]) {
      out += CONS[c]
      // inherent 'a' unless a vowel sign or virama follows (skeleton() later drops a trailing 'a')
      if (next && (MATRAS[next] !== undefined || next === '్')) continue
      out += 'a'
    } else if (MATRAS[c] !== undefined) out += MATRAS[c]
    else if (VOWELS[c]) out += VOWELS[c]
    else if (c === 'ం') out += next && /[పబభమఫ]/.test(next) ? 'm' : 'n'
    else if (c === '్' || c === '‌' || c === '‍') continue
    else if (c === 'ః') out += 'h'
    else out += c
  }
  return out
}

/** Collapse spelling variation so "Bheempur", "Bhimpur" and romanised "భీంపూర్" compare equal. */
export function skeleton(s: string): string {
  return s
    .toLowerCase()
    .replace(/\(.*?\)/g, '')
    .replace(/[^a-z]/g, '')
    .replace(/(kh|gh|ch|jh|th|dh|ph|bh|sh)/g, (m) => m[0]!)
    .replace(/aa/g, 'a')
    .replace(/ee/g, 'i')
    .replace(/oo|ou/g, 'u')
    .replace(/w/g, 'v')
    .replace(/z/g, 'j')
    .replace(/y/g, 'i')
    .replace(/(.)\1+/g, '$1')
    .replace(/a$/, '')
}

function levenshtein(a: string, b: string): number {
  const dp = Array.from({ length: b.length + 1 }, (_, i) => i)
  for (let i = 1; i <= a.length; i++) {
    let prev = dp[0]!
    dp[0] = i
    for (let j = 1; j <= b.length; j++) {
      const tmp = dp[j]!
      dp[j] = Math.min(dp[j]! + 1, dp[j - 1]! + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1))
      prev = tmp
    }
  }
  return dp[b.length]!
}

/** Parses the client's Telugu list: district headings followed by "* mandal" bullets; notes are skipped. */
function parseClientList(text: string): Map<string, string[]> {
  const byDistrict = new Map<string, string[]>()
  const teToEn = new Map(Object.entries(DISTRICT_TE).map(([en, te]) => [te.replace(/‌/g, ''), en]))
  let current: string | null = null
  for (const raw of text.split('\n')) {
    const line = raw.trim()
    if (!line) continue
    if (line.includes('జిల్లా') && !line.startsWith('*')) {
      const name = line
        .replace(/^#+\s*/, '')
        .replace(/^\d+\\?\.\s*/, '')
        .replace(/\s*జిల్లా.*$/, '')
        .replace(/‌/g, '')
        .trim()
      current = teToEn.get(name) ?? null
      if (!current) console.warn(`  client list: unknown district heading "${line}"`)
      continue
    }
    if (line.startsWith('*') && current) {
      const mandal = line.replace(/^\*\s*/, '').trim()
      if (!mandal || /తాజా|నిర్ధారించ|నిర్ధారణ|పరిశీలించాలి|ధృవీకరించాలి/.test(mandal)) continue
      byDistrict.set(current, [...(byDistrict.get(current) ?? []), mandal])
    }
  }
  return byDistrict
}

// ------------------------------------------------------------------ main

interface Loc {
  id: number
  level: 'state' | 'district' | 'mandal' | 'village'
  parentId: number | null
  stateId: number | null
  districtId: number | null
  mandalId: number | null
  nameEn: string
  nameTe: string | null
}

const titleCase = (s: string) => s.replace(/\S+/g, (w) => (w.length <= 2 && w === w.toUpperCase() ? w : w[0]!.toUpperCase() + w.slice(1).toLowerCase()))

async function main() {
  const [states, districts, subdistricts, villages] = await Promise.all([
    dataset('states'),
    dataset('districts'),
    dataset('subdistricts'),
    dataset('villages'),
  ])

  const locs: Loc[] = []
  for (const s of states) {
    const id = Number(s.state_code)
    locs.push({ id, level: 'state', parentId: null, stateId: id, districtId: null, mandalId: null, nameEn: String(s.state_name), nameTe: STATE_TE[String(id)] ?? null })
  }
  const missingDistrictTe: string[] = []
  for (const d of districts) {
    const en = String(d.district_name)
    const id = Number(d.district_code)
    const stateId = Number(d.state_code)
    if (!DISTRICT_TE[en]) missingDistrictTe.push(en)
    locs.push({ id, level: 'district', parentId: stateId, stateId, districtId: id, mandalId: null, nameEn: DISTRICT_EN_FIX[en] ?? en, nameTe: DISTRICT_TE[en] ?? null })
  }

  // Villages first (we use them to derive mandal Telugu names)
  const villagesBySub = new Map<number, Row[]>()
  for (const v of villages) {
    if (v.village_status !== 'Inhabitant') continue
    const sub = Number(v.subdistrict_code)
    villagesBySub.set(sub, [...(villagesBySub.get(sub) ?? []), v])
  }

  const clientFile = join(import.meta.dirname, '..', 'data', 'client-mandals-te.txt')
  const clientList = existsSync(clientFile) ? parseClientList(readFileSync(clientFile, 'utf8')) : new Map<string, string[]>()
  const districtNameById = new Map(districts.map((d) => [Number(d.district_code), String(d.district_name)]))

  let teFromClient = 0
  let teFromVillage = 0
  const mandalTeMissing: string[] = []
  for (const sd of subdistricts) {
    const id = Number(sd.subdistrict_code)
    const districtId = Number(sd.district_code)
    const stateId = Number(sd.state_code)
    const nameEn = titleCase(String(sd.subdistrict_name))
    let nameTe: string | null = null

    // 1) client's Telugu list, matched by spelling skeleton inside the same district
    const candidates = clientList.get(districtNameById.get(districtId) ?? '') ?? []
    if (candidates.length) {
      const target = skeleton(nameEn)
      const scored = candidates
        .map((te) => ({ te, d: levenshtein(target, skeleton(romanizeTelugu(te))) }))
        .sort((a, b) => a.d - b.d)
      const best = scored[0]
      if (best && best.d <= Math.max(1, Math.floor(target.length * 0.25)) && (scored[1]?.d ?? 99) > best.d) {
        nameTe = best.te
        teFromClient++
      }
    }
    // 2) the headquarters village usually shares the mandal's name and has an LGD Telugu name
    if (!nameTe) {
      const target = skeleton(nameEn)
      const hq = (villagesBySub.get(id) ?? []).find((v) => v.village_name_local && skeleton(String(v.village_name)) === target)
      if (hq) {
        nameTe = String(hq.village_name_local)
        teFromVillage++
      }
    }
    if (!nameTe) mandalTeMissing.push(`${nameEn} (${districtNameById.get(districtId)})`)
    locs.push({ id, level: 'mandal', parentId: districtId, stateId, districtId, mandalId: id, nameEn, nameTe })
  }

  let villageCount = 0
  for (const [sub, vs] of villagesBySub) {
    for (const v of vs) {
      const id = Number(v.village_code)
      locs.push({
        id,
        level: 'village',
        parentId: sub,
        stateId: Number(v.state_code),
        districtId: Number(v.district_code),
        mandalId: sub,
        nameEn: titleCase(String(v.village_name)),
        nameTe: v.village_name_local ? String(v.village_name_local) : null,
      })
      villageCount++
    }
  }

  // LGD codes are unique per level; make sure they don't collide across levels inside our two states.
  const seen = new Map<number, string>()
  for (const l of locs) {
    const prev = seen.get(l.id)
    if (prev) throw new Error(`LGD code ${l.id} used by both a ${prev} and a ${l.level}; cannot use codes as primary keys`)
    seen.set(l.id, l.level)
  }

  const count = (lvl: Loc['level'], st: number) => locs.filter((l) => l.level === lvl && l.stateId === st).length
  console.log('LGD snapshot:')
  for (const st of [36, 28]) {
    console.log(`  ${STATES[String(st) as '28' | '36']}: ${count('district', st)} districts, ${count('mandal', st)} mandals, ${count('village', st)} inhabited villages`)
  }
  console.log(`  Telugu mandal names: ${teFromClient} from client list, ${teFromVillage} from HQ village, ${mandalTeMissing.length} missing`)
  if (missingDistrictTe.length) console.warn('  Districts without Telugu name:', missingDistrictTe)
  if (!clientList.size) console.log('  (data/client-mandals-te.txt not found — add the client list to improve Telugu mandal names)')

  if (DRY_RUN) {
    writeFileSync(join(CACHE, 'mandals-missing-te.txt'), mandalTeMissing.join('\n'))
    console.log(`Dry run: ${locs.length} rows prepared, nothing written.`)
    return
  }

  const sql = postgres(process.env.DATABASE_URL!, { max: 1, prepare: false })
  try {
    await sql.begin(async (tx) => {
      const chunk = 2000
      for (let i = 0; i < locs.length; i += chunk) {
        const part = locs.slice(i, i + chunk).map((l) => ({
          id: l.id,
          level: l.level,
          parent_id: l.parentId,
          state_id: l.stateId,
          district_id: l.districtId,
          mandal_id: l.mandalId,
          name_en: l.nameEn,
          name_te: l.nameTe,
          is_active: true,
        }))
        await tx`
          INSERT INTO app.locations ${tx(part)}
          ON CONFLICT (id) DO UPDATE SET
            level = EXCLUDED.level, parent_id = EXCLUDED.parent_id, state_id = EXCLUDED.state_id,
            district_id = EXCLUDED.district_id, mandal_id = EXCLUDED.mandal_id, name_en = EXCLUDED.name_en,
            name_te = COALESCE(EXCLUDED.name_te, app.locations.name_te), is_active = true, updated_at = now()`
      }
      const ids = locs.map((l) => l.id)
      const res = await tx`UPDATE app.locations SET is_active = false, updated_at = now() WHERE is_active AND NOT (id = ANY(${ids}))`
      console.log(`Upserted ${locs.length} locations, deactivated ${res.count} stale rows.`)
    })
  } finally {
    await sql.end()
  }
  void villageCount
}

await main()
