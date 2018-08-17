'use strict';

const SimpleChain = require('./simpleChain.js');
const Hapi = require('hapi');
const blockchain = new SimpleChain.Blockchain();

const server = Hapi.server({
    port: 8000,
    host: 'localhost'
});

// Route for getting a block by height
server.route({
    method: 'GET',
    path: '/block/{blockHeight}',
    handler: (request, h) => {
        let blockHeight = encodeURIComponent(request.params.blockHeight);
        console.log('Getting block #' + blockHeight + '...');
        return blockchain.getBlock(blockHeight).then(block => {
            return h.response(block).code(200)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache')
        })
       .catch(error => {
            return h.response({statusCode: 404, error: "Block not found"}).code(404)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache');
        });

    }
});

// Route for posting a new block
server.route({
    method: 'POST',
    path: '/block',
    handler: (request, h) => {
        const blockContent = request.payload;
        console.log('Adding a new block...');
        let block = new SimpleChain.Block(blockContent);
        return blockchain.addBlock(block).then(resultBlock => {
            return h.response(resultBlock)
                  .header('content-type', 'application/json; charset=utf-8')
                  .header('cache-control', 'no-cache')
                  .header('statusCode', 200);
        });
    }
});

// Route for getting all the blocks from the chain
server.route({
    method: 'GET',
    path: '/blockchain',
    handler: (request, h) => {
        return blockchain.printBlockchain().then((blockResults) => {
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
