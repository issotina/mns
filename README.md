# MName Server (mns)
> Dgram Server to query phone number information (carrier) over DNS protocol

## Why ?
  This project started from a need at [kkiaPay](https://kkiapay.me/) where we provide an API to allow developers to collect payments on their sites by [Mobile Money](https://www.gsma.com/mobilefordevelopment/wp-content/uploads/2021/03/GSMA_State-of-the-Industry-Report-on-Mobile-Money-2021_Full-report.pdf). In the mobile money system the account number is simply a phone number of the subscriber.
  To process a mobile money payment, when the customer enters his phone number, we needed to instantly validate the number, determine the wallet provider (his bank in some way) and display in the form the logo of his bank (wallet provider). 

  The naive approach would be to embed this control in the client program. But operators [regularly add support for new routes](https://www.facebook.com/mtnbeninofficiel/photos/bonne-nouvelle-familleapr%C3%A8s-le-51-la-famille-sagrandit-avec-le-5%EF%B8%8F%E2%83%A32%EF%B8%8F%E2%83%A3-le-nouveau/3731244666939433/), so if we don't want to publish a new version of our libraries every time the operator changes, we need to have the control done remotely on a server.

  The first approach was an http API, but soon we noticed several difficulties:

  - An http API is overkill for our needs and introduces unnecessary latency
  - The number of phone number resolution requests was too high and was unnecessarily occupying the bandwidth of our load balancers.

## Solution 

Detecting the provider corresponding to a phone number is similar to resolving a domain name. And the internet has a very nice decentralized protocol when it comes to asking for a route: the [DNS protocol](https://en.wikipedia.org/wiki/Domain_Name_System).

The protocol is built around binary messages and is compact on UDP (TCP is also used but on another part of the protocol that does not concern our context). These characteristics, the tooling on top of the protocol (there are clients on all platforms) and the embedded caching logic make it an excellent option for our phone number resolution needs. 

**The idea was to build a DNS server, but instead of responding to domain name resolution requests, it would respond to phone number lookups.**

*This implementation is based on RFC 1035. [RFC 1035](https://datatracker.ietf.org/doc/html/rfc1035)*


---
## How it Works 

### Using unix client (dig)
```
; <<>> DiG 9.10.6 <<>> @ns4.kkiapay.me -t NS 229.67434270
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 36524
;; flags: qr rd ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;229.67434270.			IN	NS

;; ANSWER SECTION:
229.67434270.		300	IN	NS	mtn-bj.

;; Query time: 3 msec
;; SERVER: 167.172.156.170#53(167.172.156.170)
;; WHEN: Wed Oct 27 21:56:54 WAT 2021
;; MSG SIZE  rcvd: 62

```

### Using nodejs client
```js
const { Resolver } = require('dns').promises;

const resolver = new Resolver();
resolver.setServers(['ns4.kkiapay.me']);

resolver.resolveNs("229.67434270").then((addr) => {
    console.log(addr) // mtn-bj
})
```
### From the browser

To my disappointment, browsers do not offer an API to perform DNS queries: 
https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/dns


## Contribute

You can compile and host your own version of the server or freely use the ns4.kkiapay.me name server and give us feedback on this project. 
 But like a DNS server mesh, the idea is to have a distributed network of **MNS**. 

 So you can contribute on several levels:
 - Host a test version
 - Enrich the database 
 - Contribute to the code

## Roadmap

Many things remain to be done for a first stable version: 
- [ ] Stub resolvers for recursive queries 
- [ ] Add a client to easily interact with the database 
- [ ] Implement other types of requests 

## deps
 - [LMDB](http://www.lmdb.tech/doc/)
 - [ZIG Binding for LMDB](https://github.com/lithdew/lmdb-zig)
 - [Zig network](https://github.com/MasterQ32/zig-network)
## Disclosure
 This project is still in the experimental phase and ns4.kkiapay.me is purely a demo instance, so do not rely on the data returned by this server yet. 