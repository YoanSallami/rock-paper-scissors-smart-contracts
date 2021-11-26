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
    });

    describe("Matchmaking", function () {
        it("Should create the game", async function() {
            await expect(contractInstanceFromAlice.createGame(access_lock, {value: starting_bet}))
                         .to.emit(contractInstance, 'GameCreated')
                         .withArgs(0, alice.address, starting_bet);
        });
        it("Should join the game", async function() {
            await contractInstanceFromAlice.createGame(access_lock, {value: starting_bet});
            await expect(contractInstanceFromBob.joinGame(0, access_key, {value: starting_bet}))
                         .to.emit(contractInstance, 'GameJoined')
                         .withArgs(0, bob.address, starting_bet);
        });
    });


});