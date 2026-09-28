const fs = require('fs');

let gradleCode = fs.readFileSync('android/gradle/wrapper/gradle-wrapper.properties', 'utf8');
gradleCode = gradleCode.replace(/gradle-9\.1-all\.zip/, 'gradle-8.14-all.zip');
fs.writeFileSync('android/gradle/wrapper/gradle-wrapper.properties', gradleCode);
console.log('done gradle 8.14');
