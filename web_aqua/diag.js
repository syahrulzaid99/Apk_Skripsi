try {
  require('./src/app.js');
  console.log('APP_LOADED_OK');
} catch (e) {
  const fs = require('fs');
  fs.writeFileSync('crash.log', (e && e.stack ? e.stack : String(e)));
  console.log('CRASH_CAPTURED');
}
