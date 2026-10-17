'use strict';
function transferPatch(current, caller, recipient, input, nowSeconds) {
  if (!caller || !caller.uid || !caller.phone_number ||
      caller.phone_number !== '+91' + current.adminMobile ||
      (current.adminUid && current.adminUid !== caller.uid)) {
    throw new Error('Only the current verified administrator can transfer this masjid.');
  }
  if (current.adminMobile !== input.expectedAdminMobile ||
      (current.adminUid || null) !== (input.expectedAdminUid || null)) {
    throw new Error('Administration changed. Reopen the masjid and try again.');
  }
  if (!recipient || !recipient.uid || recipient.firebase?.sign_in_provider !== 'phone' ||
      recipient.phone_number !== '+91' + input.mobile ||
      !Number.isFinite(recipient.auth_time) || nowSeconds - recipient.auth_time > 600 ||
      recipient.auth_time > nowSeconds + 60) {
    throw new Error('Verify the new administrator phone with a fresh OTP.');
  }
  if (caller.uid === recipient.uid || current.adminMobile === input.mobile) {
    throw new Error('Choose a different administrator.');
  }
  if (typeof input.name !== 'string' || !input.name.trim() || input.name.length > 120 ||
      typeof input.email !== 'string' || input.email.length > 254 ||
      !/^[6-9]\d{9}$/.test(input.mobile)) {
    throw new Error('Enter valid new administrator details.');
  }
  return {adminUid: recipient.uid, adminName: input.name.trim(),
    adminMobile: input.mobile, adminEmail: input.email.trim()};
}
module.exports = {transferPatch};
