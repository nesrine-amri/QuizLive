import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Partners
  await prisma.partner.upsert({
    where: { id: 'mg' },
    update: { name: 'MG, Magasin Général', isActive: true },
    create: { id: 'mg', name: 'MG, Magasin Général', category: 'retail', isActive: true },
  });

  await prisma.partner.upsert({
    where: { id: 'lloyd' },
    update: { name: 'Lloyd Assurances', isActive: true },
    create: { id: 'lloyd', name: 'Lloyd Assurances', category: 'insurance', isActive: true },
  });

  // ── Rewards ────────────────────────────────────────────────────────────────
  //
  //  Two tiers per partner, aligned with scoring constants in gameplay.service:
  //
  //  TIER 1 — 10% discount at 500 pts
  //    Average viewer reaches this in ~1 hour of active watching (70% correct rate)
  //    Good entry reward: lowers the barrier, gets users hooked early
  //
  //  TIER 2 — 15% discount at 1000 pts
  //    Average viewer reaches this in ~2 hours of active watching
  //    Premium reward: meaningful enough for partners to fund it
  //
  //  Logic for partners:
  //    - A user who watched 2h of Tunisian TV is a highly engaged, qualified lead
  //    - 15% discount is the standard "activation" rate used in Tunisian retail promo
  //    - Partners get anonymised age/gender/region data from Analytics per answered question

  // MG (Magasin Général) — Tier 1
  await prisma.reward.upsert({
    where: { id: 'reward_mg_10' },
    update: { isActive: true, requiredPoints: 500, discountValue: 10 },
    create: {
      id: 'reward_mg_10',
      partnerId: 'mg',
      title: 'تخفيض 10% عند MG',
      description: 'بون تخفيض 10% على أي مشتريات في MG. صالح 30 يوم من تاريخ الاستلام.',
      requiredPoints: 500,
      discountValue: 10,
      expiresInDays: 30,
      isActive: true,
    },
  });

  // MG — Tier 2
  await prisma.reward.upsert({
    where: { id: 'reward_mg_15' },
    update: { isActive: true, requiredPoints: 1000, discountValue: 15 },
    create: {
      id: 'reward_mg_15',
      partnerId: 'mg',
      title: 'تخفيض 15% عند MG',
      description: 'بون تخفيض 15% على أي مشتريات في MG. صالح 30 يوم من تاريخ الاستلام.',
      requiredPoints: 1000,
      discountValue: 15,
      expiresInDays: 30,
      isActive: true,
    },
  });

  // Lloyd Assurances — Tier 1
  await prisma.reward.upsert({
    where: { id: 'reward_lloyd_10' },
    update: { isActive: true, requiredPoints: 500, discountValue: 10 },
    create: {
      id: 'reward_lloyd_10',
      partnerId: 'lloyd',
      title: 'تخفيض 10% عند Lloyd',
      description: 'تخفيض 10% على تجديد تأمينك عند Lloyd Assurances. صالح 30 يوم.',
      requiredPoints: 500,
      discountValue: 10,
      expiresInDays: 30,
      isActive: true,
    },
  });

  // Lloyd Assurances — Tier 2
  await prisma.reward.upsert({
    where: { id: 'reward_lloyd_15' },
    update: { isActive: true, requiredPoints: 1000, discountValue: 15 },
    create: {
      id: 'reward_lloyd_15',
      partnerId: 'lloyd',
      title: 'تخفيض 15% عند Lloyd',
      description: 'تخفيض 15% على تجديد تأمينك عند Lloyd Assurances. صالح 30 يوم.',
      requiredPoints: 1000,
      discountValue: 15,
      expiresInDays: 30,
      isActive: true,
    },
  });

  // ── Media channels ──────────────────────────────────────────────────────────
  //
  //  Single YouTube live URL (Watania) to avoid mixing several live sources.
  //  All other media: youtubeUrl null → FastAPI uses the local demo video file.
  //  yt-dlp resolves the URL to HLS at runtime (cached 3h in FastAPI).

  const tv = [
    {
      id: 'wataniya1_tv',
      name: 'Watania 1',
      type: 'TV' as const,
      popularity: 96,
      logoUrl: 'https://www.google.com/s2/favicons?domain=elwatania1.com&sz=128',
      youtubeUrl: 'https://www.youtube.com/watch?v=a32T-z4QZX4',
    },
    {
      id: 'wataniya2_tv',
      name: 'Watania 2',
      type: 'TV' as const,
      popularity: 94,
      logoUrl: 'https://www.google.com/s2/favicons?domain=elwatania2.com&sz=128',
      youtubeUrl: null,
    },
    {
      id: 'elhiwar_tv',
      name: 'El Hiwar Ettounsi',
      type: 'TV' as const,
      popularity: 98,
      logoUrl: 'https://www.google.com/s2/favicons?domain=elhiwarettounsi.com&sz=128',
      youtubeUrl: null,
    },
    {
      id: 'nessma_tv',
      name: 'Nessma TV',
      type: 'TV' as const,
      popularity: 92,
      logoUrl: 'https://www.google.com/s2/favicons?domain=nessma.tv&sz=128',
      youtubeUrl: null,
    },
    {
      id: 'attessia_tv',
      name: 'Attessia TV',
      type: 'TV' as const,
      popularity: 90,
      logoUrl: 'https://www.google.com/s2/favicons?domain=attessia.tv&sz=128',
      youtubeUrl: null,
    },
  ];

  const radio = [
    {
      id: 'mosaique_fm',
      name: 'Mosaique FM',
      type: 'RADIO' as const,
      popularity: 98,
      logoUrl: 'https://www.google.com/s2/favicons?domain=mosaiquefm.net&sz=128',
      youtubeUrl: null,
    },
    {
      id: 'ifm',
      name: 'IFM',
      type: 'RADIO' as const,
      popularity: 95,
      logoUrl: 'https://www.google.com/s2/favicons?domain=ifm.tn&sz=128',
      youtubeUrl: null,
    },
    {
      id: 'express_fm',
      name: 'Express FM',
      type: 'RADIO' as const,
      popularity: 92,
      logoUrl: 'https://www.google.com/s2/favicons?domain=radioexpressfm.com&sz=128',
      youtubeUrl: null,
    },
    {
      id: 'diwan_fm',
      name: 'Diwan FM',
      type: 'RADIO' as const,
      popularity: 90,
      logoUrl: 'https://www.google.com/s2/favicons?domain=diwanfm.net&sz=128',
      youtubeUrl: null,
    },
    {
      id: 'shems_fm',
      name: 'Shems FM',
      type: 'RADIO' as const,
      popularity: 85,
      logoUrl: 'https://www.google.com/s2/favicons?domain=shemsfm.net&sz=128',
      youtubeUrl: null,
    },
  ];

  for (const m of [...tv, ...radio]) {
    await prisma.media.upsert({
      where: { id: m.id },
      update: {
        name: m.name,
        type: m.type,
        isActive: true,
        popularity: m.popularity,
        logoUrl: m.logoUrl,
        youtubeUrl: m.youtubeUrl ?? null,
      },
      create: {
        id: m.id,
        name: m.name,
        type: m.type,
        isActive: true,
        popularity: m.popularity,
        logoUrl: m.logoUrl,
        youtubeUrl: m.youtubeUrl ?? null,
      },
    });
  }
}

main()
  .then(async () => prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });

