'use strict';

// Keep security checks intact, but never describe an IAM/network error as a bad OTP.
async function verifyTransferToken({token, actor, verifyIdToken, makeError, logError = () => {}}) {
  if (typeof token !== 'string' || !token.trim()) {
    throw makeError('unauthenticated', actor === 'caller'
      ? 'Sign in again as the current administrator.'
      : 'Verify the new administrator again.', {reason: actor + '-session-invalid'});
  }
  try {
    return await verifyIdToken(token, true); // includes revoked/disabled-user checks
  } catch (error) {
    const code = typeof error.code === 'string' ? error.code : 'unknown';
    logError({actor, code}); // Never log bearer tokens or OTPs.
    if (['auth/id-token-expired', 'auth/id-token-revoked', 'auth/user-disabled',
      'auth/user-not-found', 'auth/invalid-id-token', 'auth/argument-error'].includes(code)) {
      throw makeError('unauthenticated', actor === 'caller'
        ? 'Your current-admin session is no longer valid. Sign in again.'
        : 'The new-admin session is no longer valid. Verify them again.',
      {reason: actor + '-session-invalid'});
    }
    if (['auth/insufficient-permission', 'auth/invalid-credential',
      'app/invalid-credential', 'auth/project-not-found', 'auth/configuration-not-found'].includes(code)) {
      throw makeError('failed-precondition',
        'The transfer server cannot check Firebase Authentication. The platform admin must check the function runtime account permissions.',
        {reason: 'transfer-auth-setup'});
    }
    throw makeError('unavailable', 'The transfer server could not check the session. Please retry.',
      {reason: 'transfer-auth-unavailable'});
  }
}
module.exports = {verifyTransferToken};
