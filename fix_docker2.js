const fs = require("fs");
let c = fs.readFileSync("Dockerfile", "utf8");
c = c.replace(/ENV PORT=3000\r?\n/, "");
c = c.replace(/# Expose container port\r?\nEXPOSE 3000\r?\n/, "");
fs.writeFileSync("Dockerfile", c);
console.log("Done");
