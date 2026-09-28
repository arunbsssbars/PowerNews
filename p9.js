const fs = require('fs');
let code = fs.readFileSync('android/gradle/wrapper/gradle-wrapper.properties', 'utf8');
code = code.replace(/gradle-8\.3-all\.zip/, 'gradle-8.14-all.zip');
fs.writeFileSync('android/gradle/wrapper/gradle-wrapper.properties', code);
console.log('done gradle');
