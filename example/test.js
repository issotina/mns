const { Resolver } = require('dns').promises;

const resolver = new Resolver();
resolver.setServers(['127.0.0.1:5000']);
resolver.resolveNs("229.66434766").then((addr) => {
    console.log(addr)
})