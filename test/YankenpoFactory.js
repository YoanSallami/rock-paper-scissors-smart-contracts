const { expect } = require("chai");

const crypto = require('crypto');
const { access } = require("fs");

describe("YankenpoFactory contract", function () {

    let YankenpoFactory;
    let contractInstance;
    let contractInstanceFromAlice;
    let contractInstanceFromBob;
    let contractInstanceFromMax;

    let owner;
    let alice;
    let bob;
    let max;

    const startingBet = 3000000;

    const accessKey = "0x" + crypto.randomBytes(32).toString('hex');
    const accessLock = ethers.utils.solidityKeccak256(["bytes32"], [accessKey]);

    const bad_accessKey = "0x" + crypto.randomBytes(32).toString('hex');

    beforeEach(async function () {
        YankenpoFactory = await ethers.getContractFactory("YankenpoFactory");

        [owner, alice, bob, max] = await ethers.getSigners();

        contractInstance = await YankenpoFactory.deploy();

        contractInstanceFromAlice = contractInstance.connect(alice);
        contractInstanceFromBob = contractInstance.connect(bob);
        contractInstanceFromMax = contractInstance.connect(max);
    });

    describe("Deployment", function () {
        it("Should have the right owner", async function() {
            expect(await contractInstance.owner()).to.equal(owner.address);
        });
        it("Should be unpaused", async function() {
            expect(await contractInstance.paused()).to.equal(false);
        });
        it("Should have the right commission percent", async function() {
            expect(await contractInstance.commissionPercent()).to.equal(7);
        });
    });

    describe("Matchmaking", function () {
        it("Should create the game", async function() {
            await expect(contractInstanceFromAlice.createGame(accessLock, {value: startingBet}))
                         .to.emit(contractInstance, 'GameCreated')
                         .withArgs(0, alice.address, startingBet);
        });
        it("Should have the right commission after creation", async function() {
            await contractInstanceFromAlice.createGame(accessLock, {value: startingBet});
            expect(await contractInstance.commission()).to.equal((startingBet*7)/100);
        });
        it("Should join the game", async function() {
            await contractInstanceFromAlice.createGame(accessLock, {value: startingBet});
            await expect(contractInstanceFromBob.joinGame(0, accessKey, {value: startingBet}))
                         .to.emit(contractInstance, 'GameJoined')
                         .withArgs(0, bob.address, startingBet);
        });
        it("Should have the right commission after joining", async function() {
            await contractInstanceFromAlice.createGame(accessLock, {value: startingBet});
            await contractInstanceFromBob.joinGame(0, accessKey, {value: startingBet});
            expect(await contractInstance.commission()).to.equal(((startingBet*7)/100)+((startingBet*7)/100));
        });
        it("Should not join the game (bad access key)", async function() {
            await contractInstanceFromAlice.createGame(accessLock, {value: startingBet});
            await expect(contractInstanceFromBob.joinGame(0, bad_accessKey, {value: startingBet}))
                         .to.be.revertedWith("Access key do not match");
        });
        it("Should withdraw the commission", async function() {
            await contractInstanceFromAlice.createGame(accessLock, {value: startingBet});
            await contractInstanceFromBob.joinGame(0, accessKey, {value: startingBet});
            await expect(contractInstance.withdraw(owner.address))
                         .to.emit(contractInstance, 'Withdrawn')
                         .withArgs(owner.address, ((startingBet*7)/100)+((startingBet*7)/100));
        });
        it("Should change ethers balance", async function() {
            await contractInstanceFromAlice.createGame(accessLock, {value: startingBet});
            await contractInstanceFromBob.joinGame(0, accessKey, {value: startingBet});
            await expect(await contractInstance.withdraw(owner.address))
                .to.changeEtherBalance(owner, ((startingBet*7)/100)+((startingBet*7)/100));
        });
        
    });


});