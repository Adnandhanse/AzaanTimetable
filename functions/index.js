'use strict';
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {transferPatch} = require('./transfer_validation');
const {verifyTransferToken} = require('./token_verification');
const logger = require('firebase-functions/logger');
initializeApp();

exports.transferMasjidAdministration = onCall({region: 'us-central1'}, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Log in as the current masjid admin.', {reason: 'caller-session-invalid'});
  const input = request.data;
  if (!input || typeof input.masjidId !== 'string' || !input.masjidId ||
      input.masjidId.includes('/') || typeof input.recipientIdToken !== 'string' ||
      typeof input.operationId !== 'string' || !/^[a-zA-Z0-9-]{10,100}$/.test(input.operationId)) {
    throw new HttpsError('invalid-argument', 'Invalid transfer details.');
  }
  // Recheck revocation of A's actual bearer token, and independently verify B's token.
  const bearer = request.rawRequest.headers.authorization || '';
  const verify = (token, actor) => verifyTransferToken({
    token, actor,
    verifyIdToken: (value, checkRevoked) => getAuth().verifyIdToken(value, checkRevoked),
    makeError: (code, message, details) => new HttpsError(code, message, details),
    logError: (details) => logger.error('transfer-auth-verification-failed', details),
  });
  const caller = await verify(bearer.replace(/^Bearer /i, ''), 'caller');
  const recipient = await verify(input.recipientIdToken, 'recipient');
  const db = getFirestore();
  const masjidRef = db.collection('masjids').doc(input.masjidId);
  const auditRef = masjidRef.collection('ownershipHistory').doc(input.operationId);
  try {
    return await db.runTransaction(async (tx) => {
    const masjid = await tx.get(masjidRef);
    const audit = await tx.get(auditRef);
    if (audit.exists) {
      const prior = audit.data();
      if (prior.fromUid === caller.uid && prior.toUid === recipient.uid &&
          prior.toMobile === input.mobile) return {success: true};
      throw new HttpsError('already-exists', 'This transfer reference was already used.');
    }
    if (!masjid.exists) throw new HttpsError('not-found', 'Masjid not found.');
    const current = masjid.data();
    let patch;
    try { patch = transferPatch(current, caller, recipient, input, Math.floor(Date.now() / 1000)); }
    catch (error) {
      throw new HttpsError('failed-precondition', error.message,
        {reason: /fresh OTP/.test(error.message) ? 'recipient-session-invalid' : 'transfer-precondition'});
    }
    tx.update(masjidRef, {...patch,
      ownershipTransferredAt: FieldValue.serverTimestamp(),
      ownershipTransferRequestId: 'direct-' + input.operationId});
    tx.create(auditRef, {fromUid: caller.uid, fromMobile: current.adminMobile,
      toUid: recipient.uid, toMobile: input.mobile,
      method: 'current_admin_with_recipient_otp', transferredAt: FieldValue.serverTimestamp()});
    return {success: true};
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error.code === 7 || error.code === 'permission-denied') {
      logger.error('transfer-firestore-permission-denied');
      throw new HttpsError('failed-precondition',
        'The transfer server cannot update the masjid. The platform admin must check the function runtime Firestore permissions.',
        {reason: 'transfer-data-setup'});
    }
    throw error;
  }
});
