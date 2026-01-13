const http = require('http');
const fs = require('fs');
const port = process.env.PORT || 4000;
let data = {status:'ok'};
try{data = JSON.parse(fs.readFileSync('src/mocks/data.json','utf8'));}catch(e){}
http.createServer((req,res)=>{res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify(data));}).listen(port);
