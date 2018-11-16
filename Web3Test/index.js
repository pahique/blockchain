const Web3 = require('web3');
const EthereumTransaction = require('ethereumjs-tx');


async function sendSignedTransaction(sendingAddress, privateKeySender, receivingAddress, transferValue) {
    let balanceSenderBefore = await web3.eth.getBalance(sendingAddress);
    let balanceReceiverBefore = await web3.eth.getBalance(receivingAddress);
    
    let networkId = await web3.eth.net.getId();
    console.log('networkId: ' + networkId);

    let gasPrice = await web3.eth.getGasPrice();
    console.log('Current gas price: ' + gasPrice);

    web3.eth.getBlockTransactionCount("latest").then(result => { console.log("Latest block transaction count: " + result) });

    let count = await web3.eth.getTransactionCount(sendingAddress);
    console.log('Nonce: '+ count);
    
    let rawTransaction = {
        nonce: count,
        chainId: networkId,
        to: receivingAddress,
        //gas: 4500000,
        //gasPrice: 10000000000,
        gasPrice: 20000000,
        gasLimit: 30000,
        value: transferValue,
        data: ''
    }

    let privateKeySenderHex = Buffer.from(privateKeySender, 'hex');
    let transaction = new EthereumTransaction(rawTransaction);
    transaction.sign(privateKeySenderHex);

    let serializedTransaction = transaction.serialize();
    try {
        let result = await web3.eth.sendSignedTransaction('0x' + serializedTransaction.toString('hex'));
        console.log(result);
    } catch(error) {
        console.log('Error sending signed transaction: ' + error);
    }
    let balanceSenderAfter = await web3.eth.getBalance(sendingAddress);
    let balanceReceiverAfter = await web3.eth.getBalance(receivingAddress);
    // sender: balance after = balance before - transferValue - (gasPrice * gas spent in the transaction)
    console.log("Sender's balance: " + balanceSenderBefore + ' -> ' + balanceSenderAfter);
    console.log("Receiver's balance: " + balanceReceiverBefore + ' -> ' + balanceReceiverAfter);
}

// Ganache 
// let web3 = new Web3('http://localhost:7545');
// // Accounts Ganache seed: 'stool solve trade hole afford buzz satoshi decade observe husband comic punch'
// const account1 = '0xDbF2Ff9e78b22A19b9B9dB605b3e48729258F562';
// const privateKey1 = 'eea2413c15a37a65561a1f5fd0f965a90c35159f95be0d315d4d15a138e6a717';
// const account2 = '0x972f40ee4e09EcE33C9c2938161A2825690fF119';
// const privateKey2 = 'ca3f8242ae348b8ecf4525d4b2b029ce42eea51495e27dea03826b492115efbb';
// const account3 = '0x79F9E5ED7998ADc7022EbEF609990b9DAbb1379e';
// const privateKey3 = 'd9eb5a5c866a43c5f40d96f59ce8eefc9debd13942062ea6d9718915fd52a396';

// Rinkeby
let web3 = new Web3('https://rinkeby.infura.io/v3/d0faa30739c34283869a0ce154c069f4');
// Accounts Rinkeby seed: 'heavy view squeeze pledge multiply alert mushroom barely crawl joy afraid old'
const account1 = '0x14648D1222B257f63528Fb1cEB3964E008bef522';
const privateKey1 = '14ab3772f453625bd4cb667f207c5ffb5b5b5a79355c658cb89473db657d3a9a';
const account2 = '0xCa035a3a0Cb4bfe707A41c2F503Ade857614cE4f';
const privateKey2 = '14894e97d7f9f84b3952784f754c5b5b547b254570c025967300f2c6f73d8ead';

sendSignedTransaction(account1, privateKey1, account2, 40000000);





// Previous code using Promises

// web3.eth.getAccounts().then(accounts => {

//     // Accounts Rinkeby seed: 'heavy view squeeze pledge multiply alert mushroom barely crawl joy afraid old'
//     const account1 = '0x14648D1222B257f63528Fb1cEB3964E008bef522';
//     const privateKey1 = '14ab3772f453625bd4cb667f207c5ffb5b5b5a79355c658cb89473db657d3a9a';
//     const account2 = '0xCa035a3a0Cb4bfe707A41c2F503Ade857614cE4f';
//     const privateKey2 = '14894e97d7f9f84b3952784f754c5b5b547b254570c025967300f2c6f73d8ead';

//     let sendingAddress = account1;
//     let privateKeySender = privateKey1;
//     let receivingAddress = account2;
//     let transactionValue = 40000000;

//     web3.eth.getBalance(sendingAddress).then(balance => {console.log("Sender's balance before transaction: " + balance);});
//     web3.eth.getBalance(receivingAddress).then(balance => {console.log("Receiver's balance before transaction: " + balance);});

//     web3.eth.getTransactionCount(sendingAddress).then(count => {
//         console.log('Nonce: ' + count);
//         let rawTransaction = {
//             nonce: count,
//             to: receivingAddress,
//             gasLimit: 30000,
//             gasPrice: 20000000,
//             value: transactionValue,
//             data: ''
//         }
        
//         let privateKeySenderHex = new Buffer(privateKeySender, 'hex');
//         let transaction = new EthereumTransaction(rawTransaction);
//         transaction.sign(privateKeySenderHex);
        
//         let serializedTransaction = transaction.serialize();
//         web3.eth.sendSignedTransaction('0x' + serializedTransaction.toString('hex')).then(result => {
//             console.log(result);
//             web3.eth.getBalance(sendingAddress).then(balance => {console.log("Sender's balance after transaction: " + balance);});
//             web3.eth.getBalance(receivingAddress).then(balance => {console.log("Receiver's balance after transaction: " + balance);});
//         }).catch(error => {
//             console.log(error);
//         });
//     })
// }).catch(error => {
//     console.log(error);
// });


