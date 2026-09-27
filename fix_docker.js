const fs = require("fs");
let c = fs.readFileSync("Dockerfile", "utf8");
c = c.replace("ENV PORT=3000\n", "");
c = c.replace("# Expose container port\nEXPOSE 3000\n", "");
fs.writeFileSync("Dockerfile", c);
console.log("Done");
