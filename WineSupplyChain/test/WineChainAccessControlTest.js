const WineChainAccessControl = artifacts.require('WineChainAccessControl')

contract('WineChainAccessControl', accounts => { 
    let tx;
    let defaultAccount = accounts[0];
    let otherAccount = accounts[1];

    beforeEach(async function() { 
        this.contract = await WineChainAccessControl.new({from: defaultAccount})
    })
    
    describe('test contract ownership', () => { 

        it('get current owner', async function () { 
            let owner = await this.contract.owner()
            assert.equal(owner, defaultAccount)
        })

        it('is owner', async function () { 
            assert.isTrue(await this.contract.isOwner({from: defaultAccount}))
            assert.isFalse(await this.contract.isOwner({from: otherAccount}))
        })

        it('emit OwnershipTransferred event', async function() {
            tx = await this.contract.transferOwnership(otherAccount)
            assert.equal(tx.logs[0].event, 'OwnershipTransferred')
            assert.equal(tx.logs[0].args.previousOwner, defaultAccount)
            assert.equal(tx.logs[0].args.newOwner, otherAccount)
        })

        it('renounce ownership', async function() {
            tx = await this.contract.renounceOwnership()
            assert.equal(tx.logs[0].event, 'OwnershipTransferred')
            assert.equal(tx.logs[0].args.previousOwner, defaultAccount)
            assert.equal(tx.logs[0].args.newOwner, 0)
            let owner = await this.contract.owner()
            assert.equal(owner, 0)
        })
    })

    let producer1 = accounts[2];
    let producer2 = accounts[3];

    describe('test producer role', () => { 

        it('add producer', async function () { 
            tx = await this.contract.addProducer(producer1, "Producer 1", "Chianti", "Italia", 1600)
            let producer = await this.contract.producers(producer1)
            assert.equal(producer[0], producer1)
            assert.equal(producer[1], "Producer 1")
            assert.equal(producer[2], "Chianti")
            assert.equal(producer[3], "Italia")
            assert.equal(producer[4], 1600)
            assert.isTrue(producer[5])
        })

        it('is producer', async function () { 
            tx = await this.contract.addProducer(producer1, "Producer 1", "Chianti", "Italia", 1600)
            assert.isTrue(await this.contract.isProducer(producer1))
            assert.isFalse(await this.contract.isProducer(otherAccount))
        })

        it('remove producer', async function () { 
            tx = await this.contract.addProducer(producer1, "Producer 1", "Chianti", "Italia", 1600)
            let producer = await this.contract.producers(producer1)
            assert.equal(producer[0], producer1)
            assert.isTrue(producer[5])

            tx = await this.contract.removeProducer(producer1)
            producer = await this.contract.producers(producer1)
            assert.isFalse(producer[5])
        })
    })

    describe('test certifier role', () => { 
        let certifier1 = accounts[4];

        it('add certifier', async function () { 
            tx = await this.contract.addCertifier(certifier1, "Certifier 1")
            let certifier = await this.contract.certifiers(certifier1)
            assert.equal(certifier[0], certifier1)
            assert.equal(certifier[1], "Certifier 1")
            assert.isTrue(certifier[2])
        })

        it('is certifier', async function () { 
            tx = await this.contract.addCertifier(certifier1, "Certifier 1")
            assert.isTrue(await this.contract.isCertifier(certifier1))
            assert.isFalse(await this.contract.isCertifier(otherAccount))
        })

        it('remove certifier', async function () { 
            tx = await this.contract.addCertifier(certifier1, "Certifier 1")
            let certifier = await this.contract.certifiers(certifier1)
            assert.equal(certifier[0], certifier1)
            assert.isTrue(certifier[2])

            tx = await this.contract.removeCertifier(certifier1)
            certifier = await this.contract.certifiers(certifier1)
            assert.isFalse(certifier[2])
        })
    })

    describe('test distributor role', () => { 
        let distributor1 = accounts[5];

        it('add distributor', async function () { 
            tx = await this.contract.addDistributor(distributor1, "Distributor 1", "Veneto", "Italia")
            let distributor = await this.contract.distributors(distributor1)
            assert.equal(distributor[0], distributor1)
            assert.equal(distributor[1], "Distributor 1")
            assert.equal(distributor[2], "Veneto")
            assert.equal(distributor[3], "Italia")
            assert.isTrue(distributor[4])
        })

        it('is distributor', async function () { 
            tx = await this.contract.addDistributor(distributor1, "Distributor 1", "Veneto", "Italia")
            assert.isTrue(await this.contract.isDistributor(distributor1))
            assert.isFalse(await this.contract.isDistributor(otherAccount))
        })

        it('remove distributor', async function () { 
            tx = await this.contract.addDistributor(distributor1, "Distributor 1", "Veneto", "Italia")
            let distributor = await this.contract.distributors(distributor1)
            assert.equal(distributor[0], distributor1)
            assert.isTrue(distributor[4])

            tx = await this.contract.removeDistributor(distributor1)
            distributor = await this.contract.distributors(distributor1)
            assert.isFalse(distributor[4])
        })
    })

    describe('test retailer role', () => { 
        let retailer1 = accounts[6];

        it('add retailer', async function () { 
            tx = await this.contract.addRetailer(retailer1, "Retailer 1")
            let retailer = await this.contract.retailers(retailer1)
            assert.equal(retailer[0], retailer1)
            assert.equal(retailer[1], "Retailer 1")
            assert.isTrue(retailer[2])
        })
    
        it('is retailer', async function () { 
            tx = await this.contract.addRetailer(retailer1, "Retailer 1")
            assert.isTrue(await this.contract.isRetailer(retailer1))
            assert.isFalse(await this.contract.isRetailer(otherAccount))
        })

        it('remove retailer', async function () { 
            tx = await this.contract.addRetailer(retailer1, "Retailer 1")
            let retailer = await this.contract.retailers(retailer1)
            assert.equal(retailer[0], retailer1)
            assert.isTrue(retailer[2])
    
            tx = await this.contract.removeRetailer(retailer1)
            retailer = await this.contract.retailers(retailer1)
            assert.isFalse(retailer[2])
        })
    })

})

let expectThrow = async function(promise) {
    try {
        await promise;
    } catch(error) {
        assert.exists(error);
        return;
    }
    assert.fail("Expected an error but didn't see one");
}

