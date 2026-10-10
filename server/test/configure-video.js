require('dotenv').config();
const { ensurePrivateCallType, CALL_TYPE } = require('../dist/video');
ensurePrivateCallType().then(() => {
  console.log(`Stream credentials verified; private call type ${CALL_TYPE} configured.`);
}).catch(() => {
  console.error('Could not configure Stream video. Check credentials, connectivity and Video activation in the dashboard.');
  process.exitCode = 1;
});
