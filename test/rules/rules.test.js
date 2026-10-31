// Firestore rules tests. Run: npm install && npm test (needs Java for the emulator).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  updateDoc,
  deleteDoc,
  writeBatch,
} from 'firebase/firestore';

let env;

function monthKey(d = new Date()) {
  const t = new Date(d.getTime() + 330 * 60000);
  return `${t.getUTCFullYear()}-${String(t.getUTCMonth() + 1).padStart(2, '0')}`;
}
const M = monthKey();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-votewala',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const db = (uid) => env.authenticatedContext(uid, { email_verified: true }).firestore();
const unverified = (uid) => env.authenticatedContext(uid, { email_verified: false, firebase: { sign_in_provider: 'password' } }).firestore();

/** What the app sends for a vote: ballot + tally + user counter (+ badges). */
function voteBatch(fs, uid, pollId, bucket, option, { firstVote = true, badges = [] } = {}) {
  const b = writeBatch(fs);
  b.set(doc(fs, `votes/${pollId}/ballots/${uid}`), { bucket, option, at: serverTimestamp() });
  b.set(doc(fs, `tallies/${pollId}/buckets/${bucket}`), { [`o${option}`]: increment(1), total: increment(1) }, { merge: true });
  const user = { voteCount: increment(1), lastActionAt: serverTimestamp(), lastBallot: `votes/${pollId}/ballots/${uid}` };
  b.set(doc(fs, `users/${uid}`), user, { merge: true });
  for (const id of badges) b.set(doc(fs, `users/${uid}/badges/${id}`), { at: serverTimestamp() });
  return b;
}

function issueBatch(fs, uid, bucket, choices) {
  const pollId = `issues-${M}`;
  const b = writeBatch(fs);
  b.set(doc(fs, `votes/${pollId}/ballots/${uid}`), { bucket, choices, at: serverTimestamp() });
  for (const [slot, v] of Object.entries(choices)) {
    b.set(doc(fs, `tallies/${pollId}/buckets/${bucket}_${slot}`), { [`o${v}`]: increment(1), total: increment(1) }, { merge: true });
  }
  b.set(doc(fs, `users/${uid}`), { voteCount: increment(1), lastActionAt: serverTimestamp(), lastBallot: `votes/${pollId}/ballots/${uid}` }, { merge: true });
  return b;
}

async function ageRateLimit(uid) {
  await env.withSecurityRulesDisabled((ctx) =>
    updateDoc(doc(ctx.firestore(), `users/${uid}`), { lastActionAt: new Date(Date.now() - 60000) }));
}

describe('monthly constituency polls', () => {
  test('a voter casts one MLA vote and the tally counts it', async () => {
    const fs = db('alice');
    await assertSucceeds(voteBatch(fs, 'alice', `mla-${M}`, 'mla-37', 0, { badges: ['first-voice'] }).commit());
    const t = await getDoc(doc(fs, `tallies/mla-${M}/buckets/mla-37`));
    if (t.data().o0 !== 1 || t.data().total !== 1) throw new Error('tally not counted');
  });

  test('a second vote in the same month is rejected', async () => {
    const fs = db('alice');
    await voteBatch(fs, 'alice', `mla-${M}`, 'mla-37', 0).commit();
    await ageRateLimit('alice');
    await assertFails(voteBatch(fs, 'alice', `mla-${M}`, 'mla-12', 1).commit());
  });

  test('MLA and MP are separate polls', async () => {
    const fs = db('alice');
    await voteBatch(fs, 'alice', `mla-${M}`, 'mla-37', 0).commit();
    await ageRateLimit('alice');
    await assertSucceeds(voteBatch(fs, 'alice', `mp-${M}`, 'mp-3', 1).commit());
  });

  test('votes in a past month are rejected', async () => {
    await assertFails(voteBatch(db('alice'), 'alice', 'mla-2020-01', 'mla-37', 0).commit());
  });

  test('voting too fast is rate limited', async () => {
    const fs = db('alice');
    await voteBatch(fs, 'alice', `mla-${M}`, 'mla-37', 0).commit();
    await assertFails(voteBatch(fs, 'alice', `mp-${M}`, 'mp-3', 1).commit());
  });

  test('a vote for someone else is rejected', async () => {
    await assertFails(voteBatch(db('mallory'), 'alice', `mla-${M}`, 'mla-37', 0).commit());
  });

  test('unverified email accounts cannot vote', async () => {
    await assertFails(voteBatch(unverified('ivy'), 'ivy', `mla-${M}`, 'mla-37', 0).commit());
    await assertSucceeds(getDoc(doc(unverified('ivy'), `tallies/mla-${M}/buckets/mla-37`)));
  });

  test('signed-out users cannot vote', async () => {
    await assertFails(voteBatch(env.unauthenticatedContext().firestore(), 'x', `mla-${M}`, 'mla-37', 0).commit());
  });

  test('tallies cannot be inflated without a ballot', async () => {
    const fs = db('mallory');
    await assertFails(setDoc(doc(fs, `tallies/mla-${M}/buckets/mla-37`), { o0: increment(5), total: increment(5) }, { merge: true }));
    const b = voteBatch(fs, 'mallory', `mla-${M}`, 'mla-37', 0);
    b.set(doc(fs, `tallies/mla-${M}/buckets/mla-37`), { o0: increment(2), total: increment(2) }, { merge: true });
    await assertFails(b.commit());
  });

  test('a ballot without its tally update is rejected', async () => {
    const fs = db('alice');
    const b = writeBatch(fs);
    b.set(doc(fs, `votes/mla-${M}/ballots/alice`), { bucket: 'mla-37', option: 0, at: serverTimestamp() });
    b.set(doc(fs, 'users/alice'), { voteCount: increment(1), lastActionAt: serverTimestamp(), lastBallot: `votes/mla-${M}/ballots/alice` }, { merge: true });
    await assertFails(b.commit());
  });

  test('ballots are private and immutable', async () => {
    await voteBatch(db('alice'), 'alice', `mla-${M}`, 'mla-37', 0).commit();
    await assertFails(getDoc(doc(db('bob'), `votes/mla-${M}/ballots/alice`)));
    await assertFails(updateDoc(doc(db('alice'), `votes/mla-${M}/ballots/alice`), { option: 1 }));
    await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), `tallies/mla-${M}/buckets/mla-37`)));
  });

  test('featured polls use shards', async () => {
    await assertSucceeds(voteBatch(db('alice'), 'alice', 'f-vote-for-cm', `${M}-s4`, 2).commit());
    await assertFails(voteBatch(db('carol'), 'carol', 'f-vote-for-cm', '2020-01-s4', 2).commit());
    await assertFails(voteBatch(db('bob'), 'bob', 'f-vote-for-cm', 'mla-1', 2).commit());
  });
});

describe('badges', () => {
  test('badges unlock only at their milestone and only once', async () => {
    const fs = db('alice');
    await assertFails(voteBatch(fs, 'alice', `mla-${M}`, 'mla-37', 0, { badges: ['active-voice'] }).commit());
    await voteBatch(fs, 'alice', `mla-${M}`, 'mla-37', 0, { badges: ['first-voice'] }).commit();
    await assertFails(setDoc(doc(fs, 'users/alice/badges/first-voice'), { at: serverTimestamp() }));
    await assertFails(setDoc(doc(fs, 'users/alice/badges/made-up'), { at: serverTimestamp() }));
  });

  test('vote counts cannot be edited directly', async () => {
    const fs = db('alice');
    await voteBatch(fs, 'alice', `mla-${M}`, 'mla-37', 0).commit();
    await ageRateLimit('alice');
    await assertFails(setDoc(doc(fs, 'users/alice'), { voteCount: 100 }, { merge: true }));
  });
});

describe('local issues', () => {
  test('GOOD/BAD feedback counts per category', async () => {
    const fs = db('alice');
    await assertSucceeds(issueBatch(fs, 'alice', 'mla-21', { c0: 1, c3: 0 }).commit());
    const t0 = (await getDoc(doc(fs, `tallies/issues-${M}/buckets/mla-21_c0`))).data();
    const t3 = (await getDoc(doc(fs, `tallies/issues-${M}/buckets/mla-21_c3`))).data();
    if (t0.o1 !== 1 || t3.o0 !== 1 || t0.total !== 1) throw new Error(JSON.stringify([t0, t3]));
  });

  test('all ten categories in one submission fit the rules limits', async () => {
    const choices = Object.fromEntries([...Array(10).keys()].map((i) => [`c${i}`, i % 2]));
    await issueBatch(db('bob'), 'bob', 'mla-21', { c0: 1 }).commit();
    const fs = db('alice');
    const b = issueBatch(fs, 'alice', 'mla-21', choices);
    b.set(doc(fs, 'users/alice/badges/first-voice'), { at: serverTimestamp() });
    await assertSucceeds(b.commit());
  });

  test('miscounted feedback is rejected', async () => {
    const fs = db('mallory');
    const b = issueBatch(fs, 'mallory', 'mla-21', { c0: 1 });
    b.set(doc(fs, `tallies/issues-${M}/buckets/mla-21_c5`), { o1: increment(1), total: increment(1) }, { merge: true });
    await assertFails(b.commit());
    await assertFails(issueBatch(db('eve'), 'eve', 'mla-21', { c0: 7 }).commit());
  });

  async function photo(fs, uid, slot, choice, extra = {}) {
    const pollId = `issues-${M}`;
    const id = `${pollId}_${uid}_${slot}`;
    const b = writeBatch(fs);
    b.set(doc(fs, `photos/${id}`), {
      pollId, bucket: 'mla-21', slot, choice, uid, file: `issue-photos/${uid}/${slot}.jpg`,
      caption: 'Potholes near the bus stand', status: 'pending', at: serverTimestamp(), ...extra,
    });
    b.set(doc(fs, `tallies/${pollId}/buckets/mla-21_${slot}`), { [`p${choice}`]: increment(1) }, { merge: true });
    b.set(doc(fs, `users/${uid}`), { lastPhoto: id, lastActionAt: serverTimestamp() }, { merge: true });
    return b.commit();
  }

  test('an evidence photo is counted once, for the voter\'s own choice', async () => {
    const fs = db('alice');
    await issueBatch(fs, 'alice', 'mla-21', { c0: 1 }).commit();
    await ageRateLimit('alice');
    await assertFails(photo(fs, 'alice', 'c0', 0));
    await assertSucceeds(photo(fs, 'alice', 'c0', 1));
    await ageRateLimit('alice');
    await assertFails(photo(fs, 'alice', 'c0', 1));
    await assertFails(getDoc(doc(db('bob'), `photos/issues-${M}_alice_c0`)));
  });

  test('admins review photos; voters cannot approve their own', async () => {
    const fs = db('alice');
    await issueBatch(fs, 'alice', 'mla-21', { c0: 1 }).commit();
    await ageRateLimit('alice');
    await photo(fs, 'alice', 'c0', 1);
    const id = `photos/issues-${M}_alice_c0`;
    await assertFails(updateDoc(doc(fs, id), { status: 'approved' }));
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'admins/boss'), { role: 'admin' }));
    await assertSucceeds(updateDoc(doc(db('boss'), id), { status: 'approved', reviewedAt: serverTimestamp() }));
  });

  test('threshold alerts need the BAD count to reach the threshold', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'settings/thresholds'), { default: 2 }));
    const pollId = `issues-${M}`;
    const alert = (fs) => setDoc(doc(fs, `alerts/${pollId}_mla-21_c0_2`), {
      pollId, bucket: 'mla-21', slot: 'c0', threshold: 2, at: serverTimestamp(), seen: false,
    });
    await issueBatch(db('alice'), 'alice', 'mla-21', { c0: 1 }).commit();
    await assertFails(alert(db('alice')));
    await issueBatch(db('bob'), 'bob', 'mla-21', { c0: 1 }).commit();
    await assertSucceeds(alert(db('bob')));
    await assertFails(alert(db('carol')));
    await assertFails(getDoc(doc(db('bob'), `alerts/${pollId}_mla-21_c0_2`)));
  });
});

describe('admin data', () => {
  test('admins read vote counts but not ballots', async () => {
    await voteBatch(db('alice'), 'alice', `mla-${M}`, 'mla-37', 0).commit();
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'admins/boss'), { role: 'admin' }));
    await assertSucceeds(getDoc(doc(db('boss'), 'users/alice')));
    await assertFails(getDoc(doc(db('bob'), 'users/alice')));
    await assertFails(getDoc(doc(db('boss'), `votes/mla-${M}/ballots/alice`)));
  });

  test('admins edit only their own profile fields', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'admins/boss'), { role: 'owner', username: 'admin', mustChangePassword: true }));
    await assertSucceeds(updateDoc(doc(db('boss'), 'admins/boss'), { mustChangePassword: false, displayName: 'Ashok' }));
    await assertFails(updateDoc(doc(db('boss'), 'admins/boss'), { role: 'superuser' }));
    await assertFails(updateDoc(doc(db('boss'), 'admins/boss'), { mustChangePassword: true }));
    await assertFails(setDoc(doc(db('alice'), 'admins/alice'), { role: 'owner' }));
  });

  test('owners add and remove admins; admins cannot', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'admins/boss'), { role: 'owner', username: 'admin' });
      await setDoc(doc(ctx.firestore(), 'admins/helper'), { role: 'admin', username: 'helper' });
    });
    const newAdmin = { role: 'admin', username: 'ravi', displayName: 'Ravi', mustChangePassword: true };
    await assertSucceeds(setDoc(doc(db('boss'), 'admins/ravi'), newAdmin));
    await assertFails(setDoc(doc(db('boss'), 'admins/sita'), { ...newAdmin, role: 'owner' }));
    await assertFails(setDoc(doc(db('helper'), 'admins/sita'), newAdmin));
    await assertFails(deleteDoc(doc(db('helper'), 'admins/ravi')));
    await assertSucceeds(deleteDoc(doc(db('boss'), 'admins/ravi')));
    await assertFails(deleteDoc(doc(db('boss'), 'admins/boss')));
  });

  test('blocked voters cannot vote; profiles are private to admins', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'admins/boss'), { role: 'owner' });
    });
    await assertSucceeds(setDoc(doc(db('boss'), 'blocked/mallory'), { reason: 'fake accounts' }));
    await assertFails(setDoc(doc(db('alice'), 'blocked/mallory'), { reason: 'x' }));
    await assertFails(voteBatch(db('mallory'), 'mallory', `mla-${M}`, 'mla-37', 0).commit());
    await assertSucceeds(voteBatch(db('alice'), 'alice', `mla-${M}`, 'mla-37', 0).commit());
    const me = env.authenticatedContext('alice', { email: 'a@x.com', email_verified: true }).firestore();
    await assertSucceeds(setDoc(doc(me, 'profiles/alice'), { email: 'a@x.com', name: 'A', provider: 'google', lastSeen: serverTimestamp() }));
    await assertFails(setDoc(doc(me, 'profiles/alice'), { email: 'other@x.com', name: 'A', provider: 'google', lastSeen: serverTimestamp() }));
    await assertFails(getDoc(doc(db('bob'), 'profiles/alice')));
    await assertSucceeds(getDoc(doc(db('boss'), 'profiles/alice')));
  });

  test('only admins change settings and grievances', async () => {
    await assertFails(setDoc(doc(db('alice'), 'settings/thresholds'), { default: 1 }));
    await assertFails(setDoc(doc(db('alice'), 'grievances/g1'), { status: 'resolved' }));
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'admins/boss'), { role: 'admin' }));
    await assertSucceeds(setDoc(doc(db('boss'), 'grievances/g1'), { status: 'threshold' }));
    await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), 'grievances/g1')));
  });
});
