'use strict';
// Only fixed support codes cross the callable boundary. Never include provider
// response bodies, user questions, credentials or database paths.
function classifyFailure(error, stage) {
  if(error.failureKind==='corpus')return {code:'unavailable',supportCode:'AI-CORPUS'};
  if (error.name === 'TimeoutError' || error.name === 'AbortError' || [408,504].includes(error.status))
    return {code:'deadline-exceeded',supportCode:'AI-TIMEOUT'};
  if (error.failureKind === 'parse' || error.failureKind === 'response') return {code:'unavailable',supportCode:'AI-OUTPUT'};
  if (error.failureKind === 'network') return {code:'unavailable',supportCode:'AI-NETWORK'};
  if (error.status === 429) return {code:'resource-exhausted',supportCode:'AI-LIMIT'};
  if ([401,403].includes(error.status)) return {code:'failed-precondition',supportCode:'AI-KEY'};
  if (error.status === 400) return {code:'failed-precondition',supportCode:'AI-PROVIDER-REQUEST'};
  if (error.status === 404) return {code:'failed-precondition',supportCode:'AI-MODEL'};
  if (stage === 'quota' && [7,'7','permission-denied'].includes(error.code))
    return {code:'failed-precondition',supportCode:'AI-DATABASE'};
  if (stage === 'corpus') return {code:'failed-precondition',supportCode:'AI-CORPUS'};
  if (error instanceof SyntaxError || /^(gemini-blocked-or-incomplete|invalid-provider-output|invalid-plan|invalid-selection|invalid-citation|empty-essential-concept)/.test(error.message || ''))
    return {code:'unavailable',supportCode:'AI-OUTPUT'};
  return {code:'unavailable',supportCode:'AI-SERVER'};
}
module.exports={classifyFailure};
