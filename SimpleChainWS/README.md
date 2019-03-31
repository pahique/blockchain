# Blockchain Data - RESTful web API with NodeJS

Blockchain has the potential to change the way that the world approaches data.
This project is simplified private blockchain, accessible through a RESTful web API.

## Getting Started

Use the instructions below to get a copy of the project up and running.

### Prerequisites

Installing Node and NPM using the installer package available from the [Node.js® web site](https://nodejs.org/en/).

### Configuring the project

1. Use NPM to initialize the project and create package.json to store project dependencies.
```
npm init
```
2. Install crypto-js with --save flag to save dependency to our package.json file
```
npm install crypto-js --save
```
3. Install level with --save flag
```
npm install level --save
```
4. Install hapi with --save flag
```
npm install hapi --save
```
## Testing

In order to test code:

1. Start the node app
```
node app.js
```
2. The server will be listening at localhost, port 8000.

   Endpoints:

      * http://localhost:8000/block/{BLOCK_HEIGHT} in order to get a block by its height.
      * http://localhost:8000/block in order to POST a new block.
      * http://localhost:8000/blockchain in order to view all the blocks in the chain.

3. Access http://localhost:8000/block/0 to view the Genesis block.
4. Add a new block by sending a POST request
```
curl -X "POST" "http://localhost:8000/block" -H 'Content-Type: application/json' -d $'{"body":"block body contents"}'
```
5. Access http://localhost:8000/block/1 to view the block just created.
6. View the contents of the whole blockchain by accessing http://localhost:8000/blockchain
