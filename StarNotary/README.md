StarNotary Project (by Paulo Henrique C. Oliveros)

- Network: Rinkeby Test Network
- Contract address: 0x4481bb6cd7903efffca43eb6c604d6f9a3b4471b
- TransactionId (contract creation): 0xf546ec19dce1c5aa2cf1f0eed64f087f5da8db092d48ae9bf0f2fcc1aa04242c

Project folders:

- smart_contracts: contains the smart contract code and test cases, as well as truffle configurations for deployment. Install all package.json dependencies and run:
  truffle compile
  truffle test
  truffle deploy --network rinkeby

- StarNotaryWeb: contains the HTML client page. Run http-server on root folder and access "http://localhost:8080/StarNotaryWeb/" (remember to select "Rinkeby network" on Metamask)

- StarNotaryWS: contains the NodeJS client. Install all package.json dependencies on this folder and call "node app.js" to enable the URL "http://localhost:3000/star/{id}" 

