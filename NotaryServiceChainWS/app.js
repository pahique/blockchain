'use strict';

const SimpleChain = require('./simpleChain.js');
const Hapi = require('hapi');
const bitcoin = require('bitcoinjs-lib');
const bitcoinMessage = require('bitcoinjs-message');

const blockchain = new SimpleChain.Blockchain();
const validationWindowInMinutes = 300;
// Map: address => {message: message to be signed, validated: true if the message-signature has been validated}
let validationRequestMap = new Map();

const server = Hapi.server({
    port: 8000,
    host: 'localhost'
});

// Route for requesting validation
server.route({
   method: 'POST',
   path: '/requestValidation',
   handler: (request, h) => {
        const input = request.payload;
        if (input.address) {
          const address = input.address;
          console.log(`Request validation, address ${address} ...`);
          const requestTimestamp = new Date().getTime().toString().slice(0,-3);
          const message = `${address}:${requestTimestamp}:starRegistry`;
          // creates a new entry in the map, setting the initial validation result to false
          validationRequestMap.set(address, {message: message, validated: false});
          return h.response({address: address,
                          requestTimestamp: requestTimestamp,
                          message: message,
                          validationWindow: validationWindowInMinutes}).code(200)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache')
        } else {
            return h.response({statusCode: 400, error: "Address missing"}).code(400)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache');
        }
   }
});

function validateMessageSignatureRequest(payload) {
  if (!payload.address) throw new Error('address field missing');
  else if (!payload.signature) throw new Error('signature field missing');
  return true;
}

// Route for validating a signature
server.route({
   method: 'POST',
   path: "/message-signature/validate",
   handler: (request, h) => {
        const input = request.payload;
        try {
          validateMessageSignatureRequest(input);
        } catch(error) {
            return h.response({statusCode: 400, error: error.message}).code(400)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache');
        }
        const address = input.address;
        const signature = input.signature;
        console.log(`Message signature validation, address ${address} ... `);
        if (!validationRequestMap.get(address)) {
            return h.response({statusCode: 412, error: `Validation request not found`}).code(412)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache');
        }
        const message = validationRequestMap.get(address).message;
        const requestTimestamp = message.split(":")[1];
        const now = new Date().getTime().toString().slice(0,-3);
        const timeElapsed = now - requestTimestamp;
        if (timeElapsed < validationWindowInMinutes) {
          const result = bitcoinMessage.verify(message, address, signature);
          // updates the verification result in the map
          validationRequestMap.set(address, {message: message, validated: result});
          return h.response({registerStar: result,
                             status: {
                                address: address,
                                requestTimestamp: requestTimestamp,
                                message: message,
                                validationWindow: (validationWindowInMinutes - timeElapsed),
                                messageSignature: (result ? "valid" : "invalid")
                             }}).code(200)
                .header('content-type', 'application/json; charset=utf-8')
                .header('cache-control', 'no-cache');
        } else {
          // validation window has expired, removing entry from the map
          validationRequestMap.delete(address);
          return h.response({statusCode: 412, error: `Validation window expired`}).code(412)
                .header('content-type', 'application/json; charset=utf-8')
                .header('cache-control', 'no-cache');
        }
   }
});

// Route for getting a block by height
server.route({
    method: 'GET',
    path: '/block/{blockHeight}',
    handler: (request, h) => {
        let blockHeight = encodeURIComponent(request.params.blockHeight);
        console.log(`Getting block #${blockHeight} ...`);
        return blockchain.getBlock(blockHeight).then(block => {
            return h.response(block).code(200)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache')
        })
       .catch(error => {
            return h.response({statusCode: 404, error: `Block not found`}).code(404)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache');
        });

    }
});


// Route for getting blocks by address
server.route({
    method: 'GET',
    path: '/stars/hash:{hash}',
    handler: (request, h) => {
        let hash = encodeURIComponent(request.params.hash);
        console.log(`Getting block by hash ${hash} ...`);
        return blockchain.getBlockByHash(hash).then(block => {
            return h.response(block).code(200)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache')
        }).catch(error => {
            return h.response({statusCode: 404, error: `Block not found`}).code(404)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache');
        });
    }
});


// Route for getting blocks by address
server.route({
    method: 'GET',
    path: '/stars/address:{address}',
    handler: (request, h) => {
        let address = encodeURIComponent(request.params.address);
        console.log(`Getting blocks by address ${address} ...`);
        return blockchain.getBlocksByAddress(address).then(blocks => {
            return h.response(blocks).code(200)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache')
        });

    }
});


// Validates required fields in the payload
function validateStarRegistryRequest(payload) {
  if (!payload.address) throw new Error('address field missing');
  else if (!payload.star) throw new Error('star field missing');
  else if (!payload.star.ra) throw new Error('star.ra (right ascension) field missing');
  else if (!payload.star.dec) throw new Error('star.dec (declination) field missing');
  else if (!payload.star.story) throw new Error('star.story (star story) field missing');
  else if (payload.star.story.length > 250) throw new Error('star.story must have no more than 250 characters');
  return true;
}

// Checks if a message signature has already been validated
function hasValidatedMessageSignature(address) {
  if (validationRequestMap.get(address)) {
    return validationRequestMap.get(address).validated;
  }
  return false;
}

// Route for posting a new block
server.route({
    method: 'POST',
    path: '/block',
    handler: (request, h) => {
        const blockContent = request.payload;
        try {
          validateStarRegistryRequest(blockContent);
        } catch(error) {
          return h.response({statusCode: 400, error: error.message}).code(400)
                .header('content-type', 'application/json; charset=utf-8')
                .header('cache-control', 'no-cache');
        }
        // Checks if user has validated a message-signature previously
        if (hasValidatedMessageSignature(blockContent.address)) {
          console.log(`Registering a new star for address ${blockContent.address}...`);
          blockContent.star.story = Buffer.from(blockContent.star.story).toString('hex');
          let block = new SimpleChain.Block(blockContent);
          return blockchain.addBlock(block).then(resultBlock => {
              // require a new validation for the next star, by deleting the existing validation
              validationRequestMap.delete(blockContent.address);
              return h.response(resultBlock)
                    .header('content-type', 'application/json; charset=utf-8')
                    .header('cache-control', 'no-cache')
                    .header('statusCode', 200);
          });
        } else {
          return h.response({statusCode: 412, error: `Message signature validation required`}).code(412)
                .header('content-type', 'application/json; charset=utf-8')
                .header('cache-control', 'no-cache');
        }
    }
});

// Route for getting all the blocks from the chain
server.route({
    method: 'GET',
    path: '/blockchain',
    handler: (request, h) => {
        return blockchain.getBlockchain().then((blockResults) => {
            return h.response(blockResults).code(200)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache');
        });
    }
});


const init = async () => {
    await server.start();
    console.log(`Server running at: ${server.info.uri}`);
};


process.on('unhandledRejection', (err) => {
    console.log(err);
    process.exit(1);
});

init();
