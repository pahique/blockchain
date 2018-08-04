# Blockchain Data

Blockchain has the potential to change the way that the world approaches data.
This project is simplified private blockchain.

## Getting Started

Use the instructions below to get a copy of the project up and running.

### Prerequisites

Installing Node and NPM using the installer package available from the (Node.js® web site)[https://nodejs.org/en/].

### Configuring the project

- Use NPM to initialize the project and create package.json to store project dependencies.
```
npm init
```
- Install crypto-js with --save flag to save dependency to our package.json file
```
npm install crypto-js --save
```
- Install level with --save flag
```
npm install level --save
```

## Testing

To test code:
1: Open a command prompt or shell terminal after installing node.js.
2: Enter a node session, also known as REPL (Read-Evaluate-Print-Loop).
```
node
```
3: Copy and paste the contents of simpleChain.js into the node session
4: Instantiate blockchain with a variable
```
let b = new Blockchain();
```
5: Generate some blocks
```
.editor
b.addBlock(new Block('test1')).then(function(r) {
   console.log(r);
   return b.addBlock(new Block('test2'));
}).then(function(r) {
   console.log(r);
   return b.addBlock(new Block('test3'));
}).then(function(r) {
   console.log(r);
   return b.addBlock(new Block('test4'));
}).then(function(r) {
   console.log(r);
   return b.addBlock(new Block('test5'));
}).then(function(r) {
   console.log(r);
});

^D

```
6: Test some helper functions
```
b.getBlockHeight().then(function(r) { console.log(r); });

b.getBlock(1).then(function(r) { console.log(r); });

b.validateBlock(1).then(function(r) { console.log(r); });

b.printBlockchain();
```
7: Validate blockchain
```
b.validateChain().then(function(r) { console.log(r); });
```
8: Induce errors by changing block data
```
b.replaceBlock(1, 'invalid block').then(function(r) { console.log(r); });
b.replaceBlock(3, new Block('replaced')).then(function(r) { console.log(r); });
```
9: Validate blockchain. The chain should now fail with blocks 1, 3 and their connections.
```
b.validateChain().then(function(r) { console.log(r); });
```
