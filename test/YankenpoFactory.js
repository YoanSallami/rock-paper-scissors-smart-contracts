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

    const starting_bet = 3000000;

    const access_key = "0x" + crypto.randomBytes(32).toString('hex');
    const access_lock = ethers.utils.solidityKeccak256(["bytes32"], [access_key]);

    const bad_access_key = "0x" + crypto.randomBytes(32).toString('hex');

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
        it("Should have the right commision percent", async function() {
            expect(await contractInstance.commision_percent()).to.equal(7);
        });
    });

    describe("Matchmaking", function () {
        it("Should create the game", async function() {
            await expect(contractInstanceFromAlice.createGame(access_lock, {value: starting_bet}))
                         .to.emit(contractInstance, 'GameCreated')
                         .withArgs(0, alice.address, starting_bet);
        });
        it("Should have the right commision after creation", async function() {
            await contractInstanceFromAlice.createGame(access_lock, {value: starting_bet});
            expect(await contractInstance.commision()).to.equal((starting_bet*7)/100);
        });
        it("Should join the game", async function() {
            await contractInstanceFromAlice.createGame(access_lock, {value: starting_bet});
            await expect(contractInstanceFromBob.joinGame(0, access_key, {value: starting_bet}))
                         .to.emit(contractInstance, 'GameJoined')
                         .withArgs(0, bob.address, starting_bet);
        });
        it("Should have the right commision after joining", async function() {
            await contractInstanceFromAlice.createGame(access_lock, {value: starting_bet});
            await contractInstanceFromBob.joinGame(0, access_key, {value: starting_bet});
            expect(await contractInstance.commision()).to.equal(((starting_bet*7)/100)+((starting_bet*7)/100));
        });
        it("Should not join the game (bad access key)", async function() {
            await contractInstanceFromAlice.createGame(access_lock, {value: starting_bet});
            await expect(contractInstanceFromBob.joinGame(0, bad_access_key, {value: starting_bet}))
                         .to.be.revertedWith("Access key do not match");
        });
        it("Should be able to withdraw the commision", async function() {
            await contractInstanceFromAlice.createGame(access_lock, {value: starting_bet});
            await contractInstanceFromBob.joinGame(0, access_key, {value: starting_bet});
            await expect(contractInstance.withdrawCommision(owner.address))
                         .to.emit(contractInstance, 'CommisionWithdrawn')
                         .withArgs(owner.address, ((starting_bet*7)/100)+((starting_bet*7)/100));
        });
        it("Should change ethers balance", async function() {
            await contractInstanceFromAlice.createGame(access_lock, {value: starting_bet});
            await contractInstanceFromBob.joinGame(0, access_key, {value: starting_bet});
            await expect(await contractInstance.withdrawCommision(owner.address))
                .to.changeEtherBalance(owner, ((starting_bet*7)/100)+((starting_bet*7)/100));
        });
        
    });


});