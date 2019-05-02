const WineSupplyChain = artifacts.require('WineSupplyChain')

contract('WineSupplyChain', accounts => { 
    let tx;
    let defaultAccount = accounts[0];
    let otherAccount = accounts[1];
    let producer1 = accounts[2];

    beforeEach(async function() { 
        this.contract = await WineSupplyChain.new({from: defaultAccount})
        await this.contract.setDateTimeAPI('0xfa4d7c905e3cf2ac196929f9d88f026c5f15e6ab', {from: defaultAccount})
        await this.contract.addProducer(producer1, "Producer 1", "Chianti", "Italia", 1600, {from: defaultAccount})
    })
    
    describe('test harvest grapes', () => { 

        it('create grape lot', async function () { 
            tx = await this.contract.harvestGrapes(0, 1000, {from: producer1})
            let count = await this.contract.grapeLotCountPerProducer(producer1)
            assert.equal(count, 1)
            let grapeLot = await this.contract.grapeLots(0)
            //console.log(grapeLot)
            assert.equal(grapeLot['number'], 1)
            assert.equal(grapeLot['amount'], 1000)
            assert.equal(grapeLot['grapeType'], 0)
            assert.equal(grapeLot['state'], 0)  // GrapesHarvested
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

