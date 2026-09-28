const fs = require('fs');

// 1. Upgrade gradle wrapper to 9.1
let gradleCode = fs.readFileSync('android/gradle/wrapper/gradle-wrapper.properties', 'utf8');
gradleCode = gradleCode.replace(/gradle-8\.14-all\.zip/, 'gradle-9.1-all.zip');
fs.writeFileSync('android/gradle/wrapper/gradle-wrapper.properties', gradleCode);

// 2. Upgrade AGP to 8.11.1 in settings.gradle
let settingsCode = fs.readFileSync('android/settings.gradle', 'utf8');
settingsCode = settingsCode.replace(/id "com\.android\.application" version "8\.1\.0"/, 'id "com.android.application" version "8.11.1"');
fs.writeFileSync('android/settings.gradle', settingsCode);

console.log('done gradle 9.1 and AGP 8.11.1');
